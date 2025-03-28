if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getNodesWithBatchInProgress') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getNodesWithBatchInProgress
end
go

create  procedure  absp_getNodesWithBatchInProgress  @nodeKey int, @nodeType int,  @traverseMode int = 0, @includeSelf int = 0, @includeSibling int = 0,@dbName varchar(120) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

Purpose: 	This procedure will check if the given node has self/parent/child having 
			attribute=Batch-in-progress and return a list of associated self/parent/child node 
			key(s) and types()that have batch jobs in progress. Depending on the
			provided combination of @includeSelf flag(0/1) and @traverseMode, the 
			return list could be the list of self, child, parent or all child & parent
			nodes
			@traverseMode:
				0: no up & down(default)
				1: up
				2: down
				3: both up & down
			@includeSelf: 0 or 1
			@includeSibling: 0 or 1

Returns: result sets of nodeKey, nodeType that have the attrib=Batch-in-progress
=================================================================================
</pre>
</font>
##BD_END
##PD  @nodeKey    ^^ The key of the node whose parent nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose parent nodes are to be determined
##PD  @traverseMode ^^ hierarchical traverse direction
##PD  @includeSelf ^^ Whether the current node is to be included in the return list
##PD  @includeSibling ^^ whether the sibling nodes are included in the returned list
##PD  @dbName ^^ Database to be included in the return list
 */
as
begin
	set nocount on
	exec absp_getNodesWithAttribute  @nodeKey, @nodeType, 'BATCH_IN_PROGRESS', @traverseMode, @includeSelf, @includeSibling, @dbName
end