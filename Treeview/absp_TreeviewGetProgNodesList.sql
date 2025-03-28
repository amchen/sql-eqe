if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetProgNodesList') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewGetProgNodesList
end
go

create procedure absp_TreeviewGetProgNodesList @parentNodeKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a single result set, which contain information of all child nodes
underneath a program, sorted by child node names.

Returns:       A single result set, each record contains:

1. Child Key
2. Child Type
3. Name of the Child
4. Group key for the current user
5. Extra Key
6. Count
7. Attrib
====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey ^^  The key for the program to have its child nodes list fetched.


##RS  CHILD_KEY ^^  The key of the child node returned.
##RS  CHILD_TYPE ^^  The type of the child node.
##RS  LONGNAME ^^  The name of the child node.
##RS  GROUP_KEY ^^  The key of the Group the user belongs to. This determines if the user can see all groups, if the user is admin, he can see all groups.
##RS  EXTRA_KEY ^^  The CASE_KEY of the case that is marked as "Base Case".
There is only one base case for a program, and the first case (which is always created when a program is created) is by default the "Base Case".
Foreign key into table CASEINFO..
##RS  CNT ^^  Count or Number of the children being returned.
##RS  ATTRIB ^^  Attribute value.

*/
begin
   set nocount on
   declare @prog_Node_Type int
   declare @case_Node_Type int
  -- Based on the Program node type we can find out the case node_type since
  -- we cannot have a Multi-Treaty Case under a Regular Program and vice-versa
   execute  @prog_Node_Type = absp_Util_GetProgramType   @parentNodeKey
  -- SDG__00016117 - fixed the order in the tree for treaties in an account
  -- get cases
   if(@prog_Node_Type = 7)
   begin
      set @case_Node_Type = 10
      select   CASE_KEY as CHILD_KEY, @case_Node_Type as CHILD_TYPE, CASEINFO.LONGNAME as LONGNAME, PROGINFO.GROUP_KEY as GROUP_KEY, BCASE_KEY as EXTRA_KEY, 1 as CNT, CASEINFO.ATTRIB from
      CASEINFO join PROGINFO on CASEINFO.PROG_KEY = PROGINFO.PROG_KEY where
      CASEINFO.PROG_KEY = @parentNodeKey order by
      CASEINFO.LONGNAME asc
   end
   else
   begin
      if(@prog_Node_Type = 27)
      begin
         set @case_Node_Type = 30
         select   CASE_KEY as CHILD_KEY, @case_Node_Type as CHILD_TYPE, CASEINFO.LONGNAME as LONGNAME, PROGINFO.GROUP_KEY as GROUP_KEY, BCASE_KEY as EXTRA_KEY, 1 as CNT, CASEINFO.ATTRIB from
         CASEINFO join PROGINFO on CASEINFO.PROG_KEY = PROGINFO.PROG_KEY where
         CASEINFO.PROG_KEY = @parentNodeKey order by
         CASEINFO.INUR_ORDR asc
      end
   end
end





