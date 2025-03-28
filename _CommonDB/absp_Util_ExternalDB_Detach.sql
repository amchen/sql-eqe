if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_ExternalDB_Detach') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ExternalDB_Detach
end

go

create procedure absp_Util_ExternalDB_Detach @databaseName varchar(128) = '', 
	@minutesToKeepTrying int = 20, @minutesBetweenTries int = 1, @performDetach int = 0, @setSingleUser int = 1
	
/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console; 
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure is used to help external DB management tools deal with RQE databases
	It can return status to the caller informing them whether they can safely detach a database from RQE; 
		alternatively it may detach it for them if requested.
	It can do this by:
	1) check and see if the DB is in use in BatchJob table; if so set those jobs to CancelPending and retry as requested: return 0 (false) if expires
	2) if NOT in use (either first time or after some retries) then 
		a) remove from CFLDRINFO so the user can't do anything else if an EDB
		b) if option set, physically detach it (the main and the _IR if an EDB pair)
		c) return 1 or 2 depending on whether detached or not

Returns:
-1 - an error occured (like the database name was not found as example - nothing to detach)
 0 - if the database is in use and should not be detached
 1 - if the database is OK to be detached
 2 - if the database was OK to detach and the flag was set to do it and it was physically detached

====================================================================================================
pre
font
##BD_END

##PD  @databaseName ^^ The name of the database to detach (for EDBs, always the base name - we will handle the _IR).
##PD  @minutesToKeepTrying ^^ The number of minutes to keep trying in case the database is in use.  Default = 20.
##PD  @minutesBetweenTries ^^ The number of minutes to sleep between tries to see if still busy. Default = 1.
##PD  @performDetach ^^  A flag to indicate whether this procedure will do the physical detach.  0 = do not; 1 = detach.  Default = 0. 
##PD  @setSingleUser ^^  A flag to indicate whether to drop all existing connections.  0 = do not; 1 = drop connections.  Default = 1. 

##RD  @retCode ^^ -1 = bad name or nothing to detach; 0 = do not detach; 1 = OK to detach yourself; 2 = detached for you.

*/

AS
begin
	set nocount on;
	
	declare @sql nvarchar(1000);
	declare @retCode int;
	declare @dbName varchar(128);
	declare @dbNameIR varchar(128);
	declare @dbRefKey int
	declare @dbRefKey2 int
	declare @isEdb int
	declare @isRdb int
	declare @busyStatus int
	declare @waitRetryLoops int
	declare @delayLength char(8)
	
	set @sql = '';
	set @retCode = 0;
	set @dbName = '';
	set @dbNameIR = '';
	set @dbRefKey = 0;
	set @dbRefKey2 = 0;
	set @isEdb = 0;
	set @isRdb = 0;
	set @busyStatus = 0;
	set @waitRetryLoops = 0;
	set @delayLength = '';

	-- for convenience the caller tells us in minutes how long to wait and what the retry wait time should be
	-- we turn that into a number of loops
	if @minutesToKeepTrying < 1 set @minutesToKeepTrying = 1;	-- we need at least a 1 here	
	if @minutesBetweenTries < 1 set @minutesBetweenTries = 1;	-- we need at least a 1 here
	
	if @minutesBetweenTries > 59 set @minutesBetweenTries = 59;	-- because of the "waitfor" command this has to be 1 to 59
	if @minutesBetweenTries > @minutesToKeepTrying set @minutesToKeepTrying = @minutesBetweenTries;
	
	-- time divided by wait = number of loops
	set @waitRetryLoops = @minutesToKeepTrying / @minutesBetweenTries;
	set @delayLength = '00:' + cast(@minutesBetweenTries as char(2)) + ':00';
	
	if @waitRetryLoops < 1 set @waitRetryLoops = 1;	-- we need at least a 1 here
	
	set @dbName = RTRIM(LTRIM(@databaseName));
	
	if LEN(@dbName) = 0 return -1;	-- nothing to detach
	
	-- you should not call for the _IR DB but if you do, we handle it
	if RIGHT(@dbName, 3) = '_IR'
		set @dbName = SUBSTRING(@dbName, 1, len(@dbName) - 3); -- remove the _IR
		
	set @dbNameIR = @dbName + '_IR';	-- in case eventually we need the _IR
	
	-- is this an EDB with an entry in CFLDRINFO?
	select @dbRefKey = Cf_Ref_Key from commondb..CFLDRINFO where DB_NAME = @dbName;
	
	if @dbRefKey > 0 set @isEdb = 1;	-- must be an EDB

	-- no, is it an RDB perhaps?
	if @dbRefKey = 0
	begin
		select @dbRefKey = database_id from sys.databases where name = @dbName;
		
		-- lets just check and see if there is an IR pair
		select @dbRefKey2 = database_id from sys.databases where name = @dbName + '_IR';
		
		if @dbRefKey > 0 and @dbRefKey2 = 0 set @isRdb = 1;	-- must be an RDB
		
		if @dbRefKey > 0 and @dbRefKey2 > 0 set @isEdb = 1;	-- must be an EDB
	end
	
	-- well, if not an RDB and not an EDB, error out
	if @dbRefKey = 0  return -1;
	
	-- check TaskInfo and BatchJob
	select top 1 @busyStatus = 1 from TaskInfo where DBRefKey = @dbRefKey and Status in ('R', 'W');
	if @busyStatus != 1 
		select top 1 @busyStatus = 1 from commondb..BatchJob where DBRefKey = @dbRefKey and Status in ('R', 'PS', 'W', 'WL', 'CP');

	-- if jobs currently running or waiting, cancel them
	if @busyStatus = 1
		update commondb..BatchJob set Status = 'CP' where dbRefkey = @dbRefKey and Status in ('R', 'PS', 'W', 'WL');
	
	-- now wait for the right amount of time to elapse
	-- try again every now and then
	while (@busyStatus = 1 and @waitRetryLoops > 0)
	begin
			WAITFOR DELAY @delayLength;
			set @waitRetryLoops = @waitRetryLoops - 1;
		
		set @busyStatus = 0;
		-- check TaskInfo and BatchJob again
		select @busyStatus = 1 from TaskInfo where DBRefKey = @dbRefKey and Status in ('R', 'W');
		if @busyStatus != 1 
			select @busyStatus = 1 from commondb..BatchJob where DBRefKey = @dbRefKey and Status in ('R', 'PS', 'W', 'WL', 'CP');
	end
	
	-- once you are here you have waited the length of time requested or it is not busy
	-- if still busy, return busy
	if @busyStatus = 1 return 0;
	
	-- for RDBs, set attrib = 0 for both logical and physical detach
	if @isRdb = 1
	begin
		set @sql = N'update [' + @dbName + '].dbo.RdbInfo set attrib = 0 where LongName = ' + '''' + @dbName + ''''
		execute sp_executesql @sql
	end 

	-- clean up batch job and related tables in prepartion for the detach
	if @isEdb = 1
	begin
		exec commondb..absp_Util_CleanupBatchJob @dbName, @dbRefKey ;
	end

	-- if not busy, and they do detaching, clean up connections and set detach in progress 
	if @performDetach = 0 
	begin
		exec commondb..absp_InfoTableAttrib_Set 12,@dbRefKey,'CF_DETACH_IN_PROGRESS',1

		-- clean up any connections when @setSingleUser is requested
		if @setSingleUser =1
		begin
			set @sql = 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE ;'
			set @sql = @sql + 'ALTER DATABASE [' + @dbName + '] set MULTI_USER'
			exec sp_executesql @sql
			if @isEdb = 1 -- do the ir too
			begin
				set @sql = 'ALTER DATABASE [' + @dbNameIR + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE ; '
				set @sql = @sql + 'ALTER DATABASE [' + @dbNameIR + '] set MULTI_USER'
				exec sp_executesql @sql
			end
		end
		return 1;
	end

	-- OK, so we have to do detach for you
	if @isEdb = 1
	begin	
		-- Since FLDRINFO does not have column CF_REF_KEY until the stored procedure absp_Util_CreateCurrencyFolderInfoTables is executed
		-- we will avoid SQL Server error during loading by storing the query in a string (and then use sp_executesql to execute it)
		select @sql = 'use [' + @dbName +']'+
		' begin ' + 
		' declare @cfRefKey int; ' +
		' select @cfRefKey = CF_REF_KEY from commondb.dbo.CFLDRINFO where DB_NAME= ''' + @dbName + ''';' +
		' update FLDRINFO set CF_REF_KEY = 0 where CF_REF_KEY = @cfRefKey; ' +
		' delete from commondb.dbo.CFLDRINFO where CF_REF_KEY = @cfRefKey; ' +
		' end '	
		--print @sql
		
		exec sp_executesql @sql;

		-- since EDB, we need to do the pair
		set @sql = 'ALTER DATABASE [' + @dbNameIR + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE '
		exec sp_executesql @sql
		if exists ( select 1 from sys.databases where name = @dbNameIR )
		begin
			exec sp_detach_db @dbNameIR
		end		
	end
	
	set @sql = 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE '
	exec sp_executesql @sql
	if exists ( select 1 from sys.databases where name = @dbName )
	begin
		exec sp_detach_db @dbName
	end

	return 2;
end


