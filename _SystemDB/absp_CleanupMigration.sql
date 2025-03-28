if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanupMigration') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupMigration;
end
go

create procedure absp_CleanupMigration
	@batchJobKey int,
	@cleanupStep int
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure cleans up Migration for the given batchJobKey.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on;

	declare @nodeKey int;
	declare @DatabaseName varchar(120);
	declare @IDatabaseName varchar(120);
	declare @IRDB varchar(120);
	declare @sql nvarchar(max);
	declare @sourceRQEVersion varchar(25);
	declare @sourceBuild varchar(25);
	declare @updateVersion int;
	declare @dbType varchar(25);
	declare @nodeType int;

	--Get the RQE migration database name--
	select @DatabaseName=rtrim(KeyValue) from commondb..MigrationProperties where BatchJobKey=@batchJobKey and KeyName='dbName';
	select @dbType = rtrim(KeyValue) from commondb..MigrationProperties where BatchJobKey=@batchJobKey and KeyName='dbType';
	
	if (@dbType = 'EDB')
	begin
		select @nodeKey = CF_REF_KEY from commondb..CFLDRINFO where DB_NAME = @DatabaseName;
		set @nodeType = 12
	end
	else if (@dbType = 'RDB')
		begin
			set @sql='select @nodeKey = RdbInfoKey from [' + @DatabaseName + ']..RdbInfo where LongName = ''' + @DatabaseName +'''';
			execute sp_executesql @sql, N'@nodeKey int output', @nodeKey = @nodeKey output;
			set @nodeType = 101
		end

	-- Check the cleanupStep value and cleanup the migration steps in reverse order

	--Rollback version update--
	select @sourceRQEVersion=KeyValue   from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Source.RQEVersion';
	select @sourceBuild=KeyValue   from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Source.Build';
	
	if (@dbType = 'EDB')
		set @sourceBuild = '@(#)' +@sourceBuild;
	
	-- For EDB/RDB
	set @sql = 'delete from  ' + QUOTENAME(dbo.trim(@databaseName)) + '..RQEVersion where RQEVersion>=''' + @sourceRQEVersion + ''' and Build>''' + @sourceBuild + ''';'
	print @sql;
	exec (@sql);

	--For IDB
	if (@dbType = 'EDB')
	begin
		set @IDatabaseName = dbo.trim(@databaseName) + '_IR'
		
		set @sql = 'if ((select count(*) from ' + QUOTENAME(@IDatabaseName) + '..RQEVersion)>1)'
		set @sql = @sql + 'delete from ' + QUOTENAME(@IDatabaseName) + '..RQEVersion where RQEVersion>=''' + @sourceRQEVersion + ''' and Build>''' + @sourceBuild + ''';'
		print @sql;
		exec (@sql);
	end

	--Set Attribute to Migration needed--
	set @sql='if exists ( select 1 from sys.databases where name=''' +dbo.trim(@databaseName) + ''')'
	if (@dbType = 'EDB')
		set @sql=@sql + ' exec absp_InfoTableAttribSetCurrencyMigrationNeeded ' + dbo.trim(cast(@nodeKey as varchar(20))) + ', 1, ''' + dbo.trim(@databaseName) + '''';
	else if (@dbType = 'RDB')
		set @sql=@sql + ' exec absp_InfoTableAttribSetRDBMigrationNeeded ' + dbo.trim(cast(@nodeKey as varchar(20))) + ', 1, ''' + dbo.trim(@databaseName) + '''';
	print @sql;
	exec (@sql);

end
