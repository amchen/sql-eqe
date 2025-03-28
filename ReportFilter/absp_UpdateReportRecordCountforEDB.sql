if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UpdateReportRecordCountforEDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateReportRecordCountforEDB
end
 go

create procedure absp_UpdateReportRecordCountforEDB @analysisRunKey int, @debug int=1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      The procedure updates the report record counts for all report types 
			   excluding ELT reports and exposure reports for both EDB and RDB.
			   It is called by a new engine in the MDG sequence planner.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin
	set nocount on
	
	declare @reportQuery varchar(6000);
	declare @reportId int;
	declare @sql nvarchar(max);
	declare @recCnt int;
	declare @pos int;
	declare @pos2 int;
	declare @folderKey int;
	declare @aportKey int;
	declare @pportKey int;
	declare @rportKey int;
	declare @programKey int;
	declare @caseKey int;
	declare @accountKey int;
	declare @policyKey int;
	declare @siteKey int;
	declare @exposureKey int;
	declare @crolReq char(1);
	declare @reportType int;
	declare @anlcfgKey int;
	declare @YLTDBName varchar(150);
	declare @rdbInfoKey int;
	declare @sql2 nvarchar(max);
	declare @yltId int;
	declare @columnName varchar(120);
	declare @nodeType int;
	declare @nodeKey int;
	declare @rdbAvailableReportKey int;
 

	--Get node Info for the given analysisRunKey--
	select @nodeType=NodeType,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
		@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rPortKey=RPortKey,@programKey=ProgramKey,@caseKey=CaseKey
		from AnalysisRunInfo where AnalysisRunKey =@analysisRunKey;
	
	select @nodeKey = Case @nodeType
		when 0  then @folderKey
		when 1  then @aportKey
		when 2  then @pportkey
		when 4  then @accountKey
		when 8  then @policyKey
		when 9  then @siteKey
		when 23 then @rportKey
		when 27 then @programKey
		when 30 then @caseKey
		when 64 then @exposureKey
		else -1
	end;

	--Execute each query to get the count and update availablereport--
	declare RQCurs cursor for select T1.ReportId ,T2.ReportTypeKey, ReportQuery,AnlCfgKey  from AvailableReport T1 inner join ReportQuery T2 
		on T1.ReportId=T2.ReportId  
		where T1.AnalysisRunKey =@analysisRunKey 
		and ReportTypeKey in(3,4) and  ReportQuery<>''
	open RQCurs
	fetch RQCurs into @reportId,@reportType,@reportQuery,@anlCfgKey;
	while @@fetch_status=0
	begin
			set @recCnt=0;
			set @reportQuery=REPLACE (@reportQuery,'''''','''');
			
			--Fix the query to remove the 'order by' clause and 'top 20000 Col1, Col2'--
			set @pos = charindex(' from ', @reportQuery);
			set @pos2 = isnull(charindex(' order ', @reportQuery),LEN(@reportQuery));
			set @sql = 'select @recCnt= count(*) ' +  substring (@reportQuery,@pos,(@pos2 - @pos));
			if @debug=1 print @sql
			
			--Replace Parameters in the query--				
			select @crolReq=CrolRequired from ReportQuery where ReportId=@reportId;
			if @debug=1 print @crolReq
			
			if  @reportType=3 or @reportType=4
			begin
				if @nodeType=4  --Account
				begin
					set @sql=replace(@sql,'{0}',@pportKey);
					set @sql=replace(@sql,'{1}',@exposureKey);
					set @sql=replace(@sql,'{2}',@nodeKey);
					set @sql=replace(@sql,'{3}',@anlcfgKey);
					if @crolReq='Y'
						set @sql=replace(@sql,'= {4}','=1');
					
				end
				else if @nodeType=9 --Site
				begin
					set @sql=replace(@sql,'{0}',@pportKey);
					set @sql=replace(@sql,'{1}',@exposureKey);					
					set @sql=replace(@sql,'{2}',@accountKey);
					set @sql=replace(@sql,'{3}',@nodeKey);
					set @sql=replace(@sql,'{4}',@anlcfgKey);
					if @crolReq='Y'
						set @sql=replace(@sql,'= {5}','=1');

				end
				else --other nodes
				begin
					set @sql=replace(@sql,'{0}',@nodeKey);
					set @sql=replace(@sql,'{1}',@anlcfgKey);
					if @crolReq='Y'
						set @sql=replace(@sql,'= {2}','=1');
				end;
				
				--Execute count query--
				if @debug =1 print @sql
				execute sp_executesql @sql,N'@recCnt int output',@recCnt output; 
					
				--Update RecordCount--
				update AvailableReport 
					set RecordCount=@recCnt
				from AvailableReport A 
					where AnalysisRunKey =@analysisRunKey and  ReportId=@reportId;
								
			end
			
			
			fetch RQCurs into @reportId , @reportType,@reportQuery,@anlCfgKey;
	end
	close RQCurs;
	deallocate RQCurs;

			
end  