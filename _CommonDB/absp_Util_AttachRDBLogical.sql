if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachRDBLogical') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachRDBLogical;
end
go

create procedure absp_Util_AttachRDBLogical
	@databaseName varchar(255)

/*
====================================================================================================
Purpose:	This procedure performs a logical attach of an RDB database.
Returns:	Nothing
====================================================================================================
*/

as
begin
	set nocount on;

	declare @sql nvarchar(1000);
	declare @systemVersion varchar(25);
	declare @dbVersion  varchar(25);
	declare @rdbInfoKey int;
	declare @attribName varchar(25)


	-- Apply Update
	exec absp_Migr_LoadProcedure @databaseName, '16.10.00', '', 'RQEMigration';
	exec absp_Migr_ApplyUpdate 'RDB', @databaseName;

	-- Get RdbInfoKey
	set @sql = N' select @rdbInfoKeyOUT=RdbInfoKey from [' + @databaseName + '].dbo.RdbInfo where LongName = ''' + @databaseName + '''';
	execute sp_executesql @sql,N'@rdbInfoKeyOUT int OUTPUT', @rdbInfoKeyOUT=@rdbInfoKey OUTPUT;

	set @attribName = 'CURRENCY_AVAILABLE';

	exec absp_InfoTableAttrib_Set 101, @rdbInfoKey, @attribName,1, @databaseName;

	-- get current systemdb version
	select top 1 @systemVersion = rqeversion from systemdb.dbo.RQEVersion order by RqeVersionKey desc;

	-- get version for @databaseName
	set @sql = N' select top 1 @dbVersionOUT=rqeversion from [' + @databaseName + '].dbo.RqeVersion order by RqeVersionKey desc';
	execute sp_executesql @sql,N'@dbVersionOUT varchar(25) OUTPUT', @dbVersionOUT=@dbVersion OUTPUT;

	if @systemVersion != @dbVersion
	begin
		exec absp_InfoTableAttribSetRDBMigrationNeeded @rdbInfoKey, 1, @databaseName;
	end
	else
	begin
		exec absp_Migr_LoadProcedure @databaseName, '16.10.00', 'F', 'Util', 'absp_Util_GetFullDBVersion';
		exec absp_Migr_LoadProcedure @databaseName, '16.10.00', 'F', 'Util', 'absp_Util_IsBtBRequired';

		select @systemVersion = systemdb.dbo.absp_Util_GetFullDBVersion();

		-- get version for @databaseName
		set @sql = N' select @dbVersionOUT = [' + @databaseName + '].dbo.absp_Util_GetFullDBVersion()';
		execute sp_executesql @sql,N'@dbVersionOUT varchar(25) OUTPUT', @dbVersionOUT=@dbVersion OUTPUT;

		if @systemVersion != @dbVersion
			exec absp_InfoTableAttribSetRDBMigrationNeeded @rdbInfoKey, 1, @databaseName;
	end
end
