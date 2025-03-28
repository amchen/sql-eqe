if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_MCF_Setup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MCF_Setup
end

go
create procedure absp_Util_MCF_Setup
@dbName varchar(128) = 'CF1',
@qryTableFilePath varchar(254) = 'C:\Projects\Features\Data_files\CD-Db\EDM\MISC\QRYTABLE.TXT'


/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console; 
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure runs stored procedures and scripts to create tables/views for multiple currency folder database environment
	(only works in multiple-databases environment)

Returns	None

====================================================================================================
pre
font
##BD_END
##PD  @dbName ^^ currency folder db name 
##PD  @qryTableFilePath ^^  path of QRYTABLE.TXT
*/

AS
begin
	set nocount on
	declare @vSQLStmt  varchar(4000)
	
	-- sync up the long name and the database name. This should be replaced with attach function 
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + ' update FLDRINFO set LONGNAME = DB_NAME() where CURR_NODE=''Y'''
	
	print @vSQLStmt
	execute (@vSQLStmt)
	
	-- add bits to the ATTRDEF table (will go away when 3.16 code is branched) 
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CURRENCY_AVAILABLE'', ATTRIBDESC=''Currency Node is available for use.'' where ATTRIB_ID=6;'	
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CF_MIGRATION_IN_PROGRESS'', ATTRIBDESC=''Currency Node is currently being migrated.'' where ATTRIB_ID=7;'	
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CF_MIGRATION_FAILED'', ATTRIBDESC=''Currency Node has been failed on migration.'' where ATTRIB_ID=8;'	
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CF_DETACH_IN_PROGRESS'', ATTRIBDESC=''Currency Node is currently being detached.'' where ATTRIB_ID=9'
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CF_MIGRATION_NEEDED'', ATTRIBDESC=''Currency Node Migration is needed.'' where ATTRIB_ID=10'
	set @vSQLStmt = @vSQLStmt + ' update ATTRDEF set ATTRIBNAME= ''CF_COPY_IN_PROGRESS'', ATTRIBDESC=''Currency Node is currently being copied.'' where ATTRIB_ID=11'
	
	print @vSQLStmt
	execute (@vSQLStmt)
	
	/* Not needed in RQE
	-- Alter table RQEVersion to add DBTYPE for system, common and CF/ CF_IR cans
	set @vSQLStmt = 'use systemdb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''RQEVersion'' and column_name=''DbType'') ' +
			' alter table RQEVersion add DbType varchar(3) not null default('''') ' 	
	print @vSQLStmt
	execute (@vSQLStmt)
	*/
	
	set @vSQLStmt = 'use systemdb '
	set @vSQLStmt = @vSQLStmt + ' update RQEVersion set DbType = ''SYS''' 
	print @vSQLStmt
	execute (@vSQLStmt)
	
	/* Not needed in RQE
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''RQEVersion'' and column_name=''DbType'') ' +
			' alter table RQEVersion add DbType varchar(3) not null default('''') '
	print @vSQLStmt
	execute (@vSQLStmt)
	*/
	
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt + ' update RQEVersion set DB_TYPE = ''COM''' 
	print @vSQLStmt
	execute (@vSQLStmt)
	
	/* Not needed in RQE
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''RQEVersion'' and column_name=''DbType'') ' +
			' alter table RQEVersion add DbType varchar(3) not null default('''') '
	print @vSQLStmt
	execute (@vSQLStmt)
	*/
	
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + ' update RQEVersion set DB_TYPE = ''EDB''' 
	print @vSQLStmt
	execute (@vSQLStmt)
	
	/* Not needed in RQE
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '_IR' + '] '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''RQEVersion'' and column_name=''DbType'') ' +
			' alter table RQEVersion add DbType varchar(3) not null default(''''); '
	print @vSQLStmt
	execute (@vSQLStmt)
	*/
	
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '_IR' + '] '
	set @vSQLStmt = @vSQLStmt + ' update RQEVersion set DB_TYPE = ''IDB'''
	print @vSQLStmt
	execute (@vSQLStmt)
	
	-- create CFLDRINFO table
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + ' exec absp_Util_CreateCurrencyFolderInfoTables'
	print @vSQLStmt
	execute (@vSQLStmt)
	
		
	
	-- modify USERGRPS for attach/detach permissions
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''USERGRPS'' and column_name=''GRP_ATACH'') ' +
			' alter table USERGRPS add [GRP_ATACH] [char] (1) NULL '
	print @vSQLStmt
	execute (@vSQLStmt)
	
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''USERGRPS'' and column_name=''GRP_DTACH'') ' +
			' alter table USERGRPS add [GRP_DTACH] [char] (1) NULL '
	print @vSQLStmt
	execute (@vSQLStmt)
	
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''USERGRPS'' and column_name=''OTHR_ATACH'') ' +
			' alter table USERGRPS add [OTHR_ATACH] [char] (1) NULL '
	print @vSQLStmt
	execute (@vSQLStmt)
	
	set @vSQLStmt = 'use commondb '
	set @vSQLStmt = @vSQLStmt +
			' if not exists (select * from INFORMATION_SCHEMA.COLUMNS where table_name=''USERGRPS'' and column_name=''OTHR_DTACH'') ' +
			' alter table USERGRPS add [OTHR_DTACH] [char] (1) NULL '
	print @vSQLStmt
	execute (@vSQLStmt)

	-- create other tables and views
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + ' exec absp_Util_CreateCommonTablesAndViews ''' + ltrim(rtrim(@qryTableFilePath)) + ''''
	print @vSQLStmt
	execute (@vSQLStmt)
	
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '_IR' + '] '
	set @vSQLStmt = @vSQLStmt + ' exec absp_Util_CreateCommonTablesAndViews ''' + ltrim(rtrim(@qryTableFilePath)) + ''''
	print @vSQLStmt
	execute (@vSQLStmt)
	

	set @vSQLStmt = 'use commondb ' 
	set @vSQLStmt = @vSQLStmt + ' exec absp_Util_CreatesystemdbViews '
	print @vSQLStmt
	execute (@vSQLStmt)
	
	-- add default row to RBROKER - should set the bit DICTTBL.CF_DB='L'
	set @vSQLStmt = 'use [' + ltrim(rtrim(@dbName)) + '] '
	set @vSQLStmt = @vSQLStmt + 
	' if (select count(*) from rbroker) = 0 ' +
	' insert into rbroker(name) values(''None'')'
	print @vSQLStmt
	execute (@vSQLStmt)


end
