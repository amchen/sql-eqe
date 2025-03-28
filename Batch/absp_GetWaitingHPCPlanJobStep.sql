if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetWaitingHPCPlanJobStep') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetWaitingHPCPlanJobStep
end
go

create procedure absp_GetWaitingHPCPlanJobStep  @batchJobKey int,@debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
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
	declare @batchJobStepKey int;
	declare @sequenceID int;
	 
	--Return if non-HPC job--
	if not exists(select 1 from commondb..BatchJob where BatchJobKey=@batchJobKey and IsHPC='Y') 
	begin
		select * from commondb..BatchJobStep where 1=0;
		return;
	end
	
	--Get the first SequenceID of the Plan JobStep with 'W' status   
	select top (1) @batchJobStepKey=BatchJobStepKey, @sequenceID=SequenceID from commondb..BatchJobStep where BatchJobKey=@batchJobKey and EngineName like 'Plan[_]%' and Status in ('W') order by SequenceID;
	
	-- Check to see if any job step failed. In HPC if a job step fails then the entire job gets cleaned up and there is no
	-- easy way to mark the other steps as cancel.
	-- Here we will check if any job step failed and if there is at least one failed job step we will mark all other W or R
	-- Job steps as cancelled i.e. C.
	
	if exists (select 1 from commondb..BatchJobStep where BatchJobKey = @batchJobKey and Status = 'F' and SequenceID < 99999)
	begin
		update BatchJobStep set Status = 'C' where BatchJobKey = @batchJobKey and Status in ('R', 'W') and SequenceID < 99999;
	end
	
	 
	-- Check to see if all the job steps except POST_PROCESSOR is done. The job step status can be F, S or C
	
	if not exists (select 1 from commondb..BatchJobStep where BatchJobKey = @batchJobKey and Status in ('R', 'W') and SequenceID < 99999)
	begin
		select * from commondb..BatchJobStep where BatchJobKey= @batchJobKey and EngineName like 'POST_PROCESSOR';
		return;
	end
	
	
	--If we do not have a waiting plan job, and have a RunViaHPC job for the plan job, get it.
	if (@batchJobStepKey is Null) or   (exists (select 1 from commondb..BatchJobStep where BatchJobKey=@batchJobKey and  SequenceID < @sequenceID and charIndex('RunViaHPC',EngineArgs)>0 and  Status='W'))
	begin
		select top(1) * from commondb..BatchJobStep where BatchJobKey= @batchJobKey and  charIndex('RunViaHPC',EngineArgs)>0 and Status='W' order by sequenceID
		return;
	end
	

	--Return the next Plan BatchJobStep if status of all jobs  with SeqID less than the seq ID of the Plan Job is 'S'. Return empty resultset otherwise
	if  exists (select 1 from commondb..BatchJobStep where BatchJobKey=@batchJobKey and  SequenceID < @sequenceID and Status<>'S')
	begin
		select * from commondb..BatchJobStep where 1=0;
	end 
	else 
	begin
		select * from commondb..BatchJobStep where BatchJobStepKey= @batchJobStepKey and EngineName like 'Plan[_]%' and SequenceID = @sequenceID;
	end
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
