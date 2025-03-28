if exists(select * from SYSOBJECTS where ID = object_id(N'absp_RQEFriendlyDetach') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_RQEFriendlyDetach
end
go

create procedure absp_RQEFriendlyDetach @dbName varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure checks for batch jobs and tasks currently running in the specified 
			database. If not busy, a forced detach is performed. If busy, currently running and 
			waiting jobs will be canceled to allow subsequent calls to this procedure to succeed.
			Intended to execute from the commondb database.

Returns:        Returns 0 for not busy and database detached, otherwise 1 for busy
====================================================================================================
</pre>
</font>
##BD_END

##PD	@dbName			^^  The name of the database to check for running jobs/tasks.
##RD	@busyStatus		^^  Returns 0 for success, 1 for busy.

*/
as
begin

	set nocount on

	declare @busyStatus int
	declare @dbRefKey int
	declare @sql nvarchar(MAX)
	declare @longname varchar(255)

	set @busyStatus = 0 -- assume not busy until we find otherwise
	set @dbRefKey = 0 

	-- get dbRefKey from cfldrinfo
	if right(@dbName,3) = '_ir'
		set @longname = substring(@dbName,1,len(@dbName)-3) --remove the _IR
	else
		set @longname = @dbName

	select @dbRefKey=cf_Ref_Key from cfldrinfo where db_name = @longname		

	-- if database is in cfldrinfo, check if it's busy
	if @dbRefKey != 0 
	begin

		-- check TaskInfo
		select @busyStatus= 1 from TaskInfo where dbRefKey = @dbRefKey and status in ('r','ps', 'w')
		if @busyStatus = 1 return @busyStatus

		-- check BatchJob
		select @busyStatus= 1 from BatchJob where dbRefKey = @dbRefKey and status in ('r','ps', 'w', 'cp')

		-- if jobs currently running or waiting, cancel them
		if @busyStatus = 1
		begin
			update BatchJob set status = 'CP' where dbRefkey = @dbRefKey and status in ('r', 'ps', 'w')
		end
	end

	-- if not busy with RQE jobs/tasks, do a forced detach
	if @busyStatus = 0
	begin
		set @sql = 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE '
		exec sp_executesql @sql
		if exists ( select 1 from sys.databases where name = @dbName )
		begin
			exec sp_detach_db @dbName
		end
	end

	return @busyStatus
end



