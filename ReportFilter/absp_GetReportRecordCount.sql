if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetELTReportRecordCount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetELTReportRecordCount
end
 go

create procedure absp_GetELTReportRecordCount @batchJobKey int,@threshold int,@analysisRunKey int =-1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure updates AvailableReport.RecordCount for the associated node.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin
	set nocount on


	declare @eltRecCnt int;

	if @batchJobKey>0
	begin
		--Get node Info for the given batchJobKey--
		select @analysisRunKey=AnalysisRunKey from AnalysisRunInfo where AnalysisRunKey in(select AnalysisRunKey from BatchJob where BatchJobKey=@batchJobKey and DBName=DB_NAME() );
	end


				set @eltRecCnt = -1;
	update AvailableReport
			set RecordCount=  B.RecordCount 
	from AvailableReport A inner join eltsummary B
					on A.reportid = B.reportid
				        and A.analysisrunkey = B.analysisRunkey
	where A.ReportID = B.ReportID
				        and  A.AnalysisRunKey =@analysisRunKey

				end

 