if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Inv_GetUpNodes') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Inv_GetUpNodes
end
go

create  procedure  absp_Inv_GetUpNodes  @nodeKey int, @nodeType int, @includeSelf int = 0, @isForceInvalidation int, @recursiveFlag int=0, @skipEbeRunID int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

Purpose: 	This procedure will return the list of all the nodes that are higher 
		in the tree view excluding Folder Node but including paste-linked parents. 
		If the @includeSelf flag is set to true then along with the parent nodes 
		the same node will also be returned. 


Returns: A resultset containing child node keys and types.
=================================================================================
</pre>
</font>
##BD_END
##PD  @nodeKey    ^^ The key of the node whose parent nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose parent nodes are to be determined
##PD  @includeSelf ^^ Whether the current node is to be included in the return list
##PD  @recursiveFlag ^^ Whether the procedure is invoke recursively (0 for the first call)
 */
as
begin
	set nocount on
	
	declare @inurOrdr int
	declare @progKey int
	declare @invalidateIR  int
	declare @invalidateExpReport int
	declare @exposureKey int
		
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
			--For Program, if the invalidate is due to a change in Exposure Set information then we need to invalidate the IR tables
			if @nodeType=64  
			begin
				--Fixed defect 6367: Deletion of Failed / Cancelled Exposure is also Invalidating Node unnecessarily
				if exists(select 1 from exposureinfo where status in ('Cancelled', 'Failed') and exposureKey=@nodeKey)
					return
				if not exists(select 1 from ExposureMap where ParentType =27 and ExposureKey=@nodeKey)
					set @invalidateIR=0
			end	

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
	if  @includeSelf =1 
		insert into #TmpTree(NodeKey,NodeType,InvalidateIR,InvalidateExpReport)  values(@nodeKey,@nodeType,@invalidateIR,@invalidateExpReport)
	
	--Get the parent nodes
	--There can be multiple parents in case of PasteLink--
	
	if  @nodeType=2 or  @nodeType=23 
	begin
	 	insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
	 		select  Aport_Key,1,@invalidateIR,@invalidateExpReport from AportMap where Child_Key= @nodeKey and Child_Type = @nodeType  
	end
	else if @nodeType=27
	begin
		select @exposureKey = ExposureKey from ExposureMap where Parentkey=@nodeKey and ParentType=27
		if exists(select 1 from #TmpTree where NodeKey=@exposureKey and InvalidateIR=1)
			set @invalidateIR=1
		insert into @NodeTable(NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select  Rport_Key,23,@invalidateIR,@invalidateExpReport from RportMap where Child_Key= @nodeKey and Child_Type = @nodeType  	
	end		 
	else if @nodeType=30
	begin	
		insert into @NodeTable (NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select Prog_Key,27,@invalidateIR,@invalidateExpReport from CaseInfo where Case_Key = @nodeKey 
		
		select @inurOrdr=inur_ordr, @progKey=Prog_Key from CaseInfo where Case_Key=@nodeKey
		insert into @NodeTable (NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
			select Case_Key,30,@invalidateIR,@invalidateExpReport from CaseInfo where Prog_Key=@progKey and inur_ordr>@inurOrdr
	end
 	else if @nodeType=64
 	begin
 		insert into @NodeTable (NodeKey,NodeType,InvalidateIR,InvalidateExpReport) 
 			select ParentKey,ParentType,@invalidateIR,@invalidateExpReport from ExposureMap where ExposureKey=@nodeKey
 	end
 	
 	insert into #TmpTree select * from @NodeTable
 	
 	--Insert EBERunID for node--
	if @skipEbeRunID = 0 
		insert into #TmpTree select EBERunID,-1,@invalidateIR,@invalidateExpReport  from ELTSummary where NodeKey=@nodeKey and NodeType=@nodeType
	
 	--Get the parent recursively
 	declare c1 cursor for select NodeKey,NodeType  from @NodeTable
 	open c1
 	fetch c1 into @nodeKey,@nodeType
 	while @@fetch_status=0
 	begin
 		exec absp_Inv_GetUpNodes  @nodeKey, @nodeType,0,@isForceInvalidation,1,@skipEbeRunID
 		fetch c1 into @nodeKey,@nodeType
 	end
 	
 	close c1
 	deallocate c1
 	
 	if @recursiveFlag=0 select distinct * from #TmpTree order by nodeType desc,nodeKey desc
 	
end