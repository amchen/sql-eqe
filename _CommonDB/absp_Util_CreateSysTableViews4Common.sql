if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateSysTableViews4commondb') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateSysTableViews4commondb
end

go
create procedure --------------------------------------------------------------
absp_Util_CreateSysTableViews4commondb

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates system table views in the commondb database


Returns:       None
====================================================================================================
</pre>
</font>
##BD_END


*/
AS
begin

 set nocount on

declare @tableName varchar(255)
declare @sql varchar(1000)

if (DB_NAME() != 'commondb')
begin
	print ' This stored prodecure must be executed on commondb database!'
	return
end


set @sql='declare curs1 cursor fast_forward global for select tablename from ' +
	'systemdb.dbo.DICTTBLX where type not in (''a'', ''p'') and tablename not in(''TIL'', ''STATEL'') '

--set @sql='declare curs1 cursor fast_forward global for select tablename from DICTTBLX  where type not in (''a'', ''p'') and tablename not in(''TIL'', ''STATEL'') '
exec(@sql)


open curs1
fetch next from curs1 into @tableName
while @@fetch_status = 0
begin
	-- drop 'view' from the database if exists
	if exists (Select 1 from sysobjects Where id = Object_ID(@tableName) and OBJECTPROPERTY(id, N'IsView') = 1)
	begin
		 set @sql = 'drop view ' + @tableName
		 print 'drop view ' + @tableName
		 exec(@sql)
	end
	-- create the view for each table
	set @sql = 'create view ' + @tableName + ' as select * from systemdb.dbo.' + @tableName + '_S'
	print @sql
	exec(@sql)
	
	set @sql = 'create view ' + @tableName + '_S' + ' as select * from systemdb.dbo.' + @tableName + '_S'
	print @sql
	exec(@sql)

	fetch next from curs1 into @tableName
end
close curs1
deallocate curs1

end