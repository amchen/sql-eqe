if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateResults') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateResults
end
go

create  procedure absp_InvalidateResults  @actionType varchar(30),@nodeKey int, @nodeType int, @isForceInvalidation int
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
BEGIN TRY
	set nocount on
	declare @invalidateIR int;
	declare @invalidateExpRpt int;
	declare @cnt1 int;
	declare @cnt2 int;
	declare @parentKey int;
	declare @parentType int;
	
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
	declare c1 cursor for select NodeKey,NodeType,InvalidateIR,InvalidateExpReport from #TmpNodes
	open c1
	fetch c1 into @nodeKey,@nodeType,@invalidateIR, @invalidateExpRpt
	while @@fetch_status=0
	begin
		if @nodeType=1
			exec absp_InvalidateByAportKey @nodeKey, @invalidateIR, @invalidateExpRpt;
		else if @nodeType=2
			exec absp_InvalidateByPPortKey @nodeKey, @invalidateIR, @invalidateExpRpt;
		else if @nodeType=23
			exec absp_InvalidateByRPortKey @nodeKey, @invalidateIR, @invalidateExpRpt;
		else if @nodeType=27
		 	exec absp_InvalidateByProgKey @nodeKey, @invalidateIR, @invalidateExpRpt;
		 else if @nodeType=30
			exec absp_InvalidateByTreatyKey  @nodeKey, @invalidateIR, @invalidateExpRpt;
		else if @nodeType=64
		begin
			exec absp_InvalidateByExposureKey @nodeKey, @invalidateIR, @invalidateExpRpt;
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
			exec absp_InvalidateByEBERunID @nodeKey, @invalidateIR, @invalidateExpRpt;

		fetch c1 into @nodeKey,@nodeType,@invalidateIR, @invalidateExpRpt;
	end;
	close c1;
	deallocate c1;
	
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH