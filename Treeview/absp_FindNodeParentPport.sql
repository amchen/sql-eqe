if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNodeParentPport') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindNodeParentPport
end
 go
create procedure absp_FindNodeParentPport @ret_parentKey int output ,@ret_parentType int output, @nodeKey int,@nodeType int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return
1. The key and the type of the parent node for a given pport node via the parentKey & 
parentType[0 in case of folder and 1 in case of Accumulation portfolio] OUTPUT parameters
2. The returned code signifying whether the parent node is found for the given pport node key

Returns:         A single value @retVal
1. @retVal = -1, a parent node is not found
2. @retVal = 1, a parent node is found


====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_parentKey ^^ The key of the parent node, returned as an OUTPUT parameter
##PD  @ret_parentType ^^ The type of the parent node, returned as an OUTPUT parameter
##PD  @nodeKey ^^  The key of the pport node for which the parent node needs to be identified. 
##PD  @nodeType ^^  The type of the node (unused as it is always an pport node) for which the parent node needs to be identified. 

##RD  @retVal^^ A returned value signifying whether a parent node has been found or not.


*/
as
begin

   set nocount on
   
  --message 'in absp_FindNodeParentPport , nodeKey, nodeType  = ', nodeKey , nodeType;
   declare @retVal int
   set @ret_parentKey = -1
   set @ret_parentType = 1
   select top 1 @ret_parentKey = APORT_KEY  from APORTMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 2)
   if @ret_parentKey = -1
   begin
      set @ret_parentType = 0
      select top 1 @ret_parentKey = FOLDER_KEY  from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 2)
   end
  --message 'in absp_FindNodeParentPport , parentKey  = ', ret_parentKey;
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


