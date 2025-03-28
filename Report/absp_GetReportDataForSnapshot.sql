if exists (select 1 from sysobjects where id = object_id(N'dbo.absp_GetReportDataForSnapshot') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure dbo.absp_GetReportDataForSnapshot
end
go



CREATE  procedure [dbo].[absp_GetReportDataForSnapshot]   
@analysisRunKey  Int, @schemaname varchar(50), @status varchar(100)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure will return periods and exedenceRp for snapshot analysisRunKey.
Returns:    Returns a resultset.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @analysisRunKey  ^^  The AnalysisRunKey from the AnalysisRunInfo table. This key will be 0 for Import Reports.
##PD  @status  ^^  The report status (Waiting or Available)
##PD  @schemaname  ^^  Schema name for snapshot.
*/

Begin
	set nocount on
	
	declare @UserName varchar(100);
	declare @SummaryRPKey int;
	declare @ReturnPeriod1 int;
    	declare @ReturnPeriod2 int;
    	declare @ReturnPeriod3 int;
    	declare @ReturnPeriod4 int;
	declare @ReturnPeriod int;
	
	declare @sql nvarchar(max);
	declare @outputParam nvarchar(max)
	
	BEGIN
	
	   
	   set @sql = 'select @UserName=USER_NAME from USERINFO where USER_KEY in (select CreatedBy from '+ @schemaname + '.AnalysisRunInfo where AnalysisRunKey = ' + dbo.trim(cast(@analysisRunKey as varchar(10))) + ')'
	   print @sql
	   exec sp_executesql  @sql, N'@UserName varchar(100) OUTPUT', @UserName OUTPUT
	  
	   set @outputParam = '@SummaryRPKey int OUTPUT, @ReturnPeriod1 int output, @ReturnPeriod2 int output, @ReturnPeriod3 int output, @ReturnPeriod4 int output'
	   set @sql = 'select  @SummaryRPKey=SummaryRPKey,@ReturnPeriod1=ReturnPeriod1, @ReturnPeriod2=ReturnPeriod2, @ReturnPeriod3=ReturnPeriod3, @ReturnPeriod4=ReturnPeriod4
	   from SummaryRP where SummaryRPKey in (select SummaryRPKey from '+ @schemaname + '.AnalysisRunInfo where AnalysisRunKey = '+ dbo.trim(cast(@analysisRunKey as varchar(10))) + ')'
	   exec sp_executesql  @sql, @outputParam, @SummaryRPKey OUTPUT, @ReturnPeriod1 output, @ReturnPeriod2 output, @ReturnPeriod3 output, @ReturnPeriod4 output
 
	   set @sql = 'select @ReturnPeriod=ReturnPeriod from ExceedanceRP where ExceedanceRPKey in (select ExceedanceRPKey from '+ @schemaname + '.AnalysisRunInfo where AnalysisRunKey = ' + dbo.trim(cast(@analysisRunKey as varchar(10))) + ')'
	   exec sp_executesql  @sql, N'@ReturnPeriod int OUTPUT', @ReturnPeriod OUTPUT
	  
 	END

	select  @UserName as UserName,@status as Status,@SummaryRPKey as SummaryRPKey,@ReturnPeriod1 as ReturnPeriod1,@ReturnPeriod2 as ReturnPeriod2,@ReturnPeriod3 as ReturnPeriod3,@ReturnPeriod4 as ReturnPeriod4,@ReturnPeriod as ReturnPeriod
End


GO



