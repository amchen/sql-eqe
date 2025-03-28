
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewCasePartsDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewCasePartsDelete
end
 go

create procedure 
absp_TreeviewCasePartsDelete @caseKey INT 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes a case and all the treaty case information for the given case node key.
The related treaty case information include the following:-
1) The treaty Case Exclusions
2) The treaty Case Reinstatements
3) The treaty Case Industry Loss Triggers
4) The treaty Case Layer Data
5) Treaty Case Information



Returns:       It returns nothing. It uses the DELETE statement to remove a case & its related informaton.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @caseKey ^^  The key of the case node for which the case and treaty information are to be removed. 


*/
as
begin

   set nocount on
   
  -- deletes all the child parts of a Case
   delete from CASEEXCL where CASE_KEY = @caseKey
   delete from CASEREIN where CASE_KEY = @caseKey
--   delete from CASETRIG where CASE_KEY = @caseKey
   delete from CASELAYR where CASE_KEY = @caseKey
   delete from CASEINFO where CASE_KEY = @caseKey
end




