if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetChildBatchJobs') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetChildBatchJobs
end
 go
create procedure absp_GetChildBatchJobs @pKey int as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This is a recursive procedure to check for dependent jobs.

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
	declare @status varchar(20)
	declare @retCode int
	declare @finishDt varchar(50)
	
	set @retCode=0
	
	--Get child Batch jobs with Success status--
        if not exists( select 1 from  #BatchJobsTbl where ParentKey=@pKey ) return 0
        
   	declare curs cursor fast_forward  for 
   	        select BatchJobKey, ParentKey, FinishDate, Status from  #BatchJobsTbl where ParentKey=@pKey          
   	open curs 
   	fetch next from curs  into @batchJobKey,@parentKey, @finishDt,@status
   	while @@fetch_status = 0
   	begin 	
   	   
   	    	if @status <> 'S' and @status <> 'C' and @status <> 'F'
   	    	begin
   			set @retCode =-1
   			return @retCode
   		end
   	    	else
   	    	begin
   				exec @retCode= absp_GetChildBatchJobs @batchJobKey
   				if @retCode =-1
   					break
   				else
   					insert into #BatchJobsToDelete values(@batchJobkey, @finishDt, @status)	   			
   			end
   		fetch next from curs  into @batchJobKey,@parentKey,@finishDt,@status
   	end
   	close curs
   	deallocate curs
 
   	return @retCode
end