if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DisableIndex') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DisableIndex
end
go

create procedure absp_Util_DisableIndex @tableName varchar(128), @disable int=1
/*
##BD_BEGIN absp_Util_DisableIndex ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure disables/rebuilds all the indicies for a given table.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END


##PD  @fileName ^^  The name of the table whose index will get disabled/rebuilt.
##RD  @rc ^^ Returns nothing
*/
as

begin
	declare @indexName varchar(128)
	declare @sql varchar(max)
	declare @disableSql varchar(8)
	
	if @disable=1
		set @disableSql=' DISABLE'
	else
		set @disableSql=' REBUILD'
	
	--exclude clustered indexes
	declare tableIndexes cursor for
 		 select name from sys.indexes where  object_id = OBJECT_ID(@tableName) and type<>1

	open tableIndexes
	fetch tableIndexes into @indexName

	while @@fetch_status = 0
	begin
		set @sql = 'ALTER INDEX ' + @indexName + ' ON ' + dbo.trim(@tableName) + @disableSql
		print @sql
		exec(@sql)
		fetch tableIndexes into @indexName
	end

	close tableIndexes
	deallocate tableIndexes

END
