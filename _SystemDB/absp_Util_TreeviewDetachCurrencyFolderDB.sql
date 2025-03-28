if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_TreeviewDetachCurrencyFolderDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_TreeviewDetachCurrencyFolderDB
end

go
create procedure absp_Util_TreeviewDetachCurrencyFolderDB @dbName varchar(128) = ''
/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console; 
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure logically detaches the current currency folder database from the treeview
	(only works in multiple-databases environment)

Returns	None

====================================================================================================
pre
font
##BD_END
*/

AS
begin
	set nocount on
	declare @sql nvarchar(1000);
	declare @cfRefKey int;
	
	if LEN(@dbname) = 0 select @dbname = DB_NAME();

	select @cfRefKey = CF_REF_KEY from commondb.dbo.CFLDRINFO where DB_NAME= @dbName;
	delete from commondb.dbo.DownloadInfo where DbRefKey = @cfRefKey;
	delete from commondb.dbo.TaskInfo where DbRefKey = @cfRefKey;
	
	-- Since FLDRINFO does not have column CF_REF_KEY until the stored procedure absp_Util_CreateCurrencyFolderInfoTables is executed
	-- we will avoid SQL Server error during loading by storing the query in a string (and then use sp_executesql to execute it)
	
	select @sql = 'use [' + ltrim(rtrim(@dbname)) +']'+
	' begin ' + 
	' update FLDRINFO set CF_REF_KEY = 0 where CF_REF_KEY = ' +  dbo.trim(cast(@cfRefKey as varchar(30)))+ '; ' +
	' delete from commondb.dbo.CFLDRINFO where CF_REF_KEY =  ' +  dbo.trim(cast(@cfRefKey as varchar(30)))+ '; ' +
	' end '	
	--print @sql
	
	exec sp_executesql @sql
end
