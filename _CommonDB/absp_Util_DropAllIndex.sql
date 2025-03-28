if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DropAllIndex') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DropAllIndex
end
go

create procedure absp_Util_DropAllIndex @tableName varchar(128)
/*
##BD_BEGIN absp_Util_DropAllIndex ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure drops all the indicies for a given table.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END


##PD  @fileName ^^  The name of the table whose index will get dropped.
##RD  @rc ^^ Returns nothing
*/
as

BEGIN
DECLARE @indexName NVARCHAR(128)
DECLARE @dropIndexSql NVARCHAR(4000)

DECLARE tableIndexes CURSOR FOR

 SELECT a.name FROM sysindexes a, sys.indexes b
		WHERE a.id = OBJECT_ID(LTRIM(RTRIM(@tableName)))
		AND   a.indid > 0 AND a.indid < 255
		AND   INDEXPROPERTY(a.id, a.name, 'IsStatistics') = 0
		AND   a.name like '%[_]I%'
 		AND a.id=b.object_id
 		AND b.is_primary_key=0
		ORDER BY a.indid DESC

OPEN tableIndexes
FETCH NEXT FROM tableIndexes INTO @indexName

WHILE @@fetch_status = 0
BEGIN
	SET @dropIndexSql = N'DROP INDEX ' + LTRIM(RTRIM(@tableName)) + '.' + @indexName
	exec absp_Util_LogIt @dropIndexSql, 1, 'absp_Util_DropAllIndex'
	EXEC sp_executesql @dropIndexSql
	FETCH NEXT FROM tableIndexes INTO @indexName
END

CLOSE tableIndexes
DEALLOCATE tableIndexes

END
