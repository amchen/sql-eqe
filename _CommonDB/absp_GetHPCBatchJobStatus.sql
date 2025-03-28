if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetHPCBatchJobStatus') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetHPCBatchJobStatus
end
go

create procedure absp_GetHPCBatchJobStatus
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	    This procedure will return the batchjob status for all running batch jobs.
				This will be needed by Java code to perform cleanup for cancelled & failed jobs.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on

	--create table variables--
	declare @RunningHPCJobs table (BatchJobKey int, Status varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS)

	--Get all running HPC jobs--
 	insert into @RunningHPCJobs select BatchJobKey,Status from commondb..BatchJob where IsHPC='Y' and Status='R';

	--Remove jobs where Status of BatchJobStep is 'W' or 'R'--
	delete from @RunningHPCJobs where BatchJobKey in (select BatchJobKey from commondb..BatchJobStep where  Status in ('W','R'));

	--@RunningHPCJobs contains finished jobs with status 'S','F','C'--
	--Mark Failed Jobs--
	update @RunningHPCJobs set Status='F' where BatchJobKey in (select distinct BatchJobKey from commondb..BatchJobStep where Status='F')

	--Mark Cancelled Jobs--
	update @RunningHPCJobs set Status='C' where status='R' and BatchJobKey in (select distinct BatchJobKey from commondb..BatchJobStep where Status='C')

 	--Marke 'S' if all are 'S'--
	update @RunningHPCJobs set Status='S'
		from @RunningHPCJobs T1 inner join commondb..BatchJobStep T2 on T1.BatchJobKey=T2.BatchJobKey
		where T1.Status='R' and 'S'= ALL (select Status from commondb..BatchJobStep T3 where T2.BatchJobStepKey=T3.BatchjobStepKey )

	select B.*, C.JobTypeName, A.Status as TmpStatus from @RunningHPCJobs A
		 inner join commondb..BatchJob B on A.BatchJobKey=B.BatchJobKey
		 inner join JobDef C on B.JobTypeID =C.JobTypeID
		 where A.Status in ('S','C','F')
		 order by B.BatchJobKey;

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
