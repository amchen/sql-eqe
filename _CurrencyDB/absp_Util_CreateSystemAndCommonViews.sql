if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateSystemAndCommonViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateSystemAndCommonViews;
end
go

create procedure absp_Util_CreateSystemAndCommonViews
/*
====================================================================================================
Purpose:
	This procedure creates views to systemdb and commondb tables in the User database.
    Also explicitly recreates the CFLDRINFO view.
Returns:	None
====================================================================================================
*/
AS
begin
	set nocount on;
	declare @sql nvarchar(2000);

	-- create views
	exec absp_Util_CreateGenericViews 'systemdb';
	exec absp_Util_CreateGenericViews 'commondb';

	-- explicitly create CFLDRINFO view
	if exists (select 1 from sys.views where name='CFLDRINFO' and type='V')
	begin
		print 'drop view CFLDRINFO';
		drop view CFLDRINFO;
	end
	set @sql = 'create view CFLDRINFO as select * from commondb.dbo.CFLDRINFO';

	print @sql;
	exec sp_executesql @sql;
end
