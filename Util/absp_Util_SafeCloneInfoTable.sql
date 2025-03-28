if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SafeCloneInfoTable') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SafeCloneInfoTable
end
go

create procedure absp_Util_SafeCloneInfoTable
	@baseName char(120),
	@tableName char(120),
	@fieldName char(120),
	@skipKeyFieldNum int,
	@whereClause varchar(max),
	@fieldValueTrios varchar(max),
	@targetDB varchar(130)
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL

Purpose:    This Procedure will repeatedly call absp_Util_SafeGenericTableCloneRecords to clone records
of a given table until it succeeds.
If Two users paste the same records at the same time the same new name may be returned by
getUniqueName.  If that occurs, the record appended by the first user will cause the second
user attempt to fail.   So, this procedure will try again.

Returns:    @lastKey having a value >=0
====================================================================================================

</pre>
</font>
##BD_END

##PD   @baseName 	^^ The name based on which the unique name is to be generated.
##PD   @tableName 	^^ Name of a table for which record cloning has to be done.
##PD   @fieldName 	^^ Field name for which an unique name is to be generated.
##PD   @skipKeyFieldNum	^^ Field name that has to be skipped (0 --> not to skipped , any other number of the field that has to be skipped)
##PD   @whereClause 	^^ Record cloning criteria.
##PD   @fieldValueTrios 	^^ A string containg a list of values with which the columns of the inserted records are to be set
##RD   @lastKey     ^^ value of the last autogenerating key from the temporary table
*/
as
begin

   set nocount on
   
   
  /*
  SDG__00011987 -- if alreadyExists exception, try again

  This Procedure will repeatedly call absp_Util_SafeGenericTableCloneRecords until it succeeds.
  If Two users paste the same records at the same time the same new name may be returned by
  getUniqueName.  If that occurs, the record appended by the first user will cause the second
  user attempt to fail.   So, this procedure will try again.
  */
   declare @newName char(120)
   declare @lastKey int
   declare @newFieldValueTrios char(140)
   declare @sql nvarchar(max)
      
   if @targetDB=''
    	set @targetDB=DB_NAME()
    	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB


   set @lastKey = -1
   while @lastKey < 0
   begin
   
      set @sql = 'execute  ' + dbo.trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @baseName +''','+@tableName +','''+ @fieldName+''''
      execute sp_executesql @sql,N'@newName char(120) output',@newName output

      set @newFieldValueTrios = @fieldValueTrios+@newName
      execute @lastKey = absp_Util_SafeGenericTableCloneRecords @tableName,@skipKeyFieldNum,@whereClause,@newFieldValueTrios,1, @targetDB
   end
   return @lastKey
end
