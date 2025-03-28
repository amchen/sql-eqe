if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateTableFromExternalDatabase') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CreateTableFromExternalDatabase;
end
go

create procedure  absp_CreateTableFromExternalDatabase @batchJobKey int, @exposureKey int, @isLocalServer int=0
as

/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	 The procedure creates tables in a schema from extername database.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##PD  @tableName ^^ The table name to be transferred
##PD  @sourceSchema ^^ The source schema from where the table will get transferred
##PD  @targetSchema ^^ The target schema  where the table will get transferred

##BD_END
*/
begin
	set nocount on
	 
	declare  @sql varchar(8000)
	declare  @sql2 varchar(8000)
	declare @dbName varchar(200)
	declare @schemaName varchar(1000)
	declare @lknServerName varchar(20)
	declare @userName varchar(100)
	declare @password varchar(100)
	declare @filter varchar(8000)
	declare @severCreated varchar(100)
	declare @serverName varchar(130)
	declare @tableName varchar(130)
	declare @collation varchar(200)
	declare @tName varchar(200)
	
	--Query the BatchProperties table to get the external database information 
	select @serverName=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBServer'
	select @userName=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.User'
	select @password=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.Password'
	select @dbName=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBName'
	select @filter=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='FilterValue'
	
	if @isLocalServer<>1
	begin

		--Create a link server to the external database.
 		set @lknServerName='LknSvr_' + dbo.trim(cast(@batchJobKey as varchar(20)));
 		begin try
			exec @severCreated=absp_CreateLinkedServer @lknServerName,@serverName, '',@dbName,@userName,@password
		end try
		begin catch
			print ERROR_MESSAGE()
			return
		end catch
		exec absp_MessageEx  'Created Linked server' 
	end 

	--Get all the table names for ExtractQuery 
	declare c1 cursor  for 
		select KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName like 'ExtractQuery.TableName%'
	open c1
	fetch c1 into @tablename
	while @@fetch_status=0
	begin
		set @schemaName=   dbo.absp_Util_GetSchemaName(@exposureKey) + '_raw'
		
		--Create empty table in schema--
		if @isLocalServer<>1
			set @sql = 'select * into ' + dbo.trim(@schemaName) + '.' + dbo.trim(@tablename) + ' from ' + @lknServerName + '.[' + @dbName+'].dbo.' + dbo.trim(@tablename) + ' where 1=2'
		else
			set @sql = 'select * into ' + dbo.trim(@schemaName) + '.' + dbo.trim(@tablename) + ' from [' + @dbName+'].dbo.' + dbo.trim(@tablename) + ' where 1=2'
		exec absp_MessageEx @sql
		exec(@sql)	
		
		--Table columns can have a different collation--
		--So recreate table using database collation--
		select @collation = cast(databasepropertyex(DB_NAME(), 'Collation') as varchar(200))
		set @tName=dbo.trim(@schemaName) + '.' + dbo.trim(@tablename)
		exec absp_Util_CreateSysTableScriptWithCollation @sql out,@tablename ,'',@schemaName,'',1,0,@collation
		exec absp_MessageEx @sql
		
		--Drop table and then recreate
		set @sql2='if exists(select 1 from sys.tables where schema_id = schema_id('''+ @schemaName +''') and name=''' + @tableName + ''' ) drop table ' + @tName
		exec absp_MessageEx @sql2
		exec(@sql2)
		
		--Rereate table
		exec (@sql)
	
		fetch c1 into @tablename
	end 
	close c1
	deallocate c1
	
	--Drop linked server
	if exists(select 1 from master.sys.sysservers where srvName=@lknServerName) exec sp_dropserver @lknServerName, 'droplogins'
	
end