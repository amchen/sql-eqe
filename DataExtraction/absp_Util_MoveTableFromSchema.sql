if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_MoveTableFromSchema') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_MoveTableFromSchema;
end
go

create procedure  absp_Util_MoveTableFromSchema @tableName varchar(130),@sourceSchema varchar(200),@targetSchema varchar(200)
as

/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	This procedure moves a table from one schema to another.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##PD  @tableName ^^ The table name to be transferred
##PD  @sourceSchema ^^ The source schema from where the table will get transferred
##PD  @targetSchema ^^ The target schema  where the table will get transferred

##BD_END
*/
begin
	set nocount on
	declare @sql varchar(8000)	
	set @sql = 'alter schema ' + @targetSchema + ' transfer  ' + dbo.trim(@sourceSchema) + '.' + dbo.trim(@tableName)
	exec(@sql)
end