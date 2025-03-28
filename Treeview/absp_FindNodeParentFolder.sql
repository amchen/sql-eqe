if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNodeParentFolder') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindNodeParentFolder
end
 go
create procedure absp_FindNodeParentFolder @ret_parentKey int output ,@ret_parentType int output, @nodeKey int,@nodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return
1. The key and the type (always 0 signifying a folder) of the parent folder node for a given node (only a folder is accounted for) via the parentKey & 
parentType OUTPUT parameter
2. The returned code signifying whether the parent folder node is found

Returns:         A single value @lastcode
1. @lastcode = -1, a parent folder node is not found
2. @lastcode = 1, a parent folder node is found


====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_parentKey ^^ The key of the parent folder node, returned as an OUTPUT parameter
##PD  @ret_parentType ^^ The type of the parent folder node, returned as an OUTPUT parameter
##PD  @nodeKey ^^  The key of the node for which the parent folder needs to be identified. 
##PD  @nodeType ^^  The type of the node (unused) for which the parent folder needs to be identified. 

##RD @lastCode ^^ Success flag: 1 indicates a parent folder node is found; -1 indicates a parent folder node is not found.


*/
as
begin

   set nocount on
   
   declare @lastKey int
   declare @lastType int
   declare @lastCode int
  --message 'in absp_FindNodeParentFolder , nodeKey, nodeType  = ', nodeKey , nodeType;
   set @lastKey = @nodeKey
   set @lastType = @nodeType
   set @lastCode = -1
   set @ret_parentKey = -1
   set @ret_parentType = 0
   select  @ret_parentKey = FOLDER_KEY  from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 0)
  -- message '*******in absp_FindNodeParentFolder , parentKey  = ', ret_parentKey;
  -- if the ret_parentKey = 0 then the node key is the currency node.Set the parent to the currency node key.
   if @ret_parentKey = 0
   begin
      set @ret_parentKey = @nodeKey
   end
   if @ret_parentKey = -1
   begin
      set @lastCode = -1
      return @lastCode
   end
   else
   begin
      set @lastCode = 1
      return @lastCode
   end
end

go


