if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getSiblingNodesWithAttribute') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getSiblingNodesWithAttribute
end
go

create  procedure  absp_getSiblingNodesWithAttribute  @nodeKey int, @nodeType int, @attribName varchar(25) = '', @dbName varchar(120) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

Purpose: 	This procedure will check if the given node has self/parent/child having 
			a specific attribute and return a list of associated sibling nodes 
			key(s) and types()that have attrib = @attribName. 

Returns: result sets of nodeKey, nodeType that have the attribute= @attribName
=================================================================================
</pre>
</font>
##BD_END
##PD  @nodeKey    ^^ The key of the node whose parent nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose parent nodes are to be determined
##PD  @@attribName   ^^ The attribute name to be search
##PD  @dbName ^^ Database to be included in the return list
 */
as
begin
	set nocount on
	declare @myNodeType int
	declare @myNodeKey int
	declare @parentType int
	declare @setting int
	declare @skipEBERunID int
	declare @downOneLevelOnly int
	declare @donotReturn int

	set @setting = 0
	set @skipEBERunID = 1
	set @downOneLevelOnly = 1
	set @donotReturn = 0
	
	IF OBJECT_ID('tempdb..#SiblingNodeTmpTree','u') is NULL
		create table #SiblingNodeTmpTree(NodeKey int,NodeType int, Ignore int, attribute int)
	else 
		set @donotReturn = 1

	create table #ParentNodeTmpTree(NodeKey int,NodeType int, Ignore int, attribute int)
		
	-- temporarily save the all parent nodes
	INSERT INTO #SiblingNodeTmpTree exec absp_Inv_GetUpNodes  @nodeKey, @nodeType , 0, 0, 0, @skipEBERunID --skip EBERunID
	-- collect the immediate parent nodes
	if @nodeType = 30 insert into #ParentNodeTmpTree select * from #SiblingNodeTmpTree where nodeType=27
	if @nodeType = 27 insert into #ParentNodeTmpTree select * from #SiblingNodeTmpTree where nodeType=23
	if @nodeType = 23 insert into #ParentNodeTmpTree select * from #SiblingNodeTmpTree where nodeType=1
	if @nodeType = 2 insert into #ParentNodeTmpTree select * from #SiblingNodeTmpTree where nodeType=1
	
	-- clean up saved parent nodes
	delete #SiblingNodeTmpTree
	
	-- get the sibling nodes
	if exists (select count(*) from #ParentNodeTmpTree)
	 begin
		declare c1 cursor for select distinct NodeKey,NodeType  from #ParentNodeTmpTree
		open c1
		fetch c1 into @myNodeKey,@myNodeType
		while @@fetch_status=0
		begin
			insert into #SiblingNodeTmpTree exec absp_Inv_GetDownNodes  @myNodeKey, @myNodeType , 0, 0, 0, @skipEBERunID , @downOneLevelOnly 
			fetch c1 into @myNodeKey,@myNodeType		
		end
	 		
		close c1
		deallocate c1
	 end
	 
	 -- exclude my self from the sibling node
	 delete from #SiblingNodeTmpTree where nodeKey = @nodeKey and nodeType = @nodeType
	 
	 -- reset the attribute
	 update #SiblingNodeTmpTree set attribute = 0
			
	-- get the sibling nodes having attribute = @attribName
	if exists (select count(*) from #SiblingNodeTmpTree)
	begin
		declare c2 cursor for select distinct NodeKey,NodeType  from #SiblingNodeTmpTree
		open c2
		fetch c2 into @myNodeKey,@myNodeType
		while @@fetch_status=0
		begin

			exec absp_InfoTableAttribGetGeneric @setting output, @myNodeType, @myNodeKey, @attribName, @dbName
			if @setting = 1 
			begin
				update #SiblingNodeTmpTree set attribute=1 where nodeType = @myNodeType and nodeKey = @myNodeKey
			end
			fetch c2 into @myNodeKey,@myNodeType		
		end
	 		
		close c2
		deallocate c2
	end
	
    if @donotReturn = 0
		select * from #SiblingNodeTmpTree where nodeType = @nodeType and nodeKey != @nodeKey and attribute=1
end
