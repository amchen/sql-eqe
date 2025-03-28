if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteFromLogItTbl') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteFromLogItTbl
end
go

create procedure ----------------------------------------------------
absp_Util_DeleteFromLogItTbl @procName varchar(max) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes records from the LOGITTBL for the given stored procedure name.


Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @procName ^^  The procedure name for which the LOGITTBL record is to be deleted.
*/
as
begin

   set nocount on
   
  /*

  This procedure will delete all the procedure that matches the proc_name into LOGITTBL.
  Example,

  call absp_Util_DeleteFromLogItTbl ('absp_Arc--');

  This call will delete all procedure that starts with "absp_Arc--" from LOGITTBL.

  -- Documented on 28-10-2005 -----------------------------------------------------------------------------
  The parameter name [proc_name] is same as the column name of the LOGITTBL table, in the "Where" condition.
  as a result the procedure deletes all records of the LOGITTBL irrespective to the parameter passed.
  So the old parameter name [proc_name] has been changed to [procName]
  ---------------------------------------------------------------------------------------------------------
  */
   begin transaction
   delete from LOGITTBL where PROC_NAME like @procName
   commit work
end




