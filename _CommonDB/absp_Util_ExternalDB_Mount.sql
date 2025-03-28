if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_ExternalDB_Mount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ExternalDB_Mount
end

go

create procedure absp_Util_ExternalDB_Mount @databaseName varchar(128) = '', @groupKey int = 0, @userKey int = 1

/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console;
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure is used to help external DB management tools deal with RQE databases.
	It logically attaches, or mounts, an RQE user database to the RQE application.
	The database to mount must already be attached to SQL Server.

Returns:
-4 - EDB version is good but IDB is an older version
-3 - database needs to be migrated to the current version
-2 - not an RQE database
-1 - the specified database is not attached to SQL Server
 1 - if the database is attached to the RQE application

====================================================================================================
pre
font
##BD_END

##PD  @databaseName ^^ The name of the database to mount to the RQE application

##RD  @retCode ^^ -1 = DB not attached to SQL Server, -2 not an RQE user DB, -3 DB needs migration, -4 IDB needs migration, 1 success 

*/

AS
begin
	set nocount on;

	declare @sql nvarchar(1000);
	declare @retCode int;
	declare @dbName varchar(128);
	declare @dbNameIR varchar(128);
	declare @dbName2 varchar(130);
	declare @dbType varchar(3);
	declare @rqeVersion varchar(25);
	declare @sysVersion varchar(25);
	declare @dbRefKey int;
	
	set @sql = '';
	set @retCode = 0;
	set @dbName = '';
	set @dbNameIR = '';

	set @dbName = RTRIM(LTRIM(@databaseName));

	if LEN(@dbName) = 0 return -2;	-- nothing to attach to RQE

	-- is the database attached to SQL Server?
	if not exists (select 1 from sys.databases where name = @dbName)
	begin
		return -1;
	end

	-- is it an RQE database? if so, what type of RQE database is it?
	begin try
		set @sql = N'select top 1 @dbtypeOUT = DbType, @rqeVersionOUT = RQEVersion from [' + @dbName + '].dbo.RQEVersion order by RQEVersionKey desc'
		execute sp_executesql @sql, N'@dbtypeOUT varchar(20) OUTPUT, @rqeVersionOUT varchar(25) OUTPUT', @dbtypeOUT=@dbType OUTPUT, @rqeVersionOUT=@rqeVersion OUTPUT
	end try
	begin catch
		-- if we end up here, there was no RQEVersion table so this isn't an RQE user DB
		return -2
	end catch

	if @dbType = 'SYS' or @dbType = 'COM' return -2

	select top 1 @sysVersion=RQEVersion from systemdb..RQEVersion order by RQEVersionkey desc;
	
	-- if db to mount needs to be migrated, bail
	if @rqeVersion != @sysVersion return -3

	if @dbType = 'EDB' 
	begin
		-- is the IDB attached to SQL Server?
		set @dbNameIR =  @dbName + '_IR'
		if not exists (select 1 from sys.databases where name = @dbNameIR) return -1
	
		-- check version on IDB in case somehow the EDB got migrated and the IDB didn't
		set @sql = N'select top 1 @rqeVersionOUT = RQEVersion from [' + @dbNameIR + '].dbo.RQEVersion order by RQEVersionKey desc'
		execute sp_executesql @sql, N'@rqeVersionOUT varchar(25) OUTPUT', @rqeVersionOUT=@rqeVersion OUTPUT
		
		-- if IDB is an old version, bail 
		if @rqeVersion != @sysVersion return -4

		exec @dbRefKey = absp_Util_AttachWCeDatabase @retCode, @dbName, @groupKey, @userKey;
		exec commondb..absp_InfoTableAttrib_Set 12,@dbRefKey,'CF_DETACH_IN_PROGRESS',0
	end

	if @dbType = 'IDB'
	begin
		-- is the EDB attached to SQL Server?
		set @dbName2 = SUBSTRING(@dbName, 1, len(@dbName) - 3); -- remove the _IR
		if not exists (select 1 from sys.databases where name = @dbName2) return -1
		exec absp_Util_AttachWCeDatabase @retCode, @dbName2, 1, 1;
	end

	if @dbType = 'RDB'
	begin
		exec absp_Util_AttachRDBLogical @dbName;
	end

	return 1;
end
