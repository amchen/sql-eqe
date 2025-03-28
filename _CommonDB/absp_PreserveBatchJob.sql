 if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_PreserveBatchJob') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_PreserveBatchJob
end
 go
create procedure absp_PreserveBatchJob as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:      The procedure moves the jobs  with Status = "S" to BatchJobPreserve and BatchJobStepPreserve.
              We cannot move a job if dependent jobs are not complete. 
 
Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

*/
begin
	set nocount on

   	declare @batchJobKey int
   	declare @parentKey int
   	declare @retCode int
   	declare @status varchar(20)
   	declare @currentDt varchar(25)
   	declare @finishDt varchar(50)
   	declare @dependencyKeyList varchar(1000)
   	declare @sql varchar(max)
   	
   	exec absp_Util_GetDateString @currentDt output,'yyyymmdd'

	set @currentDt = dbo.trim(@currentDt)
   	
	CREATE TABLE #BatchJobsTbl (BatchJobKey int, ParentKey int, FinishDate varchar(25),Status varchar(20));
	CREATE INDEX #BatchJobsTbl_I1 on #BatchJobsTbl(BatchJobKey,ParentKey)
	
	CREATE TABLE #BatchJobsToDelete (BatchJobKey int, FinishDate varchar(25), Status varchar(20));
    
    	--Get List of Jobs and the dependent Jobs--
     	insert into #BatchJobsTbl (BatchJobKey,ParentKey,FinishDate,Status) select batchJobKey,0,FinishDate,Status from commondb..BatchJob where  DependencyKeyList='0' 
    	 --Insert dependent Jobs
    	declare cursb  cursor fast_forward  for
    	        select BatchJobKey, DependencyKeyList  from commondb..BatchJob where   DependencyKeyList<>'0' and status in ('S', 'F', 'C')	
 
    	open cursb
    	fetch next from cursb into @batchJobKey,@dependencyKeyList
    	while @@fetch_status = 0
    	begin
   
   		set @sql='insert into #BatchJobsTbl(BatchJobKey,ParentKey,FinishDate,Status)  select ' +CAST(@batchJobKey as varchar(50)) + ', BatchJobKey,FinishDate,Status from commondb..BatchJob where BatchJobKey in (' + dbo.trim(cast(@dependencyKeyList as varchar)) + ')'
 		exec(@sql)
 
       	fetch next from cursb into @batchJobKey,@dependencyKeyList
    	end
 	close cursb
	deallocate cursb
        
        --Loop through the Parent Jobs with 'S' status--
 	declare cursBatchJob  cursor fast_forward  for 
 	    select BatchJobKey, ParentKey, FinishDate, Status from  #BatchJobsTbl where ParentKey=0 order by BatchJobKey
 	open cursBatchJob
   	fetch next from cursBatchJob into @batchJobKey,@parentKey, @finishDt, @status
   	while @@fetch_status = 0
   	begin
   	
   		insert into #BatchJobsToDelete values(@batchJobkey, @finishDt, @status)
   		
   		--the procedure runs recursively through all dependents 
   		--returns 0 if all dependents are complete
  	    	exec @retCode= absp_GetChildBatchJobs @batchJobKey
   	    	if @retCode=0 --Success
		begin
						
				if ((exists(select 1 from #BatchJobsToDelete where status = 'F') and 
					exists(select 1 from #BatchJobsToDelete where finishDate<>'' and datediff(dd,substring(FinishDate, 1, 4) + '-' + substring(FinishDate, 5, 2) + '-'+ substring(FinishDate, 7, 2), @currentDt) > 6)) 
					or (not exists(select 1 from #BatchJobsToDelete where status = 'F') and 
					exists(select 1 from #BatchJobsToDelete where finishDate<>'' and datediff(dd,substring(FinishDate, 1, 4) + '-' + substring(FinishDate, 5, 2) + '-'+ substring(FinishDate, 7, 2), @currentDt) > 3) ))
				begin

					--delete from BATCHJOBSTEP
					delete from commondb..BatchJobStep where BatchJobKey in (select BatchJobKey from #BatchJobsToDelete)
				
					--delete from BATCHJOB
					delete from commondb..BatchJob where BatchJobKey in (select BatchJobKey from #BatchJobsToDelete)
					
					--delete from SEQPLOUT
					delete from commondb..SEQPLOUT where BatchJobKey in (select BatchJobKey from #BatchJobsToDelete)
					
					--delete from BatchJobSettings
					delete from commondb..BatchJobSettings where BatchJobKey in (select BatchJobKey from #BatchJobsToDelete)
				end
		end
   	   	delete from #BatchJobsToDelete
   	   	
		fetch next from cursBatchJob into @batchJobKey,@parentKey, @finishDt, @status
	end
	close cursBatchJob
	deallocate cursBatchJob
end
