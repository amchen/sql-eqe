if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_TreeviewAttachCurrencyFolderDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_TreeviewAttachCurrencyFolderDB
end

go
create procedure absp_Util_TreeviewAttachCurrencyFolderDB @dbname varchar(128) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure logically attaches the current currency folder database from the treeview
	assuming the database is already attached
	(only works in multiple-databases environment)

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin
	set nocount on
	declare @sql nvarchar(1000)

	if LEN(@dbname) = 0 select @dbname = DB_NAME()

	-- create CFLDRINFO in commondb
	select @sql = 'use'
	select @sql = @sql +  ' ['+ @dbname +  ']'+
	' insert into commondb.dbo.CFLDRINFO( ' +
	'[FOLDER_KEY], [LONGNAME], [CREATE_DAT],[CREATE_BY],[GROUP_KEY],' +
	'[CURRSK_KEY], [ATTRIB], [DB_NAME]) ' +
	' select [FOLDER_KEY],[LONGNAME],[CREATE_DAT],[CREATE_BY], [GROUP_KEY], ' +
	' [CURRSK_KEY], [ATTRIB], DB_NAME() from FLDRINFO ' +
	' where [CURR_NODE] = ''Y'''
	--print @sql
	exec sp_executesql @sql

   	-- update the current database FLDRINFO CF_REF_KEY
   	select @sql = 'use'
	select @sql = @sql + ' [' + @dbname + ']'+
	 ' update FLDRINFO set FLDRINFO.[CF_REF_KEY] = C.[CF_REF_KEY] from FLDRINFO F,commondb.DBO.CFLDRINFO C ' +
	 ' where F.FOLDER_KEY = C.[FOLDER_KEY] and F.LONGNAME = C.LONGNAME and C.DB_NAME = ''' + ltrim(rtrim(@dbname)) + ''''
	--print @sql
	exec sp_executesql @sql

end
