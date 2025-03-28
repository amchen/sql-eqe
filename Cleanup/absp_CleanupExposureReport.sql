if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanupExposureReport') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupExposureReport;
end
go

create procedure absp_CleanupExposureReport
	@nodeKey int,
	@nodeType int,
	@exposureKey int,
	@cleanupStep int
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure cleans up the Exposure Report for the given nodeKey and nodeType.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on;

	-- Clean PumRprt
	if (@cleanupStep > 0) begin
		update ExposureInfo set InvalidateLargeTables = 1 where ExposureKey = @exposureKey;
	end

	-- Clean LossCalc
	if (@cleanupStep > 1) begin
		update ExposureInfo set InvalidateLargeTables = 1 where ExposureKey = @exposureKey;
	end

	-- Clean ExposureReport base table
	if (@cleanupStep > 2) begin
	    delete ExposureReport where ParentKey = @nodeKey and ParentType = @nodeType;
	end

	if (@cleanupStep > 3) begin
		-- Clean ExposureReportInfo table
		delete ExposureReportInfo where ParentKey = @nodeKey and ParentType = @nodeType;

		-- Clean ExposureSummaryReport table
		delete ExposureSummaryReport where NodeKey = @nodeKey and NodeType = @nodeType;
	end
end
