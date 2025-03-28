if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDownloadTaskStepInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDownloadTaskStepInfo
end
 go

create procedure absp_GetDownloadTaskStepInfo @taskKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      The procedure returns a task step info object
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin
	set nocount on
	
	select TaskStepInfoKey,TaskKey,StepNumber,Status,StepDescription, StepStartTime, DetailMessage  from TaskStepInfo where TaskKey=@taskKey order by TaskStepInfoKey;
	
end  
