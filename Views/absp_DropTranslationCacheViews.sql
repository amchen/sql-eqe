if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DropTranslationCacheViews') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_DropTranslationCacheViews
end
go

create procedure absp_DropTranslationCacheViews @schemaName varchar(200)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure drops all the views that exist in the given schema.

Returns:        Returns nothing
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin
	set nocount on;
	declare  @viewName varchar(100);
	declare @sql varchar(max);

	if not exists (select 1 from sys.schemas where name = @schemaName )
		return;
	
	declare c1 cursor  for 
	   select name from  sysobjects where schema_name(uid)=  @schemaName  and objectproperty(id,N'IsView') = 1;
	open c1;
	fetch c1 into @viewName;
	while @@FETCH_STATUS =0
	begin
		set @sql =  ' drop view ' + dbo.trim(@schemaName) + '.'+ dbo.trim(@viewName);
		exec absp_MessageEx @sql;
		exec (@sql);
		fetch c1 into @viewName;
	end;
	close c1;
	deallocate c1;
end;

