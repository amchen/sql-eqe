
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewCaseRename') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewCaseRename
end
 go

create procedure 
absp_TreeviewCaseRename @caseKey INT ,@newName CHAR(120) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL 
Purpose:       
This procedure renames a case.

Returns:   It returns nothing. It just uses the UPDATE statement to rename a case.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @caseKey ^^  The key for the case that is to be renamed.
##PD  @newName ^^  The new name of the case

*/
as
begin
 
   set nocount on
   
  update CASEINFO set LONGNAME = @newName  where
   CASE_KEY = @caseKey
end



