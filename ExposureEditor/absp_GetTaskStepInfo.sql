if exists(select * from sysobjects where id = object_id(N'absp_GetTaskStepInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetTaskStepInfo
end
go

create procedure absp_GetTaskStepInfo @nodeKey int, @nodeType int, @taskType int = 1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the Task Step Info for a given node key, node type. This procedure will be used by
the Task service to get the Task Step Info fro mthe TaskstepInfo table.

Returns:      TaskStepInfo rows

====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey   ^^  The key for the node.
##PD  @nodeType   ^^  The type of node.
##PD  @taskType   ^^  The type of task. invalidate=1,Search=2,ExposureCopy=3,ExposureDataFilterSort=4,FindReplaceInExposureSet=5

*/
begin
	set nocount on
	declare @taskKey int;
	declare @keyName varchar(10); 
	declare @sql nvarchar(max);
	
	exec @taskKey = absp_getTaskKey @nodeKey,@nodeType,@taskType, '''Waiting'',''Running'''
	select dbo.TaskStepInfo.* from TaskStepInfo with(nolock) where TaskKey = @taskKey order by 1,2
	
end