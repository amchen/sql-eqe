if exists(select * from sysobjects where id = object_id(N'absp_TreeviewGetChildNodesList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGetChildNodesList
end
GO

Create  procedure absp_TreeviewGetChildNodesList @currentNodeKey int ,@currentNodeType int ,@additionalKey int ,@fromKey int ,@toKey int ,@userKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a result set based on the currentNodeType
that properly has all child nodes in the correct and sorted order

Returns:       Result set that contains:

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

##PD  @currentNodeKey ^^  The key for the node to have its child nodes List fetched.
##PD  @currentNodeType ^^  The type of the node to have its child nodes List fetched.
##PD  @additionalKey ^^  An additional key; -1 in all cases except policy, where it has to be PORT_ID
##PD  @fromKey ^^  The key of the starting node.
##PD  @toKey ^^  The key of the ending node.
##PD  @userKey ^^  The USER_KEY of the current user. The USER_KEY will determine rights, and rights determine what is actually returned.

##RS  CHILD_KEY ^^  The key of the child node returned.
##RS  CHILD_TYPE ^^  The type of the node of the child.
##RS  LONGNAME ^^  The name of the child node.
##RS  GROUP_KEY ^^  The key of the Group the user belongs to. This determines if the user can see all groups, if the user is admin, he can see all groups.
##RS  EXTRA_KEY ^^  In case child node is a site, this extra key has the value of Port_Id else it always has -1.
##RS  CNT ^^  Count or Number of the children being returned.
##RS  ATTRIB ^^  Attribute value.
*/
begin
  -- The node type can be one of the followings:
  --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --Prog = 7;
  --Lport = 8;
  --MTRPORT = 23;
  --MTPROG = 27;
  -- call the correct lister based on the child type
   set nocount on
   if @currentNodeType = 0
   begin
      execute absp_TreeviewGetFolderNodesList @currentNodeKey,@userKey
   end
   else
   begin
      if @currentNodeType = 1
      begin
         execute absp_TreeviewGetAPortNodesList @currentNodeKey,@userKey
      end
      else
      begin
         if @currentNodeType = 3
         begin
            execute absp_TreeviewGetRPortNodesList @currentNodeKey,@userKey
         end
         else
         begin
            if @currentNodeType = 7
            begin
               execute absp_TreeviewGetProgNodesList @currentNodeKey
            end
            else
            begin
               if @currentNodeType = 23
               begin
                  execute absp_TreeviewGetRPortNodesList @currentNodeKey,@userKey
               end
               else
               begin
                  if @currentNodeType = 27
                  begin
                     execute absp_TreeviewGetProgNodesList @currentNodeKey
                  end
               end
            end
         end
      end
   end
end



