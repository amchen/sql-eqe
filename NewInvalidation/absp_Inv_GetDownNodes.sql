if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Inv_GetDownNodes') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Inv_GetDownNodes
end
go

create  procedure absp_Inv_GetDownNodes  @nodeKey int, @nodeType int, @includeSelf int=0, @isForceInvalidation int, @recursiveFlag int=0, @skipEBERunID int=0, @oneLevelOnly int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose: 	This procedure will return the list of all the nodes that are child 
		of this node in the tree view excluding Folder Node but including paste-linked parents. 
		If the @includeSelf flag is set to true then along with the parent nodes the same node will also be returned. 

Returns: A resultset containing child node keys and types.
=================================================================================
</pre>
</font>
##BD_END
##PD  @nodeKey    ^^ The key of the node whose child nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose child nodes are to be determined
##PD  @includeSelf ^^ Whether the current node is to be included in the return list
##PD  @recursiveFlag ^^ Whether the procedure is invoke recursively (0 for the first call)

 */
as
begin
	set nocount on
	declare @invalidateIR  int
	declare @invalidateExpReport int
	
	--First time the procedure is invoked, set all flags
	if @recursiveFlag =0 
	begin
		create table #TmpTree(NodeKey int,NodeType int, InvalidateIR int, InvalidateExpReport int)  
		create table #TmpFlags(InvalidateIR int, InvalidateExpReport int)
		if @isForceInvalidation=1
		begin
			set @invalidateIR=1
			set @invalidateExpReport=1
		end
		else
		begin
			set @invalidateIR=1
			--If the invalidate is due to a change in Exposure Set information then we need to invalidate the Exposure Report tables
			if @nodeType=64 and @recursiveFlag=0 --First time
				set @invalidateExpReport=1
			else
				set @invalidateExpReport=0
		end
		insert into #TmpFlags values(@invalidateIR,@invalidateExpReport)
	end
	
	declare @NodeTable table (NodeKey int,NodeType int, InvalidateIR int, InvalidateExpReport int)
	select @invalidateIR=InvalidateIR,@invalidateExpReport=InvalidateExpReport from #TmpFlags
	
	--Include self--
	if  @includeSelf =1 and not (@nodeType=0 or @nodeType=12) 
		insert into #TmpTree(NodeKey,NodeType,InvalidateIR,InvalidateExpReport)  values(@nodeKey,@nodeType,@invalidateIR,@invalidateExpReport)
	
	if @nodeType=0 or @nodeType=12
	begin
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  Child_Key,Child_Type,@invalidateIR,@invalidateExpReport from FldrMap where Folder_Key= @nodeKey and Child_Type <>0 --exclude folders
	end
	else if @nodeType=1
	begin
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  Child_Key,Child_Type,@invalidateIR,@invalidateExpReport from AportMap where Aport_Key= @nodeKey  
	end
	else if @nodeType=2 
	begin
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  ExposureKey, 64,@invalidateIR,@invalidateExpReport from ExposureMap where ParentKey= @nodeKey  and ParentType=@nodeType
	end
	else if @nodeType=23
	begin
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  Child_Key,Child_Type,@invalidateIR,@invalidateExpReport from RportMap where Rport_Key= @nodeKey 
	end
	else if @nodeType=27
	begin
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  ExposureKey, 64,@invalidateIR,@invalidateExpReport from ExposureMap where ParentKey= @nodeKey  and ParentType=@nodeType
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  Case_Key, 30,@invalidateIR,@invalidateExpReport from CaseInfo where Prog_Key=@nodeKey
	end
	else if @nodeType=64
	begin
		 if exists(select 1 from exposureinfo where status in ('Cancelled', 'Failed') and exposureKey=@nodeKey)
			return
		--CaseKey for Exposures under Program
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport)  
			select  Case_Key, 30,@invalidateIR,@invalidateExpReport from ExposureMap inner join ProgInfo 
			on ExposureMap.ParentKey=ProgInfo.Prog_Key and ParentType=27
			inner join CaseInfo on ProgInfo.Prog_Key =CaseInfo.Prog_Key
			and ExposureMap.ExposureKey=@nodeKey
	end
	else if @nodeType =30
	begin
		if @skipEBERunID = 0 
			insert into #TmpTree select EBERunID,-1,@invalidateIR,@invalidateExpReport from ELTSummary where NodeKey=@nodeKey and NodeType=@nodeType
		return
	end
	else
		return
	
	insert into #TmpTree select * from @NodeTable
	
	--Insert EBERunID for node--
	if @skipEBERunID = 0 
		insert into #TmpTree select EBERunID,-1,@invalidateIR,@invalidateExpReport from ELTSummary where NodeKey=@nodeKey and NodeType=@nodeType
	
	-- go all the way down (default)
	if @oneLevelOnly = 0 
	begin
		 --Get the child nodes recursively
		 declare c1 cursor for select NodeKey,NodeType  from @NodeTable
		 open c1
		 fetch c1 into @nodeKey,@nodeType
		 while @@fetch_status=0
		 begin
	 		exec absp_Inv_GetDownNodes  @nodeKey, @nodeType,0,@isForceInvalidation,1,@skipEBERunID
	 		fetch c1 into @nodeKey,@nodeType
		 end
		 
		 close c1
		 deallocate c1
	end 
 	if @recursiveFlag=0 select distinct * from #TmpTree order by nodeType desc,nodeKey desc
end