if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getNodesWithAttribute') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getNodesWithAttribute
end
go

create  procedure  absp_getNodesWithAttribute  @nodeKey int, @nodeType int, @attribName varchar(25)='', @traverseMode int=0, @includeSelf int=0, @includeSibling int=0, @dbName varchar(120)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

Purpose: 	This procedure will check if the given node has self/parent/child having 
			a specific attribute and return a list of associated self/parent/child node 
			key(s) and types()that have attrib = @attribName. Depending on the
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
			
Returns: result sets of nodeKey, nodeType that have the attrib=@attribName
=================================================================================
</pre>
</font>
##BD_END
##PD  @nodeKey    ^^ The key of the node whose parent nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose parent nodes are to be determined
##PD  @@attribName   ^^ The attribute name to be search
##PD  @traverseMode ^^ hierarchical traverse direction
##PD  @includeSelf ^^ Whether the current node is to be included in the returned list
##PD  @includeSibling ^^ whether the sibling nodes are included in the returned list
##PD  @dbName ^^ Database to be included in the returned list
 */
as
begin
	set nocount on
	
	declare @exposureKey int
	declare @setting int

    declare @TableVar table (nodeKey int, nodeType int,ignore int,attribute int)
    declare @TableVar2 table (nodeKey int,nodeType int,attribute int,relation int)
	create table #SiblingNodeTmpTree(NodeKey int,NodeType int, Ignore int, attribute int)
	
	set @setting = 0;		
    -- build #batchtempTree based on traverse mode
    -- up or both
    if @traverseMode = 1 or @traverseMode = 3
    begin
		INSERT INTO @TableVar exec absp_Inv_GetUpNodes  @nodeKey, @nodeType , 0, 0, 0, 1 -- skip ebeRunID
		insert into @TableVar2 select nodekey, nodeType, attribute,2 from @TableVar -- 2 = parent
	end
	 -- down or both
	if @traverseMode = 2 or @traverseMode = 3
	begin
		delete @TableVar
		INSERT INTO @TableVar exec absp_Inv_GetdownNodes  @nodeKey, @nodeType , 0, 0, 0, 1
		insert into @TableVar2 select nodekey, nodeType, attribute,3 from @TableVar -- 3 = child
	end
	-- include self
	if @includeSelf = 1
	begin
		delete @TableVar
		INSERT INTO @TableVar values(@nodeKey, @nodeType, 0, 0)
		insert into @TableVar2 select nodekey, nodeType, attribute,1 from @TableVar -- 1 = self
	end
	-- include sibling
	if @includeSibling = 1
	begin
		delete @TableVar	
		exec absp_getSiblingNodesWithAttribute  @nodeKey, @nodeType, @attribName, @dbName
		insert into @TableVar2 select nodekey, nodeType, attribute,4 from #SiblingNodeTmpTree -- 4 = sibling node
	end
	
	-- reset the attribute
	update @TableVar2 set attribute=0
	
	if @dbName = '' 
		set @dbName = ltrim(rtrim(DB_NAME()));
	else
		set @dbName = ltrim(rtrim(@dbName));
		
	declare c1 cursor for select  nodeKey,nodeType  from @TableVar2
 	open c1
 	fetch c1 into @nodeKey,@nodeType
 	while @@fetch_status=0
 	begin
 		exec absp_InfoTableAttribGetGeneric @setting output, @nodeType, @nodeKey, @attribName, @dbName
 		if @setting = 1 
 			update @TableVar2 set attribute=1 where nodeType = @nodeType and nodeKey = @nodeKey
 			
 		fetch c1 into @nodeKey,@nodeType		
 	end
 		
 	close c1
 	deallocate c1

 	select nodeKey,nodeType,relation from @TableVar2 where attribute=1
 	
end

