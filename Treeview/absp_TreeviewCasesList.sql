
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewCasesList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewCasesList
end
 go

create procedure 
absp_TreeviewCasesList @progKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a result set giving the name and key of each Case associated with a given Program.
It also gives back the BCASE_KEY which is for the one and only one Base Case for this Program.
If CASEKEY equals BCASE_KEY then this case is the basecase



Returns:       A result set with four parameters:
1. CASE_KEY	the CASE_KEY for each Case
2. LONGNAME	the name associated with each Case
3. BCASE_KEY	the BCASE_KEY for the one and only one Base Case for this Program.
4. NODE_TYPE	the NODE_TYPE of the returned CASE node. It can be a CASE node (NODE_TYPE = 10)
or a Multi-Treaty CASE node (Node_TYPE = 30)

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The PROG_KEY of the program associated.

##RS  CASE_KEY ^^  the CASE_KEY for each Case.
##RS  LONGNAME ^^  the name associated with each Case.
##RS  BCASE_KEY ^^  the BCASE_KEY for the one and only one Base Case for this Program.If CASEKEY equals CASE_KEY then this case is the basecase.
##RS  NODE_TYPE ^^  the NODE_TYPE of the returned CASE node.It can be a CASE node (NODE_TYPE = 10) or a Multi-Treaty CASE node (Node_TYPE = 30)


*/
begin
 
   set nocount on
   
  select   CASEINFO.CASE_KEY as CASE_KEY, CASEINFO.LONGNAME as LONGNAME, PROGINFO.BCASE_KEY as BCASE_KEY, (case CASEINFO.MT_FLAG when 'Y' then
   30
   when 'N' then 10 
end) as NODE_TYPE from(CASEINFO join PROGINFO on PROGINFO.PROG_KEY = CASEINFO.PROG_KEY) where
   CASEINFO.PROG_KEY = @progKey order by
   CASEINFO.LONGNAME asc
end





