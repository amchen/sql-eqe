if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MarkDependentHPCBatchJobsAsFailed') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_MarkDependentHPCBatchJobsAsFailed
end
go

create procedure absp_MarkDependentHPCBatchJobsAsFailed  @batchJobKey int,@debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	    This procedure will mark the dependent jobs as Failed.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on
 
	--Create temporary table
	--union is used to handle the identity column
	select * into #DependentJobs from commondb..BatchJob where 1=2
	union
	select *  from commondb..BatchJob where 1 = 2;
	 
    --Get dependent BatchJobs--
 	insert into #DependentJobs exec absp_GetDependentBatchJobs @batchJobKey

	--Mark Dependent jobs as failed--
	update commondb..BatchJob set Status='F' 
	     from commondb..BatchJob A inner join #DependentJobs B on A.BatchJobKey=B.BatchJobKey

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
