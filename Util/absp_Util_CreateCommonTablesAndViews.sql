if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateCommonTablesAndViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateCommonTablesAndViews;
end
go

create procedure absp_Util_CreateCommonTablesAndViews @qryTableFilePath varchar(254) = 'C:\Projects\Data_Files\CD-Db\EDM\MISC\QRYTABLE.TXT'
/*
====================================================================================================
Purpose:

	This procedure
	 1. loads query table
     	 2. creates views  of system and common tables in each currency folder DB
Returns:	None
====================================================================================================
*/
AS
begin
	set nocount on;
	declare @sql nvarchar(2000);

	-- load data into eqectsystem.qrytable
	truncate table systemdb.dbo.qrytable;
	set @sql  = 'bulk insert systemdb.dbo.qrytable from ''' + @qryTableFilePath + ''' with (fieldterminator = ''|'')';
	exec sp_executesql @sql;

	update systemdb.dbo.qrytable set querytext = replace (dbo.trim(querytext), '\x0a' , ' ');
	update systemdb.dbo.qrytable set querytext = replace (dbo.trim(querytext), '\x09' , ' ');

	-- create views
	exec absp_Util_CreateGenericViews 'commondb';
	exec absp_Util_CreateGenericViews 'systemdb';

	-- explicitly create CFLDRINFO view
	if exists (select 1 from sys.views where name='CFLDRINFO' and type='V')
	begin
		print 'drop view CFLDRINFO';
		drop view CFLDRINFO;
	end
	set @sql = 'create view CFLDRINFO as select * from commondb.dbo.CFLDRINFO';

	print @sql;
	exec sp_executesql @sql;

	if exists (select 1 from sys.views where name='CHASAUTH' and type='V')
	begin
		print 'drop view CHASAUTH';
		drop view CHASAUTH;
	end
	set @sql = 'create view CHASAUTH as select * from systemdb.dbo.CHASAUTH';

	print @sql;
	exec sp_executesql @sql;
end
