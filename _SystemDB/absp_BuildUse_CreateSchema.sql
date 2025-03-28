if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_BuildUse_CreateSchema') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_BuildUse_CreateSchema;
end
go

create procedure absp_BuildUse_CreateSchema
	@schemaName varchar(200)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure createse a schema if it does not already exist.
Returns: None
====================================================================================================
</pre>
</font>
##BD_END
*/
AS
begin

	set nocount on;

    declare @sql nvarchar(max);

	if not exists (select schema_name from information_schema.schemata where schema_name = @schemaName)
	begin
		set @sql = 'create schema @schemaName';
		set @sql = replace(@sql, '@schemaName', @schemaName);
		exec sp_executesql @sql;
	end
end
