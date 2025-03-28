if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ConvertAnalysisPlannerOutputToJobStep') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ConvertAnalysisPlannerOutputToJobStep;
end
go

create procedure absp_ConvertAnalysisPlannerOutputToJobStep
	@batchJobKey int,
	@planSeqeuenceID int
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure converts AnalysisJob Planner output in SeqPlout table to 
			   BatchJobStep table entries.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on;

	declare @createDt varchar(14);
	declare @engineArgs varchar(max);
	declare @groupID int;
	declare @analysisCfgKey int;
	declare @sequenceID int;
	declare @priority varchar(10);
	declare @estimatedTime int;
	
	insert into commondb..BatchJobStep 
		(batchJobKey, PlanSequenceID, SequenceID, StepWeight, EngineName, Priority, AnalysisConfigKey, EngineGroupID, Status, ErrorMessage, EngineArgs) 
		select @batchJobKey, @planSeqeuenceID, SEQ_ID, ESTIM_TIME, ENG_NAME, PRIORITY, ANLCFG_KEY, GROUP_ID, 'W', ERR_MSG, ENG_ARGS from commondb..SEQPLOUT SEQPLOUT
		where SEQPLOUT.BatchJobKey = @batchJobKey and ENG_NAME <> 'CLEANUP';
	
	-- Return Dummy result to satify hibernate
	select '';		
end
