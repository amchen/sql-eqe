if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateAutoLookupTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateAutoLookupTables
end

go
create procedure absp_Util_CreateAutoLookupTables @dropTables int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates the auto lookup tables in the currency database


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
declare @userDb varchar(120)

	set @userDb = DB_NAME()

	if @userDb = 'systemdb' or @userDb = 'commondb'
	begin
	 return
	end

	set @sql='declare curs2 cursor fast_forward global for '+
		'select rtrim(tablename) from systemdb.dbo.DICTTBLX where TYPE in (''a'')'
	
	
	exec(@sql)


	open curs2
	fetch next from curs2 into @tableName
	while @@fetch_status = 0
	begin
		
		if exists (Select 1 from sysobjects Where id = Object_ID(@tableName) and OBJECTPROPERTY(id, N'IsView') = 1)
		begin
			 set @sql = 'drop view ' + @tableName
			 print 'drop view ' + @tableName
			 exec(@sql)
		end

				
		select @sql = 'use commondb ' +
			' IF NOT EXISTS (SELECT * FROM [' + @userDb + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @tableName  + ''') ' +
			' begin ' +
			' exec absp_Migr_MakeCopyTable '''', '''','''',''' + @tableName +''',0,''' + @userDb + ''' '  +
			--' drop table ' + @tableName + ' ' +   
			' end '
		print @sql
		
		exec sp_executesql @sql 
		
		-- drop tables
		if @dropTables = 1
		begin
			select @sql = 'use commondb ' +
				'IF EXISTS (SELECT * FROM [commondb].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @tableName  + ''') ' +
			      	' drop table ' + @tableName
			print @sql		
			exec sp_executesql @sql 
		end
		
		fetch next from curs2 into @tableName
	end
	close curs2
	deallocate curs2
end