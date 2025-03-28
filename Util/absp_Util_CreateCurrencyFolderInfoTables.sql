if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateCurrencyFolderInfoTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateCurrencyFolderInfoTables
end

go
create procedure absp_Util_CreateCurrencyFolderInfoTables @dbName varchar(40) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure
	 1. creates Table CFLDRINFO & Index in commondb
     	 2. adds CF_REF_KEY to Table FLDRINFO in each currency folder DB 
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
	select @sql = 'use commondb ' +
	' IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''dbo.[CFLDRINFO]'') AND type in (N''U'')) ' +
	'begin ' +
	'CREATE TABLE [CFLDRINFO]( ' +
	  ' [CF_REF_KEY] [int] IDENTITY(1,1) NOT NULL, ' +
	  ' [FOLDER_KEY] [int] NOT NULL, ' +
	  ' [LONGNAME] [char](120) NULL, ' +
	  ' [CREATE_DAT] [char](14) NULL, ' +
	  ' [CREATE_BY] [int] NOT NULL DEFAULT ((0)), ' +
	  ' [GROUP_KEY] [int] NOT NULL DEFAULT ((0)), ' +
	  ' [CURRSK_KEY] [int] NOT NULL DEFAULT ((0)), ' +
	  ' [ATTRIB] [int] NOT NULL DEFAULT ((0)), ' +
	  ' [DB_NAME] [char] (128) NULL, ' + ') ' +
	'end '
	exec sp_executesql @sql 
    
   	-- create index CFLDRINFO_I1 in commondb
	select @sql = 'use commondb ' +
	' IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = ''CFLDRINFO_I1'') ' +
	'begin ' +
	' create unique index [CFLDRINFO_I1] ON [dbo].[CFLDRINFO] ([CF_REF_KEY]) ' +
	'end '
	exec sp_executesql @sql 
	
	-- add new CF_REF_KEY column to Table FLDRINFO in each currency folder
	select @sql = 'use ' + @dbname + 
	
	' IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME=''FLDRINFO'' AND COLUMN_NAME=''CF_REF_KEY'') ' +
	' begin ' +
		'ALTER Table FLDRINFO Add CF_REF_KEY [int] NOT NULL DEFAULT ((0)) ' +
	' end'
	exec sp_executesql @sql
end