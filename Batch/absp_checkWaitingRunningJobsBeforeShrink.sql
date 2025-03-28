if exists(select * from SYSOBJECTS where ID = object_id(N'absp_checkWaitingRunningJobsBeforeShrink') and objectproperty(ID, N'IsProcedure') = 1)
begin
   drop procedure absp_checkWaitingRunningJobsBeforeShrink;
end
go

create procedure absp_checkWaitingRunningJobsBeforeShrink @dbName varchar(120), @batchJobKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure will check if there are any waiting/running Report/Analysis jobs and then try to shrink a Db file

Returns:        Nothing.

Example call:
		absp_checkWaitingRunningJobsBeforeShrink <DBName>, <BatchJobKey>

====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbName ^^ Database name for the batch job
##PD  @batchJobKey ^^ The batch job key

*/
as
begin

	declare @dbRefKey int;
	declare @isJobWaitingRunning int;
	
	select @dbRefKey=cf_Ref_Key from cfldrinfo where db_name = @dbName; 
	
	--check batchjob--
	select @isJobWaitingRunning = 1 from BatchJob where DBRefKey = @dbRefKey and status in ('W','WL', 'R') and JobTypeID in (0, 22) and batchJobKey != @batchJobKey;
	
	if @isJobWaitingRunning = 0 
		exec absp_Util_ShrinkDbLog;
	
	-- To satisfy Hibernate --
	select '';
	
end
