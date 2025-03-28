if exists(select * from sysobjects where id = object_id(N'absp_GetTaskKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetTaskKey
end
go

create procedure absp_GetTaskKey @nodeKey int, @nodeType int, @taskType int = 1, @taskStatus varchar(80) = ''
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the task key for a given node key, node type. This procedure will be used by
the invalidation procedures to get the task key which will be used to add entries into TaskProgress table.

Returns:      TaskKey

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
	
	set @taskKey = 0;
	
	if @nodeType = 12
	begin
		set @keyName='FolderKey';
	end
	else if @nodeType = 1
	begin
		set @keyName='AportKey';
	end
	else if @nodeType = 2
	begin
		set @keyName='PportKey';
	end

	else if @nodeType = 23
	begin
		set @keyName='RportKey';
	end
	else if @nodeType = 27
	begin
		set @keyName='ProgramKey';
		end
	else if @nodeType = 30
	begin
		set @keyName='CaseKey';
	end

	-- Get the task key from TaskInfo. There might be more than one tasks on a node , we should get the info by task type and nodeType
	-- we need also get the latest taskKey if there are more than one task keys of the same node with different task statuses
	set @sql= 'select @taskKey = max(TaskKey) from TaskInfo where TaskTypeID = ' + ltrim(rtrim(str(@taskType))) +
			  ' and ' + @keyName +  ' = '  + dbo.trim(cast(@nodeKey as varchar(20)));
	
	-- There might be more than one task key per node with different statuses, so we should get the one that is unique (waiting/running)
	-- ExposureDataFilterSort=4,FindReplaceInExposureSet=5 
	if len(@taskStatus) > 0
	begin
		set @sql = @sql + ' and Status in (' + @taskStatus + ')'
	end
	
	-- exec absp_MessageEx @sql;
	execute sp_executesql @sql,N'@taskKey int output',@taskKey  output;
	
	return @taskKey;
end