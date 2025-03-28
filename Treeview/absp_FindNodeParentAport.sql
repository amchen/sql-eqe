if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNodeParentAport') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindNodeParentAport
end
 go
create procedure absp_FindNodeParentAport @ret_parentKey int output ,@ret_parentType int output, @nodeKey int,@nodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return
1. The key and the type (always 0) of the parent node (which is always a folder) for a given aport node via the parentKey & 
parentType OUTPUT parameters
2. The returned code signifying whether the parent folder node is found for the given aport node key

Returns:         A single value @retVal
1. @retVal = -1, a parent folder node is not found
2. @retVal =  1, a parent folder node is found


====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_parentKey ^^ The key of the parent folder node, returned as an OUTPUT parameter
##PD  @ret_parentType ^^ The type of the parent folder node (always 0 signifying a folder), returned as an OUTPUT parameter
##PD  @nodeKey ^^  The key of the aport node for which the parent folder needs to be identified. 
##PD  @nodeType ^^  The type of the node (unused as it is always an aport node) for which the parent folder needs to be identified. 

##RD  @retVal^^ A returned value, signifying whether  a parent folder node is found or not.


*/
as
begin

   set nocount on
   
  -- message 'in absp_FindNodeParentAport , nodeKey, nodeType  = ', nodeKey , nodeType;
   declare @retVal int
   set @ret_parentKey = -1
   set @ret_parentType = 0
   select top 1 @ret_parentKey = FOLDER_KEY  from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 1)
  --message 'in absp_FindNodeParentAport , parentKey  = ', ret_parentKey;
   if @ret_parentKey = -1
   begin
      set @retVal = -1
   end
   else
   begin
      set @retVal = 1
   end
   return @retVal
end

go


