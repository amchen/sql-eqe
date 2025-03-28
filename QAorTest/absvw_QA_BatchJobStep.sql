if exists (select 1 from sysobjects where id = object_id('absvw_QA_BatchJobStep') and type = 'V')
	drop view absvw_QA_BatchJobStep;
go

create view absvw_QA_BatchJobStep as


with myCTEEngineOptions (BatchJobStepKey, EngineName, EngineOptions


 ) as
(
	select BatchJobStepKey, EngineName,
	EngineOptions =
	case 
	when CHARINDEX('Geocode', EngineName) > 0 then
		SUBSTRING(EngineArgs,
			CHARINDEX('<GeocodeEngineOptions', EngineArgs), 
			CHARINDEX('</GeocodeEngineOptions', EngineArgs) - CHARINDEX('<GeocodeEngineOptions', EngineArgs)
			)

	when CHARINDEX('Report', EngineName) > 0 then
		SUBSTRING(EngineArgs,
			CHARINDEX('<ReportEngineOptions', EngineArgs), 
			CHARINDEX('</ReportEngineOptions', EngineArgs) - CHARINDEX('<ReportEngineOptions', EngineArgs)
			)

	when CHARINDEX('Translate', EngineName) > 0 then
		SUBSTRING(EngineArgs,
			CHARINDEX('<TranslatorEngineOptions', EngineArgs), 
			CHARINDEX('</TranslatorEngineOptions', EngineArgs) - CHARINDEX('<TranslatorEngineOptions', EngineArgs)
			)
			
	else
		EngineArgs
	End 
	
	from BatchJobStep
),

myCTEFunctionStart (BatchJobStepKey, myFunctionStart) as
(
	select BatchJobStepKey, [myFunctionStart] = Case
	when CHARINDEX('function="', EngineOptions) > 0 then
		SUBSTRING(EngineOptions,   CHARINDEX('function="', EngineOptions) + 10, 50) 
	
	when CHARINDEX(',',  EngineOptions) > 0 then
		LEFT(EngineOptions,  CHARINDEX(',',  EngineOptions) - 1)
	
	else
		EngineOptions
	end
	
	from myCTEEngineOptions

),

myCTEFunction (BatchJobStepKey, [Function]) as
(

	select BatchJobStepKey, [Function] = case
		when CHARINDEX('"', myFunctionStart) > 0 then
			LEFT(myFunctionStart, CHARINDEX('"', myFunctionStart) - 1)
		else
			myFunctionStart
		end
			
	from myCTEFunctionStart

)


select 

	BatchJobStep.BatchJobStepKey, BatchJobKey, EngineName, myCTEFunction.[Function], PlanSequenceID, SequenceID, StepWeight, Priority, 
	AnalysisConfigKey, Logkey, StartDate, FinishDate, LastResponseTime, ExecutionTime, 
	EngineGroupID, EnginePid, HostName, HostPort, Status, ErrorMessage, EngineArgs

from 
	myCTEFunction, BatchJobStep 
where 
	myCTEFunction.BatchJobStepKey = BatchJobStep.BatchJobStepKey



-- select * from absvw_QA_BatchJobStep


