if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetNodeStatusForExposureBrowser') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetNodeStatusForExposureBrowser
end
 go

create procedure absp_GetNodeStatusForExposureBrowser @nodeKey int, @nodeType int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure returns an integer which states whether the Browser Data needs regeneration or
	the data regeneration is in progress.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END


*/
as
begin
	set nocount on
	declare @attrib int;
	--Check TaskInfo entry --
	if @nodeType=2
	begin
		if exists(select 1 from TaskInfo where PportKey=@nodeKey and nodeType=@nodeType and TaskDetailDescription='FILTER_INPROGRESS' and Status in('WAITING','RUNNING'))
		begin
			select 1 as status;
			return;
		end
		if exists(select 1 from TaskInfo where PportKey=@nodeKey and nodeType=@nodeType and TaskDetailDescription='FIND_REPLACE_INPROGRESS' and Status in('WAITING','RUNNING'))
		begin
			select 3 as status;
			return;
		end
	end		
	else if @nodeType=27 
	begin
		if exists(select 1 from TaskInfo where ProgramKey=@nodeKey and nodeType=@nodeType and TaskDetailDescription='FILTER_INPROGRESS' and Status in('WAITING','RUNNING'))
		begin
			select 1 as status;
			return;
		end
		if exists(select 1 from TaskInfo where ProgramKey=@nodeKey and nodeType=@nodeType and TaskDetailDescription='FIND_REPLACE_INPROGRESS' and Status in('WAITING','RUNNING'))
		begin
			select 3 as status;
			return;
		end
	end		
		
	--Check if Filter task Cancelled
	exec absp_InfoTableAttribGetBrowserFilterTaskCancel  @attrib out,@nodeType,@nodeKey
	if @attrib=1 
	begin
		select 2 as status;
		return;
	end
	
	--Check if Find Replace Cancelled
	exec absp_InfoTableAttribGetBrowserFindReplCancel  @attrib out,@nodeType,@nodeKey
	if @attrib=1 
	begin
		select 4 as status;
		return;
	end;
	
	--Check if Filter task Failed
	exec absp_InfoTableAttribGetBrowserFilterTaskFail  @attrib out,@nodeType,@nodeKey
	if @attrib=1 
	begin
		select 7 as status;
		return;
	end;
			
	--Check if Find Replace Failed
	exec absp_InfoTableAttribGetBrowserFindReplFail  @attrib out,@nodeType,@nodeKey
	if @attrib=1 
	begin
		select 8 as status;
		return;
	end

	
	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0
		select 5 as status
	else
		select 6 as status
		

	
end