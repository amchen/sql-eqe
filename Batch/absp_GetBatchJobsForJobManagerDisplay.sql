if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetBatchJobsForJobManagerDisplay') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetBatchJobsForJobManagerDisplay
end
go

create procedure absp_GetBatchJobsForJobManagerDisplay  @basicWhereClause varchar(1000), 
							@batchJobGridWhereClause varchar (2000),
							@batchJobGridOrderByClause varchar (2000),
							@pageSizeBJ int,
							@pageIndexBJ int,
							@selectedBatchJobKey int = 0,
							@returnJobStepDetails int = 0,
							@batchJobStepGridWhereClause varchar (2000)='',
							@batchJobStepGridOrderByClause varchar (2000)='',
							@pageSizeBJS int = 1000,
							@pageIndexBJS int = 1
							
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure will be called to refresh the Job Manager dialog view.

Returns:	ResultSet 
		This will return 5 resultsets
		ResultSet 1 - This will return the total count of BatchJobs (in queue) and Tasks.
		ResultSet 2 - Pagination information for the batch job grid
		ResultSet 3 - Batch Job Information 
		ResultSet 4 - Pagination information for the batch job step grid
		ResultSet 5 - Batch Job Step Information 

====================================================================================================
</pre>
</font>
##BD_END

*/
begin
	set nocount on
	declare @sql varchar(max);
	declare @sql1 nvarchar(max);
   	declare @batchJobKey int;
	declare @bj_StartRowNumber int;
	declare @bj_EndRowNumber int;
	declare @bjs_StartRowNumber int;
	declare @bjs_EndRowNumber int;
	declare @cnt int;
	declare @currentSelectedRowNumber int;
	declare @batchJobStepColList varchar(max);
	declare @preemptiveJobKey int;
	declare @priority char(20);
	declare @hasJobs int;
	declare @postProcessorWhereClause varchar(100);
	declare @onlyPlanJobStep int;
	declare @debug int;
	
	set @debug = 0;
	set @currentSelectedRowNumber = 0;
	set @preemptiveJobKey = 0;
	set @priority = '';
	set @postProcessorWhereClause = '';
	set @onlyPlanJobStep = 0;
	
	set @basicWhereClause = replace (@basicWhereClause, '''CP''', '''CP'', ''CR''');
   	create table #PortStatus (
   		BatchJobKey int,
   		DemandSurge varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
   		Frequency varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
   		EventType varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS,
   		NodeDisplayName varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS,
   		Status varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS
   	);

	--Create temp table
	create table #Priority ( PriorityOrder int, priority char(20));
	-- Add the entries in #Priority table for all the supported Priorities.
	insert into #Priority select 1, 'High';
	insert into #Priority select 2, 'AboveNormal';
	insert into #Priority select 3, 'Normal';
	insert into #Priority select 4, 'BelowNormal';
	insert into #Priority select 5, 'Low';
	
	create table #AttachedDatabases (DBName varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #BatchJobsToBeDisplayed (BatchJobKey int, DatabaseName varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #BatchJobDisplay ( BatchJobKey int, UserName char(25), DatabaseName char(120), NodeDisplayName varchar(1000), JobType char(120), Status char(50), 
					SubmittedAt char(14), StartedAt char(14), FinishedAt char(14), CriticalJob char(1), DependencyKeyList char(1000), 
					DemandSurge varchar(10), Frequency varchar(10), EventType varchar(254), 
					Priority char(20), MaxCoreToUse int, IsPreemptive char(1), ResourceGroupKey int,
					TotalJobSteps int, FinishedJobSteps int, RunningJobSteps int, isHPC varchar(1));
					
	
	select * into #FinalBatchJobDisplay from #BatchJobDisplay;
	
	alter table #FinalBatchJobDisplay add RowNumber int IDENTITY;
	
	select * into #TMP_BJS from  commondb..BatchJobStep where 1=2;
	alter table #TMP_BJS add RowNumber int;
	
	-- When user selects "All Jobs" then the basic where clause will be empty. Set 1=1 to statify the queries.
	if (len(ltrim(rtrim(@basicWhereClause))) = 0)
		set @basicWhereClause = ' 1=1 ';	
	
	if (len(ltrim(rtrim(@batchJobGridOrderByClause))) = 0)
		set @batchJobGridOrderByClause = ' batchjobkey ';
					
	
	-- First get the list of database names in BatchJob and then check if the databases are attached or not.
	set @sql = 'insert into #AttachedDatabases SELECT distinct name  FROM sys.sysdatabases
					inner join commondb..BatchJob BatchJob on sys.sysdatabases.name COLLATE DATABASE_DEFAULT = BatchJob.dbName COLLATE DATABASE_DEFAULT
					where 1=1 and ' + @basicWhereClause +
					' and version is not NULL ';
	
	if (@debug = 1) print @sql;
	execute (@sql);

	--select * from #AttachedDatabases
	-- Get the list of JobKeys that can be displayed i.e. the jobs are not associated with the detached databases
	set @sql = ' insert into #BatchJobsToBeDisplayed select distinct BatchJob.BatchJobKey, BatchJob.dbName  from commondb..BatchJob
					inner join #AttachedDatabases on BatchJob.DBName = #AttachedDatabases.DBName
					where 1=1 and JobTypeID <> 28 and ' + @basicWhereClause;

	if (@debug = 1) print @sql;
	execute (@sql);

	if (@debug = 1) select * from #BatchJobsToBeDisplayed
	-- Now check if any of the jobs are associated with a portfolio that is already detached.
	
	insert into #PortStatus exec absp_GetPortfolioStatusForAllBatchJobs
	
	-- Now insert the entries for Migration Job. 
	insert into #PortStatus select distinct BatchJobKey , '', '' , '' , '' , 'Active'  from commondb..BatchJob where JobTypeID = 28;
	
	if (@debug = 1)  print 'inserted into #PortStatus';
	--select * from #PortStatus
	-- Now get the list of jobs to be displayed and save it in #BatchJobDisplay
	
	set @sql = 'insert into #BatchJobDisplay 
			select distinct BatchJob.BatchJobKey, UserInfo.USER_NAME, BatchJob.DBName, isNull (NodeDisplayName, ''''),
				JobDef.JobTypeName, BatchJob.Status,
				BatchJob.SubmitDate, BatchJob.StartDate, BatchJob.FinishDate, BatchJob.CriticalJob,BatchJob.DependencyKeyList,
				DemandSurge, Frequency, EventType, BatchJobSettings.Priority, BatchJobSettings.MaxCoresToUse, BatchJobSettings.IsPreemptive, BatchJobSettings.ResourceGroupKey,
				0,0,0, BatchJob.isHPC
				from commondb..BatchJob BatchJob with(nolock)
				inner join #PortStatus on BatchJob.BatchJobKey = #PortStatus.BatchJobKey and #PortStatus.Status in (''Active'')
				inner join commondb..BatchJobSettings BatchJobSettings on BatchJobSettings.BatchJobKey = BatchJob.BatchJobKey
				inner join commondb..UserInfo  UserInfo on UserInfo.User_Key = BatchJob.UserKey
				inner join commondb..CFLDRINFO  CFLDRINFO on CFLDRINFO.DB_NAME = BatchJob.DbName
				inner join systemdb..JobDef JobDef on JobDef.JobTypeID = BatchJob.JobTypeID
				where 1=1 and BatchJob.JobTypeID not in (40,28) and ' + @basicWhereClause +
			' union
			
			select distinct BatchJob.BatchJobKey, UserInfo.USER_NAME, BatchJob.DBName, NodeDisplayName,
							JobDef.JobTypeName, BatchJob.Status,
							BatchJob.SubmitDate, BatchJob.StartDate, BatchJob.FinishDate, BatchJob.CriticalJob,BatchJob.DependencyKeyList,
							DemandSurge, Frequency, EventType, BatchJobSettings.Priority, BatchJobSettings.MaxCoresToUse, BatchJobSettings.IsPreemptive, BatchJobSettings.ResourceGroupKey,
							0,0,0, BatchJob.isHPC
							from commondb..BatchJob BatchJob with(nolock)
							inner join #PortStatus on BatchJob.BatchJobKey = #PortStatus.BatchJobKey and #PortStatus.Status in (''Active'')
							inner join commondb..BatchJobSettings BatchJobSettings on BatchJobSettings.BatchJobKey = BatchJob.BatchJobKey
							inner join commondb..UserInfo  UserInfo on UserInfo.User_Key = BatchJob.UserKey
							inner join systemdb..JobDef JobDef on JobDef.JobTypeID = BatchJob.JobTypeID
							where 1=1 and BatchJob.JobTypeID = 40 and ' + @basicWhereClause +
			
			' union
			
			select distinct BatchJob.BatchJobKey, UserInfo.USER_NAME, BatchJob.DBName, 
							CASE when BatchJob.JobTypeID = 28 then ''NA for Migration'' else NodeDisplayName end as NodeDisplayName,
							JobDef.JobTypeName, BatchJob.Status,
							BatchJob.SubmitDate, BatchJob.StartDate, BatchJob.FinishDate, BatchJob.CriticalJob,BatchJob.DependencyKeyList,
							DemandSurge, Frequency, EventType, BatchJobSettings.Priority, BatchJobSettings.MaxCoresToUse, BatchJobSettings.IsPreemptive, BatchJobSettings.ResourceGroupKey,
							0,0,0, BatchJob.isHPC
							from commondb..BatchJob BatchJob with(nolock)
							inner join #PortStatus on BatchJob.BatchJobKey = #PortStatus.BatchJobKey and #PortStatus.Status in (''Active'')
							inner join commondb..BatchJobSettings BatchJobSettings on BatchJobSettings.BatchJobKey = BatchJob.BatchJobKey
							inner join commondb..UserInfo UserInfo on UserInfo.User_Key = BatchJob.UserKey
							inner join systemdb..JobDef JobDef on JobDef.JobTypeID = BatchJob.JobTypeID
				where 1=1 and BatchJob.JobTypeID = 28 and ' + @basicWhereClause;
				
	if (@debug = 1)  print @sql;
	exec (@sql);
	
	update #BatchJobDisplay set
			RunningJobSteps = t2.rs,
			FinishedJobSteps = t3.fs,
			TotalJobSteps = t4.ts
			FROM #BatchJobDisplay t1
			CROSS APPLY
			(SELECT count(*) as rs FROM commondb..batchjobstep bjs WHERE bjs.batchjobkey=t1.batchjobkey and bjs.status = 'R') as t2
			CROSS APPLY
			(SELECT count(*) as fs FROM commondb..batchjobstep bjs WHERE bjs.batchjobkey=t1.batchjobkey and bjs.status = 'S') as t3
			CROSS APPLY
			(SELECT count(*) as ts FROM commondb..batchjobstep bjs WHERE bjs.batchjobkey=t1.batchjobkey) as t4
		
	-- Now move all the records into the final table that has the Row Number column and then select the page to be displayed.
	-- Here we will apply the where clause and order by clause that are associated with the top grid in the UI.
	
	if (len(ltrim(rtrim(@batchJobGridWhereClause))) > 0)
		set @batchJobGridWhereClause = ' and ' + @batchJobGridWhereClause;
		
	set @sql = 'insert into #FinalBatchJobDisplay select * from #BatchJobDisplay
			where 1=1 ' + @batchJobGridWhereClause +
			' order by ' + @batchJobGridOrderByClause;
	if (@debug = 1)  print (@sql);
	exec (@sql);
	
	-- Now we need to find the page where the selected job is located. Since the BatchJob table is dynamic the selected job may
	-- not be in the final display list anymore or it might have moved up the queue and not in the same page as before.
	-- We will get the row number where the selected batchjob key is and if it is missing we will return the 1 page otherwise
	-- we will determine the page where the batch job is located and return that page.
	
	select @currentSelectedRowNumber = RowNumber from #FinalBatchJobDisplay where BatchJobKey = @selectedBatchJobKey;
	if (@currentSelectedRowNumber = 0) 
	begin
		select @selectedBatchJobKey = BatchJobKey from #FinalBatchJobDisplay where RowNumber = 1;
		set @bj_StartRowNumber = 1;
		set @bj_EndRowNumber = 1 * @pageSizeBJ
	end
	else
	begin
		select @pageIndexBJ = CEILING (cast ((cast (@currentSelectedRowNumber as float)/cast (@pageSizeBJ as float)) AS FLOAT));
		set @bj_StartRowNumber = ((@pageIndexBJ - 1) * @pageIndexBJ) + 1;
		set @bj_EndRowNumber = @pageIndexBJ * @pageSizeBJ;
	end
	
	-- Now that we determined the selected batch job (which might be different from the one passed in based on the state of the batch 
	-- job queue) and the page to display we need to get the job step summary i.e. TotalJobSteps, FinishedJobSteps, RunningJobSteps 
	-- for the jobs in the page and update the #BatchJobDisplay
	
	-- Now return all the resultsets
	
	-- ResultSet 1
	select 'JobCount', count(*) as CNT from commondb..BatchJob where Status not in ('S', 'F', 'C', 'X', 'PS','D')
	union 
	select 'TaskCount', count(*) as CNT from commondb..TaskInfo where Status in ('Running')
	union
	select 'HasInvalidResourceGroup', CASE when count(*) > 1 then 1 else 0 end as CNT from commondb..ResourceGroupInfo where Status ='Invalid';
	
	-- ResultSet 2
	
	select @cnt = count(*) from #FinalBatchJobDisplay;
	select @pageIndexBJ as PageIndex, @selectedBatchJobKey as SelectedBatchJobKey, @cnt as TotalRows, @pageSizeBJ as PageSize ;
	
	-- Check if there are any preemptive jobs running. If there is a preemptive job running then all other jobs in the same queue and
	-- all jobs for lower priority queue should be marked as "Suspended".
	-- If there is no preemptive job but some of the running jobs has no job step running then mark the status as "Waiting for Resources" i.e. WR
	
	select @preemptiveJobKey = t1.BatchJobKey, @priority = t2.priority from commondb..BatchJob t1 inner join commondb..BatchJobSettings t2 on t1.BatchJobKey = t2.BatchJobKey
		where t1.Status = 'R' and t2.IsPreemptive = 'Y';
		
	if (@preemptiveJobKey > 0)
	begin
		
		-- First update the status for the job in the same queue
		update #FinalBatchJobDisplay set status = 'SS' 
			where priority = @priority and BatchJobKey > @preemptiveJobKey and Status in ('R', 'W', 'WL')
			and BatchJobKey in (select distinct batchjobkey from commondb..BatchJobStep where status in ('R', 'W') group by batchjobkey having count(*) >= 1)

		-- Now update the job status for the lower priority queue
		update #FinalBatchJobDisplay set status = 'SS' 
		where  Status in ('R', 'W', 'WL')
		and priority in (select t1.priority from #Priority t1 where t1.PriorityOrder > (select t2.PriorityOrder from #Priority t2 where t2.priority = @priority))
		and BatchJobKey in (select distinct batchjobkey from commondb..BatchJobStep where status in ('R', 'W')  group by batchjobkey having count(*) >= 1)
	end
	else
	begin
		-- First update the status for the job in the same queue
		update #FinalBatchJobDisplay set status = 'WR'
			where Status = 'R' 
			and BatchJobKey not in (select batchjobkey from commondb..BatchJobStep where status in ('R')  group by batchjobkey having count(*) > 0)
	end
	
	
	-- ResultSet 3
	select BatchJobKey , UserName , DatabaseName , NodeDisplayName , JobType , CASE when Status = 'CR' then 'CP' else Status end as Status, 
		SubmittedAt , StartedAt , FinishedAt , CriticalJob , DependencyKeyList , 
		DemandSurge , Frequency , EventType, Priority , MaxCoreToUse , IsPreemptive, ResourceGroupKey ,
		TotalJobSteps , FinishedJobSteps , RunningJobSteps , isHPC
		from #FinalBatchJobDisplay 
		where RowNumber between @bj_StartRowNumber and @bj_EndRowNumber  
		order by RowNumber;
		
	-- Check if Resultset 3 is empty then no need to get the job details
	
	select @hasJobs = count(*) from #FinalBatchJobDisplay 
		where RowNumber between @bj_StartRowNumber and @bj_EndRowNumber ;
	
	if (@hasJobs = 0) 
		set @returnJobStepDetails = 0;		
		
	-- Check to see whether we need to return the job step details.ResourceGroupKey
	-- If PageIndex is set to 1 then we will return the top X from the table based on the page size
	-- If the user has specified an Index which is > 1 then 
	if (@returnJobStepDetails = 1)
	begin
		if (@pageIndexBJS = 1)
		begin
			
			-- ResultSet 4 (When Page Index is 1)
			-- Here we will always set the SelectedBatchJobStepKey to -1 to indicate that the first object in the list will get selected.
			
			-- We need to get the count too for generic grid since based on the total number of rows and page size the generic
			-- displays the number of pages to display.
			
			set @sql1 = 'select @cnt = count(*) from BatchJobStep t1 
					where t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10))) ;
			
			if (len(ltrim(rtrim(@batchJobStepGridWhereClause))) >0)
				set @sql1 = @sql1 + ' and ' + @batchJobStepGridWhereClause;
			
			--if (len(ltrim(rtrim(@batchJobStepGridOrderByClause))) >0)
			--	set @sql1 = @sql1 + ' order by ' + @batchJobStepGridOrderByClause;
			if (@debug = 1)  print (@sql1);
			execute sp_executesql @sql1,N'@cnt int output', @cnt output;
			
			select @pageIndexBJS as PageIndex, -1 as SelectedBatchJobStepKey, @cnt as TotalRows, @pageSizeBJS as PageSize ;
			
			-- Check if there is only one job step for this job.
			-- In that case we will hide the POST_PROCESSOR job step which gets created during job submission.
			set @sql1 = 'select @onlyPlanJobStep = count(*) from BatchJobStep t1 
								where ENGINENAME <> ''POST_PROCESSOR'' and t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10))) ;
						
						
			if (@debug = 1)  print (@sql1);
			execute sp_executesql @sql1,N'@onlyPlanJobStep int output', @onlyPlanJobStep output;
			
			if (@onlyPlanJobStep = 1)
				set @postProcessorWhereClause = ' and ENGINENAME <> ''POST_PROCESSOR''  ';
			
			set @sql = 'select top(' + rtrim(cast (@pageSizeBJS as char(10))) + ' ) * from BatchJobStep t1 
					where t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10))) + @postProcessorWhereClause;
			
			if (len(ltrim(rtrim(@batchJobStepGridWhereClause))) >0)
				set @sql = @sql + ' and ' + @batchJobStepGridWhereClause;
			
			if (len(ltrim(rtrim(@batchJobStepGridOrderByClause))) >0)
				set @sql = @sql + ' order by ' + @batchJobStepGridOrderByClause;
			if (@debug = 1)  print (@sql);
			exec (@sql);
		end
		else 
		begin
			
			-- If the user is on a page other than the first page then we need to check whether the page user is on is still valid
			-- Since the entries in BatchJobStep table are very dynamic the page may not be relevant by the time this query is executed.
			
			set @bjs_StartRowNumber = ((@pageIndexBJS - 1) * @pageSizeBJS) + 1;
			set @bjs_EndRowNumber = @pageIndexBJS * @pageSizeBJS;
			exec absp_Util_GetFieldNames @batchJobStepColList output, 'batchjobstep', '';
			
			if (len(ltrim(rtrim(@batchJobStepGridOrderByClause))) = 0)
				set @batchJobStepGridOrderByClause = ' batchjobstepkey ';
			
			if (len(ltrim(rtrim(@batchJobStepGridWhereClause))) = 0)
				set @batchJobStepGridWhereClause = ' where t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10)));
			else
				set @batchJobStepGridWhereClause = ' where ' + @batchJobStepGridWhereClause + ' and  t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10)));
				
			set @sql = 'SET IDENTITY_INSERT #TMP_BJS ON;
					with orderedBJS as
					(select ' + @batchJobStepcolList + ' , Row_Number() over ( order by '  + @batchJobStepGridOrderByClause  + ') as RowNum from BatchJobStep t1 ' + 
					@batchJobStepGridWhereClause + 
					') 
					insert into #TMP_BJS (' +  @batchJobStepcolList + ',RowNumber) select * from orderedbjs;
					SET IDENTITY_INSERT #TMP_BJS OFF' ;

			if (@debug = 1)  print (@sql);
			exec (@sql);
			
			-- If the page user is selected on is not there then jump to the first page.
			-- We intentionally did not want to move last but one page due to performace reasons.
			-- Also for batch job step grid the data from the first page is more useful since all the other
			-- pages will probably have job steps that are all waiting.
			if not exists (select 1 from #TMP_BJS where RowNumber <= @bjs_EndRowNumber and RowNumber >= @bjs_StartRowNumber)
			begin
				set @pageIndexBJS = 1;
				set @bjs_StartRowNumber = ((@pageIndexBJS - 1) * @pageSizeBJS) + 1;
				set @bjs_EndRowNumber = @pageIndexBJS * @pageSizeBJS;
			end
			
			-- ResultSet 4 (When Page Index is not set to 1 initially)
			-- Here we will always set the SelectedBatchJobStepKey to -1 to indicate that the first object in the list will get selected.
			
			select @cnt = count(*) from #TMP_BJS;
			select @pageIndexBJS as PageIndex, -1 as SelectedBatchJobStepKey, @cnt as TotalRows, @pageSizeBJS as PageSize ;
			
			-- Check if there is only one job step for this job.
			-- In that case we will hide the POST_PROCESSOR job step which gets created during job submission.
			set @sql1 = 'select @onlyPlanJobStep = count(*) from BatchJobStep t1 
								where ENGINENAME <> ''POST_PROCESSOR'' and t1.BatchJobKey = ' + rtrim(cast (@selectedBatchJobKey as char(10))) ;
						
						
			if (@debug = 1)  print (@sql1);
			execute sp_executesql @sql1,N'@onlyPlanJobStep int output', @onlyPlanJobStep output;
			
			if (@onlyPlanJobStep = 1)
				set @postProcessorWhereClause = ' and ENGINENAME <> ''POST_PROCESSOR''  ';
			
			-- ResultSet 5 
			
			set @sql = ' select ' + @batchJobStepcolList + ' from #TMP_BJS ' +
					' where RowNumber between '  + rtrim(cast (@bjs_StartRowNumber as char(10))) + ' and ' +
					rtrim(cast (@bjs_EndRowNumber as char(10))) + @postProcessorWhereClause + 
					' order by  ' + @batchJobStepGridOrderByClause ;
			
			print (@sql);
			exec (@sql);
		end
	end
	else
	begin
		-- Return empty resultset to satisfy the calling routine.
		select -1 as PageIndex, -1 as SelectedBatchJobStepKey, 0 as TotalRows , 0 as PageSize;
		select top(@pageSizeBJS) * from commondb..BatchJobStep t1 where 1=2;
	end
	

 end
