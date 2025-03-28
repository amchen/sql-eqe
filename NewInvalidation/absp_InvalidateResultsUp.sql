if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateResultsUp') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateResultsUp
end
go

create  procedure absp_InvalidateResultsUp  @nodeKey int, @nodeType int, @isForceInvalidation int=0, @actionType varchar(30) = 'InvalidateUpNodes'
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:  The procedures will invalidate all nodes that require invalidation.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

 */
as
begin
	set nocount on
	declare @invalidateIR int;
	declare @invalidateExpRpt int;
	declare @cnt1 int;
	declare @cnt2 int;
	declare @parentKey int;
	declare @parentType int;
	declare @taskProgressMsg varchar(max);	
	declare @taskKey int;
	declare @procID int;
	
	-- Get the Procedure ID and the TaskKey since we need to add entries to TaskProgress
	set @procID = @@PROCID;
	exec @taskKey = absp_getTaskKey @nodeKey,@nodeType;

	-- Add a task progress message
	set @taskProgressMsg = 'Invalidation started.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	create table #TmpNodes (NodeKey int,NodeType int, InvalidateIR int, InvalidateExpReport int);
	
	--Get the node list to be invalidated
	
	if @actionType= 'InvalidateUpNodes'
		insert into #TmpNodes exec absp_Inv_GetUpNodes @nodeKey,@nodeType,0,@isForceInvalidation;
	else if @actionType= 'InvalidateDownNodes'
		insert into #TmpNodes exec absp_Inv_GetDownNodes  @nodeKey,@nodeType,0,@isForceInvalidation;
	else if @actionType= 'InvalidateUpNodesAndSelf'
		insert into #TmpNodes exec absp_Inv_GetUpNodes @nodeKey,@nodeType,1,@isForceInvalidation;
	else if @actionType= 'InvalidateDownNodesAndSelf'
		insert into #TmpNodes exec absp_Inv_GetDownNodes @nodeKey,@nodeType,1,@isForceInvalidation;
	else if @actionType= 'InvalidateUpDownNodes'
		insert into #TmpNodes exec absp_Inv_GetAllNodes @nodeKey,@nodeType,0,@isForceInvalidation;
	else if @actionType= 'InvalidateUpDownNodesAndSelf '
		insert into #TmpNodes exec absp_Inv_GetAllNodes @nodeKey,@nodeType,1,@isForceInvalidation;
		
		
	--Invalidate each node--
	declare c1 cursor for select distinct NodeKey,NodeType,InvalidateIR,InvalidateExpReport from #TmpNodes
	open c1
	fetch c1 into @nodeKey,@nodeType,@invalidateIR, @invalidateExpRpt
	while @@fetch_status=0
	begin
		if @nodeType=1
		begin
			-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Accumulation Portfolio with Node Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			exec absp_InvalidateByAportKey @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
		end	
		else if @nodeType=2
		begin
			-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Primary Portfolio with Node Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			exec absp_InvalidateByPPortKey @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
		end	
		else if @nodeType=23
		begin
			-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Reinsurance Portfolio with Node Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			exec absp_InvalidateByRPortKey @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
		end	
		else if @nodeType=27
		begin
		 	-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Program with Node Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
		 	exec absp_InvalidateByProgKey @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
		end 	
		else if @nodeType=30
		begin
			-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Treaty with Node Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			exec absp_InvalidateByTreatyKey  @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
		end	
		else if @nodeType=64
		begin
			-- Add a task progress message
			set @taskProgressMsg = 'Invalidating Exposure with Exposure Key = ' + cast(@nodeKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			exec absp_InvalidateByExposureKey @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;
			-- When we do force invalidation then we do not need to remove the ExposureMap entry
			if (@isForceInvalidation = 0) 
			begin
				--Check if parent is paste liked--
				set @cnt2=0
				select @parentKey = ParentKey, @parentType=ParentType from ExposureMap where ExposureKey=@nodeKey; 
				if @parentType=27
				begin
					select   @cnt1 = count(*)  from RportMap where Child_Key = @parentKey and Child_Type = @parentType
					if @cnt1=1
					begin
						select @parentKey=Rport_Key from RportMap where Child_Key = @parentKey --Get Parent Rport
						select   @cnt1 = count(*)  from FldrMap where Child_Key = @parentKey and Child_Type = 23
   						select   @cnt2= count(*)  from AportMap where Child_Key = @parentKey and Child_Type = 23
					end
				end
				else
				begin
					select   @cnt1 = count(*)  from FldrMap where Child_Key = @parentKey and Child_Type = @parentType
   					select   @cnt2= count(*)  from AportMap where Child_Key = @parentKey and Child_Type = @parentType
   				end
				if @cnt1 + @cnt2 =1
				begin
					delete from exposuremap where exposureKey=@nodeKey;						
				end		
			end
		end
		else if @nodeType=-1
			exec absp_InvalidateByEBERunID @nodeKey, @invalidateIR, @invalidateExpRpt,@taskKey;

		fetch c1 into @nodeKey,@nodeType,@invalidateIR, @invalidateExpRpt;
	end;
	close c1;
	deallocate c1;
	 
	-- Add a task progress message
	set @taskProgressMsg = 'Invalidating completed successfully.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID; 
 

end;