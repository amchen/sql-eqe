if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SafeGenericTableCloneRecords') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SafeGenericTableCloneRecords
end
go

create procedure absp_Util_SafeGenericTableCloneRecords
	@tableName varchar(4000),
	@skipKeyFieldNum int,
	@whereClause varchar(max),
	@fieldValueTrios varchar(max),
	@display int = 1,
	@targetDB varchar(130)=''
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MS SQL Server

Purpose:    This procedure calls absp_GenericTableCloneRecords() to clone records of the base table and catches
the exceptions for duplicateKey and deadlocks. It returns the autogenerating Key if a record is cloned,
error codes for duplicateKeys and deadlocks else the system generated error is displayed.

Returns:    -1 when a duplicateKey exception
-2 when a deadlock exception 
0 or value of the last autogenerating key 

====================================================================================================

</pre>
</font>
##BD_END

##PD   tableName	^^ Name of a table for which record cloning has to be done.
##PD   skipKeyFieldNum	^^ Field name that has to be skipped (0 --> not to skipped , any other number of the field that has to be skipped)
##PD   whereClause	^^ Record cloning criteria.
##PD   fieldValueTrios 	^^ Format, how to change field name in the temporary table created from the base table. This format has to be in accordance to the expected parameter of procodure "absp_StringSetFields"
##PD   display		^^ A flag used for displaying messages.
##RD   @lastKey		^^  -1 when a duplicateKey exception,-2 when a deadlock exception, 0 or value of the last autogenerating key if success
*/
as
begin

   set nocount on
   
  /*
  SDG__00011987 -- if alreadyExistsException or deadLockException, Return @lastKey less than 0.

  This Procedure will call absp_GenericTableCloneRecords and safely catch alreadyExists exceptions.
  If not exception, the new Key is returned, otherwise a values less than 0 is return to inform
  the caller of the problem.   The caller should try again.
  This routine is called by absp_Util_SafeCloneInfoTable.
  */
   declare @lastKey int
   declare @msgText varchar(max)
  
    if @targetDB=''
    	set @targetDB=DB_NAME()
    	
    --Enclose within square brackets--
    execute absp_getDBName @targetDB out, @targetDB
    	
	begin try
      set @lastKey = -1
      execute @lastKey = absp_GenericTableCloneRecords @tableName,@skipKeyFieldNum,@whereClause,@fieldValueTrios,0,@targetDB
      return @lastKey
   	end try
	begin catch
      if @display > 0
      begin
         set @msgText = 'absp_Util_SafeGenericTableCloneRecords Ignoring alreadyExistsException for '+@tableName
         execute absp_MessageEx @msgText
      end

      set @lastKey = -1
      return @lastKey
   end catch
end
