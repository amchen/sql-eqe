if exists(select * from sysobjects where id = object_id(N'absp_getSiteDetail') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getSiteDetail
end
 go
create procedure absp_getSiteDetail @siteDetail varchar(400) output, @batchJobKey int = 0, @taskKey int = 0, @analysisRunKey int = 0, @downloadKey int = 0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the site detail for which analysis has been run for the given 
batch job key, task key or analysiRunKey.

Returns:      Portfolio name, Account name, Site name

====================================================================================================
</pre>
</font>
##BD_END

##PD  @batchJobKey   ^^  The batchjob key for which the site detail is to be returned

*/

BEGIN
	SET NOCOUNT ON;

	declare @accountKey int;
	declare @siteKey int;
	declare @exposureKey int;
	declare @parentName varchar(120);
	declare @parentKey int;
	declare @parentType int;
	declare @accountNum varchar(120);
	declare @siteNum varchar(120);
	
		-- figure out all the keys from batchjob or TaskInfo	
	if @batchJobKey > 0 
		select @accountKey = accountKey, @siteKey = siteKey, @exposureKey = exposureKey from BatchJob where BatchJobKey = @batchJobKey;
	else if @taskKey > 0
		select @accountKey = accountKey, @siteKey = siteKey, @exposureKey = exposureKey from Taskinfo where TaskKey = @taskKey;
	else if @analysisRunKey > 0
		select  @accountKey = accountKey, @siteKey = siteKey, @exposureKey = exposureKey from AnalysisRunInfo where AnalysisRunKey = @analysisRunKey;
	else if @downloadKey > 0
		select  @accountKey = accountKey, @siteKey = siteKey, @exposureKey = exposureKey from DownloadInfo where DownloadKey = @downloadKey;
		
			
	select @parentKey = parentKey, @parentType = parentType from exposureMap where exposureKey = @exposureKey;
	
	if (@parentType = 2)
		select @parentName = longname from pprtinfo where pport_key = @parentKey;
		
	if (@parentType = 27)
		select @parentName = longname from proginfo where prog_key = @parentKey;		

	select @accountNum = AccountNumber from account where accountKey = @accountKey and exposureKey = @exposureKey;

	select @siteNum = SiteNumber from site where accountKey = @accountKey and exposureKey = @exposureKey and siteKey = @siteKey;

	set @siteDetail = @parentName + ' : ' + @accountNum + ' : ' + @siteNum;
	
	
END
