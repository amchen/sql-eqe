if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteTableData') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteTableData
end
go

create procedure absp_Util_DeleteTableData @tableName varchar(255)
/*
##BD_BEGIN absp_Util_DropAllIndex ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will delete the given table and if it has any reference the it also deletes that table.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END


##PD  @tableName ^^  The name of the table which will be truncated.
##RD  @rc ^^ Returns nothing
*/
as

BEGIN

DECLARE @sql NVARCHAR(4000)
DECLARE @parentTableName VARCHAR(254)

	set @parentTableName = ''

	-- Check if the table has any reference table and if yes then delete the parent table first
	set @sql = 'select distinct @parentTableName = OBJECT_NAME(parent_object_id) from sys.foreign_keys where OBJECT_NAME(referenced_object_id) = ''' + @tableName + ''' and delete_referential_action_desc <> ''cascade'''
	execute absp_MessageEx  @sql
	exec sp_executesql @sql, N'@parentTableName VARCHAR(254) output, @tableName VARCHAR(254)',  @parentTableName output, @tableName

	-- if we don't have a parent table then delete it now else call this recursively to delete parent table
	if @parentTableName = ''
	begin
		set @sql = 'delete from ' + @tableName
		
		if @tableName = 'FLDRINFO'
			set @sql = @sql + ' where FOLDER_KEY > 0'
					
		execute absp_MessageEx  @sql
		exec (@sql)
	end
	else
	begin
		execute absp_MessageEx  @parentTableName
		exec absp_Util_DeleteTableData @parentTableName
		set @sql = 'delete from ' + @tableName
		
		if @tableName = 'FLDRINFO'
			set @sql = @sql + ' where FOLDER_KEY > 0'
			
		execute absp_MessageEx  @sql
		exec (@sql)

	end

END
