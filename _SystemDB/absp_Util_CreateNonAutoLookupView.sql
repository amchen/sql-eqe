if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateNonAutoLookupView') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateNonAutoLookupView
end

go
create procedure absp_Util_CreateNonAutoLookupView @dropTables int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates the instead of trigger view for each non-auto lookup table


Returns:       None
====================================================================================================
</pre>
</font>
##BD_END
##PD  @dropTables    ^^ flag to drop tables.
*/
AS
begin

set nocount on
declare @sql nvarchar(max)
declare @tableName varchar(120)
declare @tableNameU varchar(120)
declare @eqeId varchar(20)
declare @trigName varchar(120)
declare @insertList varchar(max)
declare @updateList varchar(max)
declare @sourceDB varchar(120)

	set @sourceDB = DB_NAME()

	if @sourceDB = 'systemdb' or @sourceDB = 'commondb'
	begin
	 return
	end

	set @sql='declare curs2 cursor fast_forward global for '+
		'select rtrim(TABLENAME),rtrim(EQECOL) from systemdb.dbo.DICTTBLX where TYPE not in (''A'' , ''P'') 
		          and TABLENAME not in (''TIL'',''STATEL'',''LineOfBusiness'',''PolicyStatus'',''Reinsurer'',''TreatyTag'')  union ' +
		'select ''D0410'', ''TRANS_ID'''


	exec(@sql)


	open curs2
	fetch next from curs2 into @tableName, @eqeId
	if rtrim(@tableName) = 'PTL' set @eqeId ='PERIL_KEY'

	while @@fetch_status = 0
	begin
		set @tableNameU = @tableName + '_U'

		-- drop 'view' from the database if exists
		if exists (select 1 from SYSOBJECTS where id = OBJECT_ID(@tableName) and OBJECTPROPERTY(id, N'IsView') = 1)
		begin
			 set @sql = 'drop view ' + @tableName
			 print 'drop view ' + @tableName
			 exec(@sql)
		end
		-- create the view for each table
		if exists (select * from systemdb.dbo.SYSOBJECTS where xtype='U' and NAME = @tableName +  '_S')
		begin
			set @sql = 'create view ' + @tableName +
			' as select * from systemdb.dbo.' + @tableName +  '_S union select * from ' + @tableName +  '_U'
			print @sql
			exec(@sql)
		end


		-- Trigger INSTEAD OF INSERT
		set @trigName ='Trig_INS_' + @tableName

		if exists (select * from sysobjects where name = @trigName and OBJECTPROPERTY(id, 'IsTrigger') = 1)
		begin
			set @sql = 'drop trigger ' + @trigName
			print 'drop trigger ' + @trigName
			exec(@sql)
		end


		exec absp_Util_GetFieldNames @insertList output, @tableName, @eqeId, 'insert'


		set @sql = 'CREATE TRIGGER ' + @trigName  + ' ON ' + @tableName + ' ' +
		'INSTEAD OF INSERT AS ' +
		'begin ' +
		'SET NOCOUNT ON ' +
		--'  set IDENTITY_INSERT ' + @tableNameU + ' OFF ' +
		   'insert into ' + @tableNameU + ' (' + rtrim(@insertList) + ') ' +
		   'select ' +  rtrim(@insertList) + ' from inserted ' +
		'end '

		print @sql
		exec(@sql)

		-- Trigger INSTEAD OF DELETE
		set @trigName ='Trig_DEL_' + @tableName

		if exists (select * from sysobjects where name = @trigName and OBJECTPROPERTY(id, 'IsTrigger') = 1)
		begin
			set @sql = 'drop trigger ' + @trigName
			print 'drop trigger ' + @trigName
			exec(@sql)
		end

		set @sql =  'CREATE TRIGGER ' + @trigName + ' ON ' + @tableName + ' ' +
		'INSTEAD OF DELETE AS ' +
		'begin ' +
		'SET NOCOUNT ON ' +
		'delete ' + @tableNameU + ' from ' + @tableNameU + ' AS F join deleted AS d on F.' + @eqeId + '= d.' + @eqeId + ' ' +
		'end '
		print @sql
		exec(@sql)

		-- Trigger INSTEAD OF UPDATE
		set @trigName ='Trig_UPT_' + @tableName
		if exists (select * from sysobjects where name = @trigName and OBJECTPROPERTY(id, 'IsTrigger') = 1)
		begin
			set @sql = 'drop trigger ' + @trigName
			print 'drop trigger ' + @trigName
			exec(@sql)
		end

        	exec absp_Util_GetFieldNames @updateList output, @tableName, @eqeId, 'update'

		set @sql = 'CREATE TRIGGER ' + @trigName + ' ON ' + @tableName + ' ' +
		'INSTEAD OF UPDATE AS ' +
		'begin ' +
		'SET NOCOUNT ON ' +
		   'update '  + @tableNameU + ' set ' +  rtrim(@updateList) + ' from inserted i where i.' + @eqeId + ' = ' +  @tableNameU + '.' + @eqeId +  ' ' +
		'end '

		print @sql
		exec(@sql)

		if @dropTables = 1
		begin
		--drop table from systemdb
			select @sql = 'use systemdb ' +
					' IF EXISTS (SELECT * FROM [systemdb].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @tableName  + ''') ' +
				      	' drop table ' + @tableName
			print @sql
			exec(@sql)
		end

		fetch next from curs2 into @tableName, @eqeId
		if rtrim(@tableName) = 'PTL' set @eqeId ='PERIL_KEY'
	end
	close curs2
	deallocate curs2
end
