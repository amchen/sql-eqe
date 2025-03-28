if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_AddVersionDbType') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AddVersionDbType
end

go
create procedure absp_Util_AddVersionDbType
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure set the dbtype  for  systemdb, commondb and currency folder DB
Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin
	set nocount on;

	declare @dbName varchar(128);
	declare @dbType varchar(3);

	select @dbName = LOWER(DB_NAME());
	set @dbName = rtrim(@dbname);

	if @dbName = 'systemdb'
		set @dbType = 'SYS';
	else if @dbName = 'commondb'
		set @dbType = 'COM';
	else if @dbName = 'rdb'
		set @dbType = 'RDB';
	else if SubString(@dbName,Len(@dbName) - 2, len(@dbName)) = '_ir'
		set @dbType = 'IDB';
	else
		set @dbType = 'EDB';

	if exists (select 1 from INFORMATION_SCHEMA.COLUMNS where table_name='RQEVersion')
	begin
		print 'absp_Util_AddVersionDbType=' + @dbType;
		update RQEVersion set DBType = rtrim(@dbType);
	end
end
