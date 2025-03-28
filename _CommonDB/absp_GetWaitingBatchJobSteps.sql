if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetWaitingBatchJobSteps') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetWaitingBatchJobSteps
end
go

create procedure absp_GetWaitingBatchJobSteps @batchJobKey int, @sequenceID int, @availableHostCount int
as
begin
       set nocount on

       declare @sql varchar(max)
       declare @maxCoresToUse int;
       declare @numStepsRunning int;
       declare @top int;
       declare @debug int;

       set @debug = 0;

       select @maxCoresToUse = maxCoresToUse from commondb..BatchJobSettings where BatchJobKey = @batchJobKey;
       select @numStepsRunning = count(*) from commondb..BatchJobStep where  BatchJobKey = @batchJobKey and Status = 'R';

       if (@maxCoresToUse = 0)
              set @top = @availableHostCount;
       else
              set @top = @maxCoresToUse - @numStepsRunning;

       -- Check if any step status = F and no step in R, W, W
	if not exists(select 1 from  commondb..batchJobStep batchJobStep  where EngineName <> 'POST_PROCESSOR' and batchJobStep.batchJobKey=@batchJobKey and  Status  not in ('S','F','C'))
      	begin
            	select  batchJobStep.* from commondb..batchJobStep batchJobStep  where batchJobStep.batchJobKey=@batchJobKey and EngineName = 'POST_PROCESSOR' and batchJobStep.Status <> 'R';
      	end                           
	else -- All job steps in ( W, WL)
      	begin
                  select top (@top) batchJobStep.* from commondb..batchJobStep batchJobStep WITH (NOLOCK)  where batchJobStep.batchJobKey=@batchJobKey and batchJobStep.sequenceID=@sequenceID  
                  and batchJobStep.status in ('W', 'WL') and EngineName <> 'POST_PROCESSOR' order by PlanSequenceID , SequenceID , StepWeight desc;
       	end
end
