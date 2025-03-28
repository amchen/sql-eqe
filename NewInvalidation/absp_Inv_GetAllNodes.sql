if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Inv_GetAllNodes ') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Inv_GetAllNodes 
end
go

create  procedure  absp_Inv_GetAllNodes  @nodeKey int, @nodeType int, @includeSelf int = 0,@isForceInvalidation int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:  	This procedure will  return a resultset that includes all the node key and node types 
		that require invalidation.


Returns: A resultset with node info of the nodes to be invalidated..
=================================================================================
</pre>
</font>
##BD_END

 */
as
begin
	set nocount on
	
	exec absp_Inv_GetUpNodes @nodeKey, @nodeType, @includeSelf,@isForceInvalidation 
	exec absp_Inv_GetDownNodes  @nodeKey, @nodeType, @includeSelf,@isForceInvalidation 

end