if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_UpdateTablesAfterCurrencyUpdate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_UpdateTablesAfterCurrencyUpdate;
end
go

create procedure absp_Util_UpdateTablesAfterCurrencyUpdate
	@folderName varchar(255),
	@groupKey int,
	@currNode char(1),
	@currskKey int,
	@folderKey int,
	@dbRefKey int 
	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:	MSSQL
Purpose:    This procedure will update the required tables after a currency update
Output:		Nothing
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin
	declare @sql nvarchar(max)
	set nocount on;
	
	set @sql = 'update FLDRINFO set LONGNAME = ''' + @folderName + ''' , GROUP_KEY = ''' + ltrim(rtrim(str(@groupKey))) + ''' , CURR_NODE = ''' + @currNode + ''', CURRSK_KEY = ''' + ltrim(rtrim(str(@currskKey))) + ''', STATUS =''ACTIVE'' where FOLDER_KEY = ''' + ltrim(rtrim(str(@folderKey))) + ''';';		
	exec(@sql)

	set @sql = 'update CFLDRINFO set LONGNAME = ''' + @folderName + ''' , GROUP_KEY = ''' + ltrim(rtrim(str(@groupKey))) + ''', CURRSK_KEY = ''' + ltrim(rtrim(str(@currskKey))) + ''' where FOLDER_KEY = ''' + ltrim(rtrim(str(@folderKey))) + ''' and CF_REF_KEY = ''' + ltrim(rtrim(str(@dbRefKey))) + ''';';
	exec(@sql)
	
	-- To satisfy Hibernate
	select '' as result
	
end
