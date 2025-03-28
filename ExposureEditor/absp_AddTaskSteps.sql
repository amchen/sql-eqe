if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_AddTaskSteps') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_AddTaskSteps
end
 go

create procedure absp_AddTaskSteps  @taskKey int, @stepNumber int,@stepStatus varchar(50),@stepDescription varchar(254),@stepDetailMsg varchar(max),@addStep int =1			
as
begin try
	set nocount on
	
	declare @stepStartTime varchar(14)
	declare @stepInfoKey int
	
	exec absp_Util_GetDateString @stepStartTime output 
	
	if @addStep=1 
	begin
		if @stepNumber = -1
		begin
			select @stepNumber = (isNull(MAX(stepNumber),0) + 1) from TaskStepInfo where TaskKey = @taskKey
			exec @stepInfoKey = absp_GenericTableGetNewKey 'TaskStepInfo','StepNumber',@stepNumber
			update TaskStepInfo set TaskKey = @taskKey, status= @stepStatus,DetailMessage=@stepDetailMsg, StepDescription=@stepDescription, StepStartTime = @stepStartTime where StepNumber=@stepNumber and TaskStepInfoKey = @stepInfoKey
		end
		else
		    insert into TaskStepInfo values(@taskKey, @stepNumber, @stepStatus, @stepDescription, @stepStartTime, @stepDetailMsg);
	end
	else
	begin
		update TaskStepInfo set status= @stepStatus,DetailMessage=@stepDetailMsg, StepStartTime = @stepStartTime where StepNumber=@stepNumber and taskKey=@taskKey
	end
end try
begin catch
end catch

