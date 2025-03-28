if exists (select 1 from sysobjects where id = object_id(N'dbo.absp_GetReportData') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure dbo.absp_GetReportData;
end
go

CREATE  procedure [dbo].[absp_GetReportData]
	@analysisRunKey  Int,
	@exposureKey int ,
	@reportTypeKey int,
	@exposureReportType int,
	@analysisReportType int,
	@importReportType int,
	@eltReportType int,
	@status varchar(100),
	@runningJobStatus varchar(100),
	@inProgressReportStatus varchar(100)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure will return the list of available reports. This procedure is used by the ReportService to return the list to the Report Panel/
Returns:    Returns a resultset.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @analysisRunKey  ^^  The AnalysisRunKey from the AnalysisRunInfo table. This key will be 0 for Import Reports.
##PD  @exposureKey  ^^  This key will be 0 for all report types except Import Reports.
##PD  @reportTypeKey  ^^  The report type from ReportTypeDef table.
##PD  @exposureReportType  ^^  The report type key for Exposure. Constant value from ReportTypeDef table.
##PD  @analysisReportType  ^^  The report type key for Analysis. Constant value from ReportTypeDef table.
##PD  @importReportType  ^^  The report type key for Import. Constant value from ReportTypeDef table.
##PD  @status  ^^  The report status (Waiting or Available)
##PD  @runningJobStatus  ^^  Status to be used if the running job.
##PD  @inProgressReportStatus  ^^  Status to be used if the report is in progress.

*/

Begin
	declare @UserName varchar(100),
	@SummaryRPKey int,
	@ReturnPeriod1 int,
    @ReturnPeriod2 int,
    @ReturnPeriod3 int,
    @ReturnPeriod4 int,
	@ReturnPeriod int,
	@cnt int

	BEGIN

	   if(@reportTypeKey = @exposureReportType or @reportTypeKey = @analysisReportType or @reportTypeKey = @eltReportType)
	   Begin
	    select @UserName=USER_NAME from USERINFO where USER_KEY in (select CreatedBy from AnalysisRunInfo where AnalysisRunKey = @analysisRunKey)
	    select @cnt=count(*) from BatchJob where AnalysisRunKey = @analysisRunKey and Status =  @runningJobStatus
	   End
	   if(@reportTypeKey = @importReportType)
	   Begin
	    select @UserName=USER_NAME from USERINFO where USER_KEY in (select CreatedBy from ExposureInfo where ExposureKey = @exposureKey )
	    select @cnt=count(*) from BatchJob where ExposureKey = @exposureKey  and Status =  @runningJobStatus
	   End

	  if(@cnt>0)set @status=@inProgressReportStatus

	   select  @SummaryRPKey=SummaryRPKey,@ReturnPeriod1=ReturnPeriod1, @ReturnPeriod2=ReturnPeriod2, @ReturnPeriod3=ReturnPeriod3, @ReturnPeriod4=ReturnPeriod4
	   from SummaryRP where SummaryRPKey in (select SummaryRPKey from AnalysisRunInfo where AnalysisRunKey = @analysisRunKey )

	   select @ReturnPeriod=ReturnPeriod from ExceedanceRP where ExceedanceRPKey in (select ExceedanceRPKey from AnalysisRunInfo where AnalysisRunKey = @analysisRunKey )

 	END

	select  @UserName as UserName,@status as Status,@SummaryRPKey as SummaryRPKey,@ReturnPeriod1 as ReturnPeriod1,@ReturnPeriod2 as ReturnPeriod2,@ReturnPeriod3 as ReturnPeriod3,@ReturnPeriod4 as ReturnPeriod4,@ReturnPeriod as ReturnPeriod;

End
