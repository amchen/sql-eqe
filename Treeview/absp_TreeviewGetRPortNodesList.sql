if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetRPortNodesList') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewGetRPortNodesList
end
go

create procedure absp_TreeviewGetRPortNodesList @parentNodeKey int ,@userKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a result set that contains information of all child nodes
underneath a re insurance portfolio, sorted by child node names.

Returns:       A result set that contains:

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

##PD  @parentNodeKey ^^  The key for the re insurance portfolio to have its child nodes list fetched.
##PD  @userKey ^^  The USER_KEY of the current user(unused). The USER_KEY will determine rights, and rights determine what is actually returned.

##RS  CHILD_KEY ^^  The key of the child node returned.
##RS  CHILD_TYPE ^^  The type of the child node.
##RS  LONGNAME ^^  The name of the child node.
##RS  GROUP_KEY ^^  The key of the Group the user belongs to. This determines if the user can see all groups, if the user is admin, he can see all groups.
##RS  EXTRA_KEY ^^  -1 for accounts and LPORT_KEY for programs.
##RS  CNT ^^  Count or Number of the children being returned.
##RS  ATTRIB ^^  Attribute value.

*/
begin
   set nocount on
   declare @rportGrpId int
   declare @rport_Node_Type int
   declare @prog_Node_Type int
  -- Based on the RPORT node type we can find out the program node_type since
  -- we cannot have a Multi-Treaty program under a Regular RPORT and vice-versa
   
   execute @rport_Node_Type = absp_Util_GetRPortType @parentNodeKey
   if(@rport_Node_Type = 3)
   begin
      set @prog_Node_Type = 7
   end
   else
   begin
      if(@rport_Node_Type = 23)
      begin
         set @prog_Node_Type = 27
      end
   end
   select   @rportGrpId = GROUP_KEY  from RPRTINFO where RPORT_KEY = @parentNodeKey
  -- get programs - for defect SDG__00014100, always say you are in the group of the RPORT
   select   A.CHILD_KEY as CHILD_KEY, A.CHILD_TYPE as CHILD_TYPE, LONGNAME as LONGNAME, @rportGrpId as GROUP_KEY, PROGINFO.LPORT_KEY as EXTRA_KEY, count(B.CHILD_TYPE) as CNT, ATTRIB from
   RPORTMAP as A, RPORTMAP as B, PROGINFO where
   A.CHILD_KEY = PROGINFO.PROG_KEY and
   A.RPORT_KEY = @parentNodeKey and A.CHILD_TYPE = @prog_Node_Type and A.CHILD_TYPE = B.CHILD_TYPE and
   A.CHILD_KEY = B.CHILD_KEY
   group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, PROGINFO.LPORT_KEY, ATTRIB order by
   LONGNAME asc
end






