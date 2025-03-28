if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UpdateHPCBatchJobStatus') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateHPCBatchJobStatus
end
go

create procedure absp_UpdateHPCBatchJobStatus  @batchJobKey int,@debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	    This procedure will update the BatchJob table with the job status information.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on
 
 	--Check if any job step is in Waiting or Running Status. If 'Y' return.
    if exists(select 1 from commondb..BatchJobStep where BatchJobKey= @batchJobKey and Status in ('W','R')) --No need to update
	begin
		select '';
		return;
	end

	--All jobs are completed if we are here--
	if exists (select 1 from commondb..BatchJobStep where BatchJobKey=@batchJobKey and Status<>'S')
	begin

		--Check if Failed-- 
		if exists(select 1 from commondb..BatchJobStep where BatchJobKey=@batchJobKey and Status='F')
		begin	
		    --If it is a critical Job, mark the dependent jobs as failed--
			if exists(select * from commondb..BatchJob where BatchJobKey=@batchJobKey and CriticalJob='Y')
			begin
				exec absp_MarkDependentHPCBatchJobsAsFailed @batchJobKey
			end
			--Mark the batch job as failed--
			update BatchJob set Status='F' where BatchJobKey=@batchJobKey;
		
		end
		else if exists(select 1 from commondb..BatchJobStep where BatchJobKey=@batchJobKey and Status='C')
		begin
			--Mark the batch job as Cancel Pending--
			--It will be handled by the java code--
			update commondb..BatchJob set Status='CP' where BatchJobKey=@batchJobKey;
		end
	end
	else
	begin
		--All jobSteps are 'S', thus mark the BatchJob.Status as 'S'
		update commondb..BatchJob set Status='S' where BatchJobKey=@batchJobKey;

	end
	select '';
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
