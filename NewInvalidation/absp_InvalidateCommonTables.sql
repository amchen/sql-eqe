if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_InvalidateCommonTables') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateCommonTables;
end
go

create procedure absp_InvalidateCommonTables
	@nodeKey int,
	@nodeType int,
	@invalidateExposureReport int = 0,
	@taskKey int=0
as

BEGIN TRY

	set nocount on;

	declare @AnalysisRunKey int;
	declare @sql varchar(max);
	declare @TableColumn varchar(30);
	declare @nodeTypeString varchar(10);
	declare @taskProgressMsg varchar(max);
	declare @procID int;
               	
   	-- Get the Procedure ID and the TaskKey since we need to add entries to TaskProgress
   	set @procID = @@PROCID;
            
   	-- Add a task progress message
   	set @taskProgressMsg = 'Invalidation started.';
   	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
   	
	if (@nodeKey < 0) begin --don't go any further.
		execute absp_Migr_RaiseError 1,'Invalid @nodeKey < 0';
	end
	if (@nodeType < 1) begin --don't go any further.
		execute absp_Migr_RaiseError 1,'Invalid @nodeType < 1';
	end

	select @TableColumn = Case @nodeType
		when 0  then 'FolderKey'
		when 1  then 'AportKey'
		when 2  then 'Pportkey'
		when 3  then 'RPortKey'
		when 4  then 'AccountKey'
		when 7  then 'ProgramKey'
		when 9  then 'SiteKey'
		when 10 then 'CaseKey'
		when 23 then 'RPortKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		when 64 then 'ExposureKey'
	end
	
	select @nodeTypeString = Case @nodeType
		when 64  then '4,9'
		else cast(@nodeType as varchar(10))
	end
	
	-- Add a task progress message
	set @taskProgressMsg = 'Invalidating tables : AnalysisRunModelInfo, AnalysisRunModelInfo, AvailableReport';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	-- invalidate AnalysisRunModelInfo
	set @sql = 'delete from AnalysisRunModelInfo from AnalysisRunModelInfo r ' + 
		'INNER JOIN AnalysisRunInfo i on r.AnalysisRunKey = i.AnalysisRunKey INNER JOIN AvailableReport a on  a.AnalysisRunKey = i.AnalysisRunKey ' + 
		'where (i.NodeType in( '+@nodeTypeString+')) AND (i.'+@TableColumn+' = '+cast(@nodeKey as varchar(10))+')  and a.Status = ''Available''';
	execute (@sql);
	
	-- invalidate AnalysisRunModelInfo for ELT Reports
	set @sql = 'delete from AnalysisRunModelInfo from AnalysisRunModelInfo r ' + 
		'INNER JOIN AnalysisRunInfo i on r.AnalysisRunKey = i.AnalysisRunKey INNER JOIN ELTSummary e on e.AnalysisRunKey = i.AnalysisRunKey ' + 
		'where (i.NodeType in( '+@nodeTypeString+')) AND (i.'+@TableColumn+' = '+cast(@nodeKey as varchar(10))+')  and e.Status = ''Active''';
	execute (@sql);
	
	--delete from AvailableReport except ELT Reports since for ELT Reports the AvailableReports.Status is not set to "Available"
	set @sql = 'delete from AvailableReport from AvailableReport a
		INNER JOIN AnalysisRunInfo i on a.AnalysisRunKey = i.AnalysisRunKey
		where (i.NodeType in( '+@nodeTypeString+')) AND (i.'+@TableColumn+' = '+cast(@nodeKey as varchar(10))+')  and a.Status = ''Available''';
	execute (@sql);
	
	-- Now delete from AvailableReports for ELT Reports. We need to check ELTSummary to remove these records
	set @sql = 'delete from AvailableReport from AvailableReport a
		INNER JOIN AnalysisRunInfo i on a.AnalysisRunKey = i.AnalysisRunKey
		inner join ELTSummary e on e.AnalysisRunKey = i.AnalysisRunKey 
		where (i.NodeType in ('+@nodeTypeString+')) AND (i.'+@TableColumn+' = '+cast(@nodeKey as varchar(10))+')  and e.Status = ''Active''';
	execute (@sql);
		
	-- Add a task progress message
	set @taskProgressMsg = 'Invalidating tables : ReportsDone, ReportFilterInfo, SP_FILES';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	-- 0001929: Need to Invalidate ReportsDone table
	delete ReportsDone where NodeType=@nodeType and NodeKey=@nodeKey;
	
	--negate the NODE_KEY rather than direct delete so the background BLOB delete event
	--can take care of it more efficiently
	update SP_FILES set NODE_KEY = -(NODE_KEY) where NODE_KEY=@nodeKey and Node_Type=@nodeType;
	
	--delete from ReportFilterInfo--
	set @sql='delete ReportFilterInfo where NodeType=' + cast(@nodeType as varchar(10)) + ' and ' + @TableColumn + '=' + cast(@nodeKey as varchar(10));
	exec(@sql);
	
	if (@invalidateExposureReport = 1)
	begin
		-- Add a task progress message
		set @taskProgressMsg = 'Invalidating tables : ExposureSummaryReport, ExposedLimitsReport';
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
		
		delete ExposureSummaryReport where NodeKey=@nodeKey and NodeType=@nodeType;
		delete ExposedLimitsReport where NodeKey=@nodeKey and NodeType=@nodeType;
	end
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH

-- Add a task progress message
set @taskProgressMsg = 'Invalidation completed successfully.';
exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;