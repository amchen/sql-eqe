if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateReportFilterInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateReportFilterInfo
end
 go

create procedure absp_GenerateReportFilterInfo @batchjobkey int, @threshold int, @analysisRunKey int =-1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure generates report filter information for the given batchjob.
		In case of migration where the batchjob may get deleted, we will pass the
		analysisRunKeys to get the node information.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin try
	set nocount on
	declare @sql nvarchar(max);
	declare @nodeType int;
	declare @folderKey int;
	declare @aportKey int;
	declare @pportKey int;
	declare @exposureKey int;
	declare @accountKey int;
	declare @policyKey int;
	declare @siteKey int;
	declare @rportKey int;
	declare @programKey int;
	declare @caseKey int;
	declare @resTableName varchar(100);
	declare @cacheTypeDefID int;
	declare @lookUpTableName varchar(100);
	declare @lookupFieldName varchar(100);
	declare @fieldName varchar(100);
	declare @lookupDisplayName varchar(100);
	declare @userCode varchar(50);
	declare @columnName varchar(100);
	declare @nodeKey int;
	declare @EBERunID int;
	declare @reportID int;
	declare @reportType int;
	declare @engineCallID int;
	declare @systemSchema varchar(50);
	declare @version varchar(50);
	
	select top (1) @version=replace(left(rqeversion,5),'.','') from RQEVersion order by RQEVersion desc, Build desc;
	set @systemSchema='RQE'+@version;
	
	
	declare @ResTblName table (ResTableName varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS, ReportID int, ReportType int, EngineCallId int);
	create table #Lookup (LookupId varchar(10), LookupValue varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS, UserCode varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS);
	
	--Update AvailableReports.RecordCount for ELT Reports--
	exec absp_GetELTReportRecordCount  @batchjobkey,@threshold,@analysisRunKey
	
	if @batchJobKey>0
	begin
		--Get node Info for the given batchJobKey--
		select @analysisRunKey=AnalysisRunKey ,@nodeType=NodeType,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
			@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rPortKey=RPortKey,@programKey=ProgramKey,@caseKey=CaseKey
		from AnalysisRunInfo where AnalysisRunKey in(select AnalysisRunKey from BatchJob where BatchJobKey=@batchJobKey and DBName=DB_NAME() );
	end
	else
	begin
		--Get node Info for the given analysisRunKey--
		select @nodeType=NodeType,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
			@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rPortKey=RPortKey,@programKey=ProgramKey,@caseKey=CaseKey
		from AnalysisRunInfo where AnalysisRunKey =@analysisRunKey;
	end
	
				
	--Get column name--
	if @nodeType=0
	begin
		set @columnName='Folder_Key'
		set @nodeKey = @folderKey
	end
	else if @nodeType=1
	begin
		set @columnName='Aport_Key'
		set @nodeKey = @aportKey
	end
	else if @nodeType=2
	begin
		set @columnName='Pport_Key'
		set @nodeKey = @pportKey
	end
	else if @nodeType=4
	begin
		set @columnName='AccountKey'
		set @nodeKey = @accountKey
	end
	else if @nodeType=8
	begin
		set @columnName='PolicyKey'
		set @nodeKey = @policyKey
	end
	else if @nodeType=9
	begin
		set @columnName='SiteKey'
		set @nodeKey = @siteKey
	end
	else if @nodeType=23
	begin
		set @columnName='RPort_Key'
		set @nodeKey = @rportKey
	end
	else if @nodeType=27
	begin
		set @columnName='Prog_Key'
		set @nodeKey = @programKey
	end
	else if @nodeType=30
	begin
		set @columnName='Case_Key'
		set @nodeKey = @caseKey
	end
	else if @nodeType=64
	begin
		set @columnName='ExposureKey'
		set @nodeKey = @exposureKey
	end
			        
	--Get the main tables for the reports associated to the node--
	insert into @ResTblName
		select  T2.MainTableName, T2.ReportID, T2.ReportTypeKey,T2.EngineCallID from AvailableReport T1 inner join ReportQuery T2
		on T1.ReportID=T2.ReportID
		where T1.AnalysisRunKey=@analysisRunKey and T1.RecordCount<=@threshold ;
			
	--Populate ReportFilterInfo for each table--
	declare  reportCurs cursor for select A.ResTableName,A.ReportID,A.ReportType,A.EngineCallID,B.FieldName, B.CacheTypeDefID, C.LookupTableName,C.LookupFieldName,C.LookupDisplayColName,C.LookupUserCodeColName
				from @ResTblName A inner join DictCol B
					on A.ResTableName=B.TableName
					inner join CacheTypeDef C
					on B.CacheTypeDefID=C.CacheTypeDefID
					where B.CacheTypeDefID > 0
	open reportCurs
	fetch reportCurs into @resTableName,@reportID,@reportType,@engineCallID,@fieldName,@cacheTypeDefID,@lookupTableName,@lookupFieldName,@lookupDisplayName,@UserCode
	while @@fetch_status=0
	begin	
	
		if exists(select * from systemdb.sys.objects A inner join systemdb.Sys.Schemas B on A.schema_id=B.schema_id
			where   A.Name=@lookupTableName and B.Name=@systemSchema)
			set  @lookupTableName='systemdb.'+@systemSchema +'.'+@lookupTableName
			
		--Then query the main table to get the list of unique lookup ID and get the description from lookup table
		set @EBERunID=0;
		
		if @reportType=5
		begin
			set @EBERunID=-1;
			select  @ebeRunId =EBERunID from AvailableReport A inner join eltsummary B 
				on A.reportid = B.reportid
			        and A.analysisrunkey = B.analysisRunkey 
			        where A.ReportID =@reportID 
			        and  A.AnalysisRunKey =@analysisRunKey	
			if @ebeRunID>0 
			begin
				set @sql = 'insert into #Lookup (LookupId , LookupValue,UserCode)
					select distinct  A.' + @fieldName + ',B.' + @lookupDisplayName +',B.' + @UserCode + ' from ' + @resTableName + ' A inner join ' + @lookUpTableName + ' B
					on A.' + @fieldName + ' =B.' + @LookupFieldName +
		 		' and EBERunID = ' + cast(@ebeRunId as varchar(30));
		 		
		 		--exec absp_MessageEx @sql
				exec (@sql)
			end
		end
		else
		begin
			if @reportType=1 and @cacheTypeDefID=11
				set @sql = 'insert into #Lookup (LookupId,LookupValue,UserCode)
					select distinct  B.' + @LookupFieldName + ',B.' + @lookupDisplayName +',B.' + @UserCode + ' from ' + @resTableName + ' A inner join ' + @lookUpTableName + ' B
					on A.' + @fieldName + ' =B.' + @lookupDisplayName 
			else
				set @sql = 'insert into #Lookup (LookupId , LookupValue,UserCode)
					select distinct  A.' + @fieldName + ',B.' + @lookupDisplayName +',B.' + @UserCode + ' from ' + @resTableName + ' A inner join ' + @lookUpTableName + ' B
					on A.' + @fieldName + ' =B.' + @LookupFieldName 
			if @reportType=1 --ExposureReport tables have NodeKey and NodeType
				set @sql = @sql + ' and NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType= ' + cast(@nodeType as varchar(30)) + ' and EngineCallID= ' + cast(@engineCallID as varchar(30))
			else
			begin
				set @sql = @sql + ' and ' + @columnName + ' = ' + cast(@nodeKey as varchar(30));
				if @nodeType=4
					set @sql = @sql + ' and ExposureKey= ' +  cast(@exposureKey as varchar(30));
				if @nodeType=9
					set @sql = @sql + ' and Pport_Key = ' +  cast(@pportKey as varchar(30))+ ' and ExposureKey= ' +  cast(@exposureKey as varchar(30)) + ' and AccountKey=' + cast(@accountKey as varchar(30)) 
			end
			--exec absp_MessageEx @sql
			exec (@sql)
		end
		
		
		if @EBERunID<>-1
		begin
			-- For exposure report tables there are entries for multiple EngineCallID. Thus we will add <tablename>_<EngineCallID> as ReportFileterInfo.TableName for them.
			if @reportType=1 set @resTableName=@resTableName + '_' + dbo.trim(cast(@engineCallID as varchar(30)));
			
			--Fill in ReportFilterInfo table with all the relevant information.
			if @cacheTypeDefId=1 or @cacheTypeDefId=36
			begin
				--Check for duplicates--
				delete from #Lookup from #Lookup A inner join ReportFilterInfo B on A.UserCode=B.LookupId
				where TableName=@resTableName and CacheTypeDefID=@cacheTypeDefID and NodeType=@nodeType 
				and FolderKey=@folderKey and AportKey=@aportKey	and PportKey=@pportKey and ExposureKey=@exposureKey
				and AccountKey=@accountKey and PolicyKey=@policyKey and SiteKey=@siteKey and RPortKey=@rPortKey 
				and ProgramKey=@programKey and CaseKey=@caseKey;

				insert into ReportFilterInfo 
					(TableName,CacheTypeDefID,LookupID,LookupUserCode,Description,NodeType,FolderKey,AportKey,PportKey,ExposureKey,AccountKey,PolicyKey,SiteKey,RPortKey,ProgramKey,CaseKey)
				select @resTableName,@cacheTypeDefID,UserCode,LookupId, LookupValue,@nodeType,@folderKey,@aportKey,@pportKey,@exposureKey,@accountKey,@policyKey,@siteKey,@rPortKey,@programKey,@caseKey
					from #Lookup
			end
			else
			begin
				--Check for duplicates--
				delete from #Lookup from #Lookup A inner join ReportFilterInfo B on A.LookupID=B.LookupId
				where TableName=@resTableName and CacheTypeDefID=@cacheTypeDefID and NodeType=@nodeType 
				and FolderKey=@folderKey and AportKey=@aportKey	and PportKey=@pportKey and ExposureKey=@exposureKey
				and AccountKey=@accountKey and PolicyKey=@policyKey and SiteKey=@siteKey and RPortKey=@rPortKey 
				and ProgramKey=@programKey and CaseKey=@caseKey;

				insert into ReportFilterInfo 
					(TableName,CacheTypeDefID,LookupID,LookupUserCode,Description,NodeType,FolderKey,AportKey,PportKey,ExposureKey,AccountKey,PolicyKey,SiteKey,RPortKey,ProgramKey,CaseKey)
				select @resTableName,@cacheTypeDefID, LookupId,UserCode, LookupValue,@nodeType,@folderKey,@aportKey,@pportKey,@exposureKey,@accountKey,@policyKey,@siteKey,@rPortKey,@programKey,@caseKey
					from #Lookup 
			end
		end
		truncate table #Lookup
		fetch reportCurs into @resTableName,@reportId,@reportType,@engineCallID,@fieldName,@cacheTypeDefID,@lookupTableName,@lookupFieldName,@lookupDisplayName,@UserCode
	end
	close reportCurs
	deallocate reportCurs	
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch