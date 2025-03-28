if exists(select * from sysobjects where id = object_id(N'absp_isChildofFolder') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_isChildofFolder
end
 go
create procedure absp_isChildofFolder @nodeKey int,@nodeType int,@folderKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure is used to find if a specified node is the child of a specified folder node.

Returns:       A single value @folderKey
1. @folderKey = -1, the parent folder node specified is not the actual parent of the specified child node.
2. @folderKey > 0, the node key of the parent folder node, signifying the parent folder node specified is the actual parent of the specified child node. 
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node for which the parent folder node needs to be identified. 
##PD  @nodeType ^^  The type of the node for which the parent folder node needs to be identified.
##PD  @folderKey ^^ The key of a folder node whose child may be the node specified.

##RD @folderKey ^^ A single value signifying whether a parent node is found or not.

*/
as
begin

   set nocount on
   
   declare @lastKey int
   declare @lastType int
   declare @lastCode int
   declare @parentKey int
   declare @parentType int
   --declare @folderKey INT
  --message '------------------------';
  -- message 'in absp_isChildofFolder, nodeKey, nodeType, folderKey  = ', nodeKey , nodeType, folderKey;
   if @folderKey <= 0
   begin
      set @folderKey = -1
      return @folderKey
   end
   set @lastKey = @nodeKey
   set @lastType = @nodeType
   set @lastCode = 1
   while @lastCode = 1
   begin
      execute @lastCode = absp_FindNodeParent @parentKey output,@parentType output,@lastKey,@lastType,@folderKey
      print 'in absp_FindNodeCurrencyKey , @lastCode, @parentKey, @parentType  = '
      print @lastCode
      print @parentKey
      print @parentType
      set @lastKey = @parentKey
      set @lastType = @parentType
    -- only return the currency key if the parentKey matches the folderKey
      if @lastCode = 3 or(@lastCode = 2 and @parentKey = @folderKey)
      begin
         return @folderKey
      end
   end
   set @folderKey = -1
   return @folderKey
end



