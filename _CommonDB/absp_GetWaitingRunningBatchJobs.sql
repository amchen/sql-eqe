if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetWaitingRunningBatchJobs') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetWaitingRunningBatchJobs
end
go

create procedure absp_GetWaitingRunningBatchJobs as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       The procedure returns a list of waiting and running jobs.
	       The following jobs are to be returned:-
	 	 Jobs with staus 'W' or 'R' having no entry in TaskInfo
	 	 Jobs whose parents are not running/waiting
	 	 Jobs whose parent critical jobs have failed

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

*/
begin
	set nocount on

   	declare @batchJobKey int
   	declare @criticalJob char(1)
   	declare @insertFlag int
   	declare @status varchar(20)
   	declare @dependencyKeyList varchar(1000)
   	declare @sql varchar(max)
	declare @serverStarted varchar(20)
	declare @Priority char(20);
	declare @jobsPerResourceGroup int;
	declare @resourceGroupCount int;
	declare @totalJobCount int;
	declare @preemptiveJobKey int;
	declare @jobTypeID int;
	declare @parallelism int;
	declare @priorityOrder int;
	declare @debug int;
	
	set @debug = 0;
	set @totalJobCount = 0;

   	declare @JobToExclude table (BatchJobKey int)

	--Return if App_Server_Started is initialized to false
	set @serverStarted=''
	select  @serverStarted = bk_value  from bkprop where bk_key = 'App_Server_Started';
	if @serverStarted='' or @serverStarted='false'
	begin
		-- Return Dummy result to satify hibernate
		select * from commondb..BatchJob where 1 = 2;
		return;
	end
	
	--Create temp table
	create table #AttachedDatabases (DBName varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #DBToInclude (DBRefKey int);
	create table #RunningJobsTbl (BatchJobKey int);
	create table #Priority ( PriorityOrder int, priority char(20));
	create table #IgnorePreemptionJobs (BatchJobKey int, PriorityOrder int);
	create table #ExcludeJobsTbl (BatchJobKey int);	
	
	-- Add the entries in #Priority table for all the supported Priorities.
	insert into #Priority select 1, 'High';
	insert into #Priority select 2, 'AboveNormal';
	insert into #Priority select 3, 'Normal';
	insert into #Priority select 4, 'BelowNormal';
	insert into #Priority select 5, 'Low';
	
	
	-- First get the list of database names in BatchJob and then check if the databases are attached or not.
	set @sql = 'insert into #AttachedDatabases SELECT distinct name  FROM sys.databases
					inner join commondb..BatchJob BatchJob on sys.databases.name COLLATE DATABASE_DEFAULT = BatchJob.dbName COLLATE DATABASE_DEFAULT
					where state_desc = ''Online'' and BatchJob.IsHPC=''N''';
	
	if (@debug = 1) print @sql;
	execute (@sql);
	if (@debug = 1) select * from #AttachedDatabases;
	
	-- Now get the list of Databases whose job can be processed. If the database is not attached or offline or it has
	-- MIGRATION_NEEDED or MIGRATION_IN_PROGRESS Attrib set then we will not process jobs (other than Migration jobs) 
	-- associated with those databases.
	
	insert into #DBToInclude select t1.DBRefKey from commondb..BatchJob t1 
					inner join #AttachedDatabases t2 on t1.DBName COLLATE DATABASE_DEFAULT = t2.DBName COLLATE DATABASE_DEFAULT 
					inner join CFLDRINFO t3 on t1.DBRefKey = t3.CF_REF_KEY and t3.Attrib = 32
					and t1.IsHPC='N';
        
	--Get batchJobKey for all the taskInfo rows--
	insert into @JobToExclude
		select BatchJobKey  from commondb..BatchJob A 
			inner join TaskInfo B
   			on A.FolderKey=B.FolderKey and A.AportKey=B.AportKey
			and A.PportKey=B.PportKey and A.ExposureKey=B.ExposureKey
			and A.AccountKey=B.AccountKey and A.PolicyKey=B.PolicyKey
			and A.SiteKey=B.SiteKey and A.RportKey=B.RportKey
			and A.ProgramKey=B.ProgramKey and A.CaseKey=B.CaseKey
			and A.nodeType=B.NodeType
			and A.DbRefKey=B.DbRefKey
			and B.status='RUNNING'
			inner join #DBToInclude C on A.DBRefKey = C.DBRefKey;
	
	-- Check if there is any preemptive jobs. If we have preemptive jobs then only the jobs that has 
	-- higher priority than the preemptive job and the preemptive job will run.
	if (@debug = 1) print '2';
	
	-- First check if the preemptive jobs are dependent jobs or not. If the preemptive job is dependent
	-- then we need to check if the job it's dependent on are already completed or not. If the 
	-- job it's dependent is not success then we will ignore the preemtive job 
	
	declare cursPreemptiveJobs  cursor fast_forward  for
		select t1.BatchJobKey, case when DependencyKeyList='0' then '' else DependencyKeyList end as DependencyKeyList, t3.PriorityOrder  from commondb..BatchJobSettings t1 
		inner join commondb..BatchJob t2 on t1.BatchJobKey = t2.BatchJobKey 
		inner join #Priority t3 on t3.priority COLLATE DATABASE_DEFAULT = t1.priority COLLATE DATABASE_DEFAULT  
		where IsPreemptive = 'Y' and t2.Status in ('R', 'W', 'WL') and t2.IsHPC='N';
	open cursPreemptiveJobs
	fetch next from cursPreemptiveJobs into @preemptiveJobKey, @dependencyKeyList, @priorityOrder
	while @@fetch_status = 0
   	begin
   		if (LEN(@dependencyKeyList) > 0)
   		begin
			set @sql = ' insert into #IgnorePreemptionJobs select distinct ' + dbo.trim(cast(@preemptiveJobKey as varchar)) + ',' + dbo.trim(cast(@priorityOrder as varchar)) +
					' from commondb..BatchJobSettings BatchJobSettings CROSS APPLY (SELECT count(*) as StatusCount FROM commondb..batchjob t3 where batchjobkey in (' + dbo.trim(cast(@dependencyKeyList as varchar (1000))) + ') and Status <> ''S'') as t1 ' +
					' where t1.StatusCount = 0 and  IsHPC =''N'' and BatchJobSettings.BatchJobKey = ' + dbo.trim(cast(@preemptiveJobKey as varchar)) ;
			if (@debug > 0) print @sql;		
			exec (@sql);
		end
		else
		begin
			set @sql = ' insert into #IgnorePreemptionJobs select distinct ' + dbo.trim(cast(@preemptiveJobKey as varchar)) + ',' + dbo.trim(cast(@priorityOrder as varchar));
			exec (@sql);
		end
	fetch next from cursPreemptiveJobs into @preemptiveJobKey, @dependencyKeyList, @priorityOrder
   	end
	close cursPreemptiveJobs;
	deallocate cursPreemptiveJobs;
	
	-- We may have more than one preemptive job but we need to only acknowledge the job that is in the highest priority queue and then by job order
	-- remove all other preemptive job from the list. At any given instance we can run 1 preemptive job.
	
	delete t1 from 
	(
	  SELECT BatchJobKey, rn=ROW_NUMBER() OVER 
	   (order by priorityorder, BatchJobKey) 
	   FROM #IgnorePreemptionJobs
	)t1
	
	where t1.rn > 1
	
	if (@debug > 0) select * from #IgnorePreemptionJobs;
	
	set @dependencyKeyList = '';
	
	-- Now determine the jobs that can be preemptive (since we removed all the dependency issues)
	-- Here we are trying to find the jobs that are not preemptive and has a batchjobkey > than the preemptive job 
	-- or if the job is in priority queue which is same or lower than than the priority queue the preemptive job 
	-- for example, if we have a preemptive job in Normal queue then any job which is in the same or lower queue will get ignored.
	-- if there is a job in the high priority queue then that job will still run along side the preemptive job.
	
	-- We first need to ignore jobs that are in lower order than the premeptive job but within the same priority
	if exists (select 1 from #IgnorePreemptionJobs) 
	begin
		insert into @JobToExclude
			select t1.BatchJobKey from commondb..BatchJob t1
			CROSS APPLY
			(SELECT top 1 t2.batchJobKey as BJ, t2.Priority, t3.PriorityOrder 
				from commondb..BatchJobSettings t2
				inner join commondb..batchjob bj on bj.batchjobkey = t2.batchjobkey and bj.Status in ('R', 'W', 'WL')
				inner join #Priority t3 on t2.Priority COLLATE DATABASE_DEFAULT  = t3.Priority COLLATE DATABASE_DEFAULT 
				where t2.BatchJobKey not in (select BatchJobKey from #IgnorePreemptionJobs)
				
				and t2.IsPreemptive = 'Y'
				order by t3.PriorityOrder, t2.BatchJobKey
			) t4
			CROSS APPLY
			(select PriorityOrder from #Priority inner join commondb..BatchJobSettings BatchJobSettings on #Priority.priority COLLATE DATABASE_DEFAULT = BatchJobSettings.priority COLLATE DATABASE_DEFAULT  and BatchJobSettings.BatchJobKey = t1.BatchJobKey) t6
		where t1.BatchJobKey <> t4.BJ and t4.PriorityOrder = t6.PriorityOrder and t1.Status in ('R', 'W', 'WL');
		
		-- Now ignore jobs that are in a lower priority queue
		
		insert into @JobToExclude
			select t1.BatchJobKey from commondb..BatchJob t1
			CROSS APPLY
			(SELECT top 1 t2.batchJobKey as BJ, t2.Priority, t3.PriorityOrder 
				from BatchJobSettings t2
				inner join commondb..batchjob bj on bj.batchjobkey = t2.batchjobkey and bj.Status in ('R', 'W', 'WL')
				inner join #Priority t3 on t2.Priority COLLATE DATABASE_DEFAULT  = t3.Priority COLLATE DATABASE_DEFAULT 
				where t2.BatchJobKey in (select BatchJobKey from #IgnorePreemptionJobs)
				order by t3.PriorityOrder, t2.BatchJobKey
			) t4
			CROSS APPLY
			(select PriorityOrder from #Priority 
				inner join commondb..BatchJobSettings BatchJobSettings on #Priority.priority COLLATE DATABASE_DEFAULT = BatchJobSettings.priority COLLATE DATABASE_DEFAULT  
				and BatchJobSettings.BatchJobKey = t1.BatchJobKey
			) t6
		where t1.BatchJobKey <> t4.BJ and t4.PriorityOrder < t6.PriorityOrder and t1.Status in ('R', 'W', 'WL');
	end
	
	--Get all Batch jobs with Wating/Running status which do not exist in TaskInfo
   	--Here we are only checking for BatchJobs that has dependency.
   	--Later we will add all the independent jobs (i.e. DependencyKeyList = 0)

   	declare cursBatchJob  cursor fast_forward  for
   	        select BatchJobKey, DependencyKeyList  from commondb..BatchJob
   	          where BatchJobKey not in (select BatchJobKey from @JobToExclude) and STATUS in ('W','R','WL') and DependencyKeyList <> '0' and BatchJob.IsHPC='N'

   	open cursBatchJob
   	fetch next from cursBatchJob into @batchJobKey,@dependencyKeyList
   	while @@fetch_status = 0
   	begin
   		--Check job status for parent jobs--
   		set @sql='select Status,CriticalJob from commondb..BatchJob where BatchJobKey in (' + dbo.trim(cast(@dependencyKeyList as varchar (1000))) + ') order by JobOrder'
   		execute('declare cursParentJob cursor forward_only global  for '+@sql)
   		open cursParentJob
   		set @insertFlag=1
   		fetch next from cursParentJob into @status,@criticalJob
   		while @@fetch_status = 0
   		begin
   			if @criticalJob='Y' and  @status<>'S'
			begin
   				--Exclude BatchJob--No need to check other parents
   				set @insertFlag=0
   				break
   			end
   			else if @criticalJob='N'
   			begin
   				if @status<>'S' and @status <> 'C' and @status <> 'F'  and @status <> 'CP' and @status <> 'CR'
   				begin
   					--Exclude BatchJob--No need to check other parents
   					set @insertFlag=0
   					break
   				end
   			end

			fetch next from cursParentJob into @status,@criticalJob
		end
		close cursParentJob
		deallocate cursParentJob

		if @insertFlag=1
			insert into #RunningJobsTbl values(@batchJobKey)

      	fetch next from cursBatchJob into @batchJobKey,@dependencyKeyList
   	end
	close cursBatchJob
	deallocate cursBatchJob

	if (@debug = 1) print '3';
	-- Now add all the indepedent jobs
	insert into #RunningJobsTbl
		select BatchJob.BatchJobKey from commondb..BatchJob BatchJob
		where  BatchJob.DependencyKeyList = '0' and Status in ('W', 'R', 'WL')  and BatchJob.IsHPC='N'
		and Not BatchJobKey in (select BatchJobKey from @JobToExclude)
	if (@debug = 1) print '4';

	-- Now add any migration job
	insert into #RunningJobsTbl
		select BatchJob.BatchJobKey from commondb..BatchJob BatchJob
		where  BatchJob.JobTypeID = 28 and Status in ('W', 'R', 'WL') and BatchJob.IsHPC='N'
	if (@debug = 1) print '5';

	-- Now check to see if any running jobs has a job setting for maximum cores to use.
	-- If the job is already using the specified number of cores then exclude the job from the list.
		
	select t1.BatchJobKey into #JobsWithAllCoresInUse from commondb..BatchJob t1
		inner join commondb..BatchJobSettings t5 on t1.BatchJobKey = t5.BatchJobKey and t5.MaxCoresToUse != 0 and t1.IsHPC='N'
		CROSS APPLY
		(SELECT bjs.batchjobkey as batchjobkey, count(*) as rs FROM commondb..batchjobstep bjs WHERE  bjs.status = 'R' group by bjs.batchjobkey) as t2
		where t5.MaxCoresToUse <= t2.rs and t2.batchjobkey = t5.BatchJobKey;
		
		
	if (@debug = 1) print '6';
	
	-- Now remove the batch jobs which are already using all the cores 
	delete from #RunningJobsTbl where BatchJobKey in (select BatchJobKey from #JobsWithAllCoresInUse);
	if (@debug = 1) print '7';
	
	-- Now check how many resource groups are in use. If there is no resource group in use then we will select top 10 jobs 
	-- for each priority. If the jobs are associated with Resource Groups then for each resource group we will select 5 jobs
	-- So if we have 5 Resource Groups then for each priority we will select 25 jobs.
	
	select @totaljobCount = count(*) from #RunningJobsTbl;
	
	if (@debug = 1) select * from commondb..BatchJobSettings t1 inner join #RunningJobsTbl t2 on t1.Batchjobkey = t2.batchjobkey;
	

	-- If we only have a small number of jobs then no need to get selected jobs for each resource group. 
	-- The following step is performed to reduce the number of jobs so absp_GetExcludeRunningJobList does not take a long time.
	if (@debug = 1) select * from #RunningJobsTbl;
	if (@totalJobCount > 50)
	begin

		select @resourceGroupCount = count(distinct resourcegroupkey) from commondb..batchjobsettings;

		if (@resourceGroupCount > 3)
			set @jobsPerResourceGroup = 10;
		else
			set @jobsPerResourceGroup = 20;
	
		-- Create a new temp table to capture all the columns we need for sorting
		select t1.BatchJobKey, ResourceGroupKey, case when IsPreemptive = 'Y' then 1 else 2 end PreemtiveOrder, priorityorder 
			into #TMP from commondb..BatchJobSettings t1 
			inner join #Priority t2 on t2.priority COLLATE DATABASE_DEFAULT = t1.priority COLLATE DATABASE_DEFAULT

		select priorityorder, ResourceGroupKey, BatchJobkey into #JobList
		from (
			select t1.*, row_number() over(partition  by ResourceGroupKey order by t1.priorityorder, PreemtiveOrder, t1.BatchJobKey) rn
			from #TMP t1 inner join #RunningJobsTbl t2 on t1.BatchJobKey = t2.BatchJobKey
		) s
		where rn <= @jobsPerResourceGroup
		order by priorityorder, ResourceGroupKey, BatchJobkey

		-- Now remove all other jobs from #RunningJobsTbl table
			
		delete from #RunningJobsTbl where BatchJobKey not in (select BatchJobKey from #JobList);
	end
	
	
	 
	 
	--Now find out all the analysis jobs that cannot be run because they have paste-linked children.
	insert #ExcludeJobsTbl exec absp_GetExcludeRunningJobList;
	if (@debug = 1) select * from #ExcludeJobsTbl;
	if (@debug = 1) print '8';
	
	-- Now find out all the jobs that has some parallelism constraint
	select t1.BatchJobKey, t1.JobTypeID, Parallelism, PriorityOrder into #TMP_PARALLELISM_CHECK from commondb..BatchJob t1 
		inner join commondb..batchjobsettings t2 on t1.BatchJobKey = t2.BatchJobKey 
		inner join #Priority t3 on t3.priority COLLATE DATABASE_DEFAULT = t2.priority COLLATE DATABASE_DEFAULT
		inner join JobDef t4 on t4.JobTypeID = t1.JobTypeID
		where t1.status in ('R','W') and t1.IsHPC='N';
		
	if (@debug = 1) select * from #TMP_PARALLELISM_CHECK;
	
	declare cursJobType  cursor fast_forward  for
	   	        select JobTypeID, Parallelism from JobDef where Parallelism > 0;
   	          
	open cursJobType
	   	fetch next from cursJobType into @jobTypeID, @parallelism
	   	while @@fetch_status = 0
   	begin
   		
   		insert into #ExcludeJobsTbl
   		select BatchJobKey
		from
		(
		    select tt1.BatchJobKey, row_number() over (order by tt1.PriorityOrder, tt1.BatchJobKey ) RowNumber 
		    from #TMP_PARALLELISM_CHECK tt1 where tt1.JobTypeID = @jobTypeID
		) tt
		where RowNumber > @parallelism;
		
   	fetch next from cursJobType into @jobTypeID, @parallelism	
   	end
   	close cursJobType;
	deallocate cursJobType;
	
	if (@debug = 1) select * from #ExcludeJobsTbl;
	
	-- Now return 5 resultset one for each priority
	-- With in each priority we will first have the preemptive jobs then running jobs followed by waiting jobs.
	declare cursPriority  cursor fast_forward  for
   	        select Priority  from #Priority
   	          order by PriorityOrder;

   	open cursPriority
   	fetch next from cursPriority into @Priority
   	while @@fetch_status = 0
   	begin
		if (@debug = 1) print '9';
		
		-- first add all the preemtive jobs order by job key
		
		select t1.* , Priority, MaxCoresToUse, ResourceGroupKey, IsPreemptive, JobTypeName into #BatchJobListByPriority_PJ from commondb..BatchJob t1
					inner join commondb..BatchJobSettings t2 on t1.BatchJobKey = t2.BatchJobKey and t2.Priority = @Priority
					inner join JobDef t3 on t3.JobTypeID = t1.JobTypeID
					where t1.BatchJobKey in (select pj.BatchJobKey from #IgnorePreemptionJobs pj) 
					and t1.BatchJobKey not in (select distinct ej.BatchJobKey from #ExcludeJobsTbl ej)
					and t1.Status in ('R', 'W', 'WL') and t1.IsHPC='N'
					order by t1.BatchJobKey;
		
		-- Now add all the running jobs	order by job key		
		select t1.* , Priority, MaxCoresToUse, ResourceGroupKey, IsPreemptive, JobTypeName  into #BatchJobListByPriority_RJ from commondb..BatchJob t1
					inner join commondb..BatchJobSettings t2 on t1.BatchJobKey = t2.BatchJobKey and t2.Priority = @Priority
					inner join JobDef t3 on t3.JobTypeID = t1.JobTypeID
					where t1.BatchJobKey in (select rj.BatchJobKey from #RunningJobsTbl rj) 
					and t1.BatchJobKey not in (select distinct ej.BatchJobKey from #ExcludeJobsTbl ej)
					and t1.BatchJobKey not in (select pj.BatchJobKey from #IgnorePreemptionJobs pj)
					and t1.Status = 'R' and t1.IsHPC='N'
					order by t1.BatchJobKey;
		
		-- finally add all the waiting jobs order by job key
		select t1.* , Priority, MaxCoresToUse, ResourceGroupKey, IsPreemptive, JobTypeName into #BatchJobListByPriority_WJ from commondb..BatchJob t1
					inner join commondb..BatchJobSettings t2 on t1.BatchJobKey = t2.BatchJobKey and t2.Priority = @Priority
					inner join JobDef t3 on t3.JobTypeID = t1.JobTypeID
					where t1.BatchJobKey in (select rj.BatchJobKey from #RunningJobsTbl rj) 
					and t1.BatchJobKey not in (select distinct ej.BatchJobKey from #ExcludeJobsTbl ej)
					and t1.BatchJobKey not in (select pj.BatchJobKey from #IgnorePreemptionJobs pj)
					and t1.Status in ('W', 'WL') and t1.IsHPC='N'
					order by t1.BatchJobKey;								
		
		select t3.* into #BatchJobListByPriority from 
			(
				select * from #BatchJobListByPriority_PJ
				union all
				select * from #BatchJobListByPriority_RJ
				union all
				select * from #BatchJobListByPriority_WJ
			)t3;
		
			
		if (@debug = 1) print '10';	
		select * from #BatchJobListByPriority t1;
		drop table #BatchJobListByPriority;
		drop table #BatchJobListByPriority_PJ;
		drop table #BatchJobListByPriority_RJ;
		drop table #BatchJobListByPriority_WJ;
		
	fetch next from cursPriority into  @Priority	
	end
	close cursPriority;
	deallocate cursPriority;
	
 end