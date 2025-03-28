if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ApplyBrowserDataFilter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ApplyBrowserDataFilter
end
 go

create procedure absp_ApplyBrowserDataFilter @nodeKey int, @nodeType int, @taskKey int=0, @userKey int=1,@debug int=0						
as
begin try
	set nocount on
	
	declare @sql varchar(max);
	declare @colList varchar(max);
	declare @filterTableName varchar(200);
	declare @defaultOrderBy varchar(max);
	declare @orderByClause varchar(max);
	declare @createDt varchar(25)
	declare @startTime datetime
    declare @endMsg varchar(120)
    declare @stepNumber int
    declare @exposureKeyList varchar(max);
    declare @addTaskSteps int;
    declare @taskInProgress int;
	declare @procId int;
    
    set @procID = @@PROCID;
    set @addTaskSteps=0;
   	    
	-- assign task process ID to the task so the task can be cancelled
	begin transaction;
	update TaskInfo set TaskDBProcessID=@@spid where TaskKey=@taskKey;
	commit transaction;
	
   	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
	set @taskInProgress=0;
	
	--Add Steps to TaskStepInfo--
	if not exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType)
	begin
		if @nodeType=2 and exists(select 1 from taskInfo where taskKey=@taskKey and PPortKey=@nodeKey and NodeType=@nodeType and TaskTypeID=4)
			set @taskInProgress=1
		else if  @nodeType=27 and exists(select 1 from taskInfo where taskKey=@taskKey and ProgramKey=@nodeKey and NodeType=@nodeType and TaskTypeID=4)
			set @taskInProgress=1		
	end
		
	if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
	or @taskInProgress=1
	begin
		set @addTaskSteps =1;
		--Add tasks when called for  invalid records-
		exec absp_AddTaskSteps  @taskKey,1,'Waiting','Create temporary views for lookup tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,2,'Waiting','Create filtered exposure tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,3,'Waiting','Create schema to store intermediate tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,4,'Waiting','Create intermediate tables to hold Account Names and Numbers' ,'',1	
		exec absp_AddTaskSteps  @taskKey,5,'Waiting','Create intermediate tables to hold Policy Names and Numbers' ,'',1	
		exec absp_AddTaskSteps  @taskKey,6,'Waiting','Create intermediate tables to hold Site Names and Numbers' ,'',1	
		exec absp_AddTaskSteps  @taskKey,7,'Waiting','Create intermediate tables to hold Structure Names and Numbers' ,'',1	
		exec absp_AddTaskSteps  @taskKey,8,'Waiting','Generate data for FilteredAccount table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,9,'Waiting','Generate data for FilteredPolicy table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,10,'Waiting','Generate data for FilteredPolicyFilter table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,11,'Waiting','Generate data for FilteredPolicyCondition table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,12,'Waiting','Generate data for FilteredAccountReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,13,'Waiting','Generate data for FilteredPolicyReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,14,'Waiting','Generate data for FilteredSiteReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,15,'Waiting','Generate data for FilteredSiteCondition table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,16,'Waiting','Generate data for FilteredStructureCondition table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,17,'Waiting','Generate data for FilteredStructure table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,18,'Waiting','Generate data for FilteredStructureCoverage table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,19,'Waiting','Generate data for FilteredStructureFeature table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,20,'Waiting','Drop temporary schema' ,'',1	
		exec absp_AddTaskSteps  @taskKey,21,'Waiting','Generate filtered statistics report' ,'',1
		exec absp_AddTaskSteps  @taskKey,22,'Waiting','Create indexes on filtered exposure tables' ,'',1
		set @stepNumber=21
	end
	else if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType)
	begin
		set @addTaskSteps =1;
		--Add tasks when called for filter/sort--
		exec absp_AddTaskSteps  @taskKey,1,'Waiting','Create temporary views for lookup tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,2,'Waiting','Create filtered exposure tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,3,'Waiting','Create schema to store intermediate tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,4,'Waiting','Retrieve filter and sort information' ,'',1	
		exec absp_AddTaskSteps  @taskKey,5,'Waiting','Determine initial list of keys for all exposure tables' ,'',1
		exec absp_AddTaskSteps  @taskKey,6,'Waiting','Determine final list of Account, Policy, Site and Structure keys' ,'',1		
		exec absp_AddTaskSteps  @taskKey,7,'Waiting','Generate PolicyCondition keys based on the associated Structures' ,'',1	
		exec absp_AddTaskSteps  @taskKey,8,'Waiting','Generate PolicyCondition keys not associated with the Structures' ,'',1	
		exec absp_AddTaskSteps  @taskKey,9,'Waiting','Get final Policy key list based on PolicyCondition keys' ,'',1	
		exec absp_AddTaskSteps  @taskKey,10,'Waiting','Determine the final list of keys for all other exposure related tables' ,'',1	
		exec absp_AddTaskSteps  @taskKey,11,'Waiting','Get Names and Numbers for Accounts, Policies, Sites and Structures' ,'',1	
		exec absp_AddTaskSteps  @taskKey,12,'Waiting','Generate data for FilteredAccount table' ,'',1
		exec absp_AddTaskSteps  @taskKey,13,'Waiting','Generate data for FilteredPolicy table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,14,'Waiting','Generate data for FilteredPolicyFilter table' ,'',1
		exec absp_AddTaskSteps  @taskKey,15,'Waiting','Generate data for FilteredPolicyCondition table' ,'',1
		exec absp_AddTaskSteps  @taskKey,16,'Waiting','Generate data for FilteredAccountReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,17,'Waiting','Generate data for FilteredPolicyReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,18,'Waiting','Generate data for FilteredSiteReinsurance table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,19,'Waiting','Generate data for FilteredSiteCondition table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,20,'Waiting','Generate data for FilteredStructureCondition table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,21,'Waiting','Generate data for FilteredStructure table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,22,'Waiting','Generate data for FilteredStructureCoverage table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,23,'Waiting','Generate data for FilteredStructureFeature table' ,'',1	
		exec absp_AddTaskSteps  @taskKey,24,'Waiting','Drop temporary schema' ,'',1	
		exec absp_AddTaskSteps  @taskKey,25,'Waiting','Generate filtered statistics report' ,'',1
		exec absp_AddTaskSteps  @taskKey,26,'Waiting','Create indexes on filtered exposure tables' ,'',1
		set @stepNumber=25
	end;
			
	-- wait until the task is ready
	exec absp_TaskExecutionTimer @taskKey, 0
	
	if @debug = 1 
	begin
		if OBJECT_ID('tempdb..##TMP_TASKTIME','u') is null
		create table ##TMP_TASKTIME (ID int identity not null,TaskKey int, NodeKey int, NodeType int, TaskStatus char(1), elapseTime varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS)
		-- mark the start time
		execute absp_Util_ElapsedTime @endMsg output, @startTime output;
	end
	
	--create temporary table for lookups to handle order by on lookup displayname columns--
	if @addTaskSteps =1
	begin
		exec absp_AddTaskSteps  @taskKey,1,'Running','' ,'Create temporary table for lookups to handle order by on lookup display name columns.',0	
		exec absp_Util_AddTaskProgress @taskKey, 'Create temporary table for lookups to handle order by on lookup display name columns.', @procID;
	end
	select * into #Country from Country where 1=0
	select * into #CIL from CIL where 1=0
	select * into #ESDL from ESDL  where 1=0
	select * into #EOTDL from EOTDL where 1=0
	select * into #FSDL from FSDL where 1=0 
	select * into #FOTDL from FOTDL where 1=0
	select * into #WSDL from WSDL  where 1=0
	select * into #WOTDL from WOTDL where 1=0
	select * into #PTL from PTL where 1=0
	select * into #LineofBusiness from LineofBusiness --where 1=0
	select PolicyConditionNameKey,ConditionName into #PolicyConditionName from PolicyConditionName where 1=0
	select * into #TreatyTag from TreatyTag --where 1=0
	select * into #Reinsurer from Reinsurer --where 1=0
	select * into #PolicyStatus from PolicyStatus --where 1=0
	select * into #ConditionType from ConditionType where 1=0
	select * into #StepInfo from StepInfo where 1=0
	
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,1,'Completed','' ,'',0	
	---------
	
	--Create filtered Exposureset tables--
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,2,'Running','' ,'',0	
	exec absp_Util_AddTaskProgress @taskKey, 'Create filtered exposure tables.', @procID;
	exec absp_CreateFilteredExposuresetTables @nodeKey,@nodeType ,@userKey,0
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,2,'Completed','' ,'',0	
	----------

	--Procedure bifurcates based on import/task--
	if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
	begin
		exec absp_PopulateFilterTables @nodeKey,@nodeType,@taskKey,@userKey,@debug
	end
	else if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType)
	begin
		exec absp_PopulateFilterTablesWithFilteredData @nodeKey,@nodeType,@taskKey, @userKey,@debug
	end
	else
	begin
		exec absp_PopulateFilterTables @nodeKey,@nodeType,@taskKey,@userKey,@debug
	end
	--------------------
	
	--Populate FilterStats==
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'Populating FilteredStatReport with filtered statistics.',0	
	exec absp_Util_AddTaskProgress @taskKey, 'Populating FilteredStatReport with filtered statistics.', @procID;

	delete from FilteredStatReport where NodeKey=@nodeKey and NodeType=@nodeType;
	
	exec absp_PopulateFilterStats 'Accounts','Account','Account', @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Policies', 'Policy','Policy',@nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Structures','Structure','Structure', @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Structure Coverages','StructureCoverage','StructureCoverage', @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Structure Features','StructureFeature','StructureFeature', @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Policy Conditions','PolicyCondition','PolicyCondition',  @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Policy Filter', 'PolicyFilter','PolicyFilter',@nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Site Conditions', 'SiteCondition','SiteCondition',@nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Structure Conditions', 'SiteCondition','StructureCondition' ,@nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Account Reinsurance','Reinsurance','AccountReinsurance', @nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Policy Reinsurance', 'Reinsurance','PolicyReinsurance',@nodeKey, @nodeType,@userKey
	exec absp_PopulateFilterStats 'Site Reinsurance','Reinsurance','SiteReinsurance', @nodeKey, @nodeType,@userKey
	
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0
	------------------
	
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Update FilteredStatReport'
	end
	
	--Create Indexes on Filtered tables--
	set @stepNumber =@stepNumber +1
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	exec absp_Util_AddTaskProgress @taskKey, 'Create Indexes on Filtered Exposure tables.', @procID;
	exec absp_CreateFilteredExposuresetTables @nodeKey,@nodeType ,@userKey,1
	if @addTaskSteps =1 exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	------------------------------------

	if @debug = 1
	begin
		-- mark the finish time
		execute absp_Util_ElapsedTime @endMsg output, @startTime output;
		insert into ##TMP_TASKTIME values(@taskKey, @NodeKey, @nodeType, 'S', @endMsg)
	end
	
	return 0 --success
end try	
begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
--	set @taskProgressMsg = 'Applying Exposure browser filter and sort process was cancelled.';
--	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	-- Log it and raise error
	exec absp_Util_GetErrorInfo @ProcName
end catch

