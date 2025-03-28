if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetWaitingRunningHPCJobs') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetWaitingRunningHPCJobs
end
go

create procedure absp_GetWaitingRunningHPCJobs  
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MSSQL
Purpose:	This procedure will return a list of HPC jobs.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on
	
	declare @serverStarted varchar(20);
	declare @sql varchar(max);
	declare @JobToExclude table (BatchJobKey int);
	declare @dependencyKeyList varchar(1000);
	declare @batchJobKey int;
   	declare @criticalJob char(1);
   	declare @insertFlag int;
   	declare @status varchar(20);

	--Create temp table
	create table #DBToInclude (DBName varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS,DBRefKey int);
	create table #RunningJobsTbl (BatchJobKey int);
	create table #ExcludeJobsTbl (BatchJobKey int);	

	--Return if App_Server_Started is initialized to false
	set @serverStarted=''
	select  @serverStarted = bk_value  from bkprop where bk_key = 'App_Server_Started';
	if @serverStarted='' or @serverStarted='false'
	begin
		-- Return Dummy result to satify hibernate
		select * from commondb..BatchJob where 1 = 2;
		return;
	end

	-- Get the list of Databases whose job can be processed and are attached 
	insert into #DBToInclude SELECT distinct name, DBRefKey FROM sys.databases
					inner join commondb..BatchJob BatchJob on sys.databases.name COLLATE DATABASE_DEFAULT = BatchJob.dbName COLLATE DATABASE_DEFAULT
					where state_desc = 'Online'

	-- Now get the list of Databases whose job can be processed. If the database is not attached or offline or it has
	-- MIGRATION_NEEDED or MIGRATION_IN_PROGRESS Attrib set then we will not process jobs (other than Migration jobs) 
	-- associated with those databases.
	
	delete from #DBToInclude where DBRefKey in (select t1.DBRefKey from commondb..BatchJob t1 
					inner join CFLDRINFO t2 on t1.DBRefKey = t2.CF_REF_KEY and t2.Attrib <> 32);


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
			
	

   	--Here we are only checking for BatchJobs that has dependency.
   	--Later we will add all the independent jobs (i.e. DependencyKeyList = 0)
	set @dependencyKeyList = '';
   	declare cursBatchJob  cursor fast_forward  for
   	        select BatchJobKey, DependencyKeyList  from commondb..BatchJob A
   	        inner join #DBToInclude B on A.DBRefKey = B.DBRefKey
   	          where BatchJobKey not in (select BatchJobKey from @JobToExclude)
			  and STATUS in ('W','R','WL') and DependencyKeyList <> '0'  and isHPC='Y'
			  
	
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
	
	

	--Now find out all the analysis jobs that cannot be run because they have paste-linked children.
	insert #ExcludeJobsTbl exec absp_GetExcludeRunningJobList;

	-- Now add all the indepedent jobs
	insert into #RunningJobsTbl
		select BatchJob.BatchJobKey from commondb..BatchJob BatchJob
		where  BatchJob.DependencyKeyList = '0' and Status in ('W', 'R', 'WL') 
		and Not BatchJobKey in (select BatchJobKey from @JobToExclude)
		and BatchJobKey in (select BatchJobKey from #DBToInclude)

	-- Now add any migration job
	insert into #RunningJobsTbl
		select BatchJob.BatchJobKey from commondb..BatchJob BatchJob
		where  BatchJob.JobTypeID = 28 and Status in ('W', 'R', 'WL') 


	--Get all the running jobs	order by job key		
		select t1.*   from commondb..BatchJob t1
					where t1.BatchJobKey in (select rj.BatchJobKey from #RunningJobsTbl rj) 
					and t1.BatchJobKey not in (select distinct ej.BatchJobKey from #ExcludeJobsTbl ej)
					and t1.Status in ('R','W', 'WL') and isHPC='Y'
					order by t1.BatchJobKey;								


end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

	select @ProcName = object_name(@@procid);
    	select	@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch
