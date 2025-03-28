if exists(select * from sysobjects where id = object_id(N'absp_AmIChildOf') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_AmIChildOf
end
 go
create procedure absp_AmIChildOf @theParentKey int ,@theParentType int,@myNodeKey int,@myNodeType int
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

This procedure is used to find if a specified node is the child of another specified node.
If nodeType = 8 (policy) or 9 (site), the nodeKey should be the portID.

Returns:      A single value @lastcode
1. @lastcode = -1, the parent node specified is not the actual parent of the specified child node.
2. @lastcode > 0, the node key of the parent node, signifying the parent node specified is the actual parent of the specified child node. 
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @theParentKey ^^ The key of the parent node.
##PD  @theParentType ^^ The type of the parent node.
##PD  @myNodeKey ^^ The key of the child node.
##PD  @myNodeKey ^^ The type of the child node.
##RD @lastCode ^^ A single value signifying whether the specified parent
node is the actual parent of the specified child node.

*/
 --
-- This is use to check if any batch job is underneath a node
--
begin

   set nocount on
   
   declare @lastCode int
   execute @lastCode = absp_isChildofNode @myNodeKey,@myNodeType,@theParentKey,@theParentType
   return @lastCode
end






