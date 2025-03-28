if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_getNodeDisplayName') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getNodeDisplayName
end
go
create procedure absp_getNodeDisplayName @nodeDispName as varchar(1000) out, @dbName as varchar(130), @batchJobKey INT = 0, @taskKey int = 0, @analysisRunKey int = 0, @yltID int = 0, @schemaName varchar(255) = '', @downloadKey int=0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will return node displaying name of a task or a batch job given the BatchJobKey or TaskKey. 
	It will read the node type and all the keys from BatchJob or TaskInfo table to figure out the node displaying name
	including the account and site node such as pport2 : ACCT-CA-001, pport2 : ACCT-CA-001 : Site 1 ....

Returns:      node displaying name as an output variable

====================================================================================================
</pre>
</font>
##BD_END
##PD  @dbName		^^  executed database name.
##PD  @batchJobKey  ^^  batch job key (taskkey will be used if = 0)
##PD  @TaskKey		^^  task key
##PD  @analysisRunKey  ^^  analysis Run key
##PD  @yltID		^^ equivalent analysis run key for YLT run
##PD  @schemaName	^^ snapshot schema name

*/ 
begin
	set nocount on
	declare @qry as nvarchar(max)
	declare @nodeType int
	declare @folderKey int
	declare @dBRefKey int
	declare @aportKey int
	declare @pportKey int
	declare @rportKey int
	declare @programKey int
	declare @caseKey int
	declare @exposureKey int
	declare @accountKey int 
	declare @policyKey int
	declare @siteKey int
	declare @parentKey int
	declare @parentType int
	declare @rdbInfoKey int
--	declare @analysisRunKey int
	declare @jobType int
	declare @origDbName varchar(120)

	set @origDbName = @dbName
	
	if @analysisRunKey > 0 
	begin
	    if @dbName <> '' 
			set @qry = 'select @dBRefKey=Cf_Ref_Key from CFLDRINFO where LongName = ''' + @dbName + ''''
		else
			set @qry = 'select @dBRefKey=Cf_Ref_Key from CFLDRINFO where LongName = ''' +  ltrim(rtrim(DB_NAME())) + ''''
			
			execute sp_executesql @qry,N'@dBRefKey int output',@dBRefKey  output
	end	
		
	if @dbName = ''
		set @dbName = '[' + ltrim(rtrim(DB_NAME())) + ']'
	else
	begin
		if LEFT(@dbname,1) != '[' and RIGHT(@dbname,1) != ']'
			set @dbName = '[' + ltrim(rtrim(@dbName)) + ']'
	end
	
	-- figure out all the keys from batchjob or TaskInfo	
	if @batchJobKey > 0 
	begin
		select @analysisRunKey=AnalysisRunKey,@jobType=JobTypeId,@nodeType=NodeType,
		@dBRefKey=DBRefKey,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
		@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rportKey=RportKey,@programKey=ProgramKey,
		@caseKey=CaseKey,@rdbInfoKey=RdbInfoKey from commondb..BatchJob where BatchJobKey = @batchJobKey

		if @analysisRunKey > 0
		begin
			set @qry = 'select @exposureKey =ExposureKey from  ' + @dbName + '.dbo.AnalysisRunInfo where AnalysisRunKey= ' + dbo.trim(cast(@analysisRunKey as varchar(20)));
			execute sp_executesql @qry,N'@exposureKey int output',@exposureKey  output;
		end
	end 
	else if @taskKey > 0
	begin
		select @nodeType=NodeType,@dBRefKey=DBRefKey,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
		@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rportKey=RportKey,@programKey=ProgramKey,@caseKey=CaseKey,@rdbInfoKey=RdbInfoKey from commondb..Taskinfo where TaskKey = @taskKey
	end
	else if @analysisRunKey > 0
	begin
		if len(@schemaName) > 0
		begin
			set @qry = 'select @nodeType=NodeType,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,' +
						'@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rportKey=RportKey,@programKey=ProgramKey,@caseKey=CaseKey from ' + rtrim(@schemaName) + 
						'.AnalysisRunInfo where AnalysisRunKey = ' + rtrim(str(@analysisRunKey));
			execute sp_executesql @qry,N'@nodeType int output,@folderKey int output,@aportKey int output,@pportKey int output,@exposureKey int output,@accountKey int output,@policyKey int output,@siteKey int output,@rportKey int output,@programKey int output,@caseKey int output',
			@nodeType  output,@folderKey output,@aportKey output,@pportKey output,@exposureKey output,@accountKey output,@policyKey output,@siteKey output,@rportKey output,@programKey output, @caseKey output;
		end
		else
		begin
			set @qry = 'select @nodeType=NodeType,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey, ' +
			'@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rportKey=RportKey,@programKey=ProgramKey,@caseKey=CaseKey from AnalysisRunInfo where AnalysisRunKey = ' + rtrim(str(@analysisRunKey))
			execute sp_executesql @qry,N'@nodeType int output,@folderKey int output,@aportKey int output,@pportKey int output,@exposureKey int output,@accountKey int output,@policyKey int output,@siteKey int output,@rportKey int output,@programKey int output,@caseKey int output', 
			@nodeType  output,@folderKey output,@aportKey output,@pportKey output,@exposureKey output,@accountKey output,@policyKey output,@siteKey output,@rportKey output,@programKey output, @caseKey output;
		end
	end
	else if @downloadKey > 0
	begin
		select @nodeType=NodeType,@dBRefKey=DBRefKey,@folderKey=FolderKey,@aportKey=AportKey,@pportKey=PportKey,@exposureKey=ExposureKey,
		@accountKey=AccountKey,@policyKey=PolicyKey,@siteKey=SiteKey,@rportKey=RportKey,@programKey=ProgramKey,@caseKey=CaseKey,@rdbInfoKey=RdbInfoKey from commondb..DownloadInfo where DownloadKey = @downloadKey
		-- get the correct database for downloadInfo entry (downloadKey > 0)
		if @origDbName = '' set @dbName = ltrim(rtrim(DB_NAME()))
		if @rdbInfoKey > 0 
			select @dbName = SDB.name from sys.databases SDB  inner join sys.master_files SMF on SDB.database_id = SMF.database_id  where SMF.file_id = 1 and SDB.state_desc = 'online' and SDB.database_id=@dBRefKey;
		else
			select @dbName = cf.DB_NAME from commondb..CFldrInfo cf where cf.Cf_Ref_Key = @dBRefKey;
		
		if LEFT(@dbname,1) != '[' and RIGHT(@dbname,1) != ']'
			set @dbName = '[' + ltrim(rtrim(@dbName)) + ']'	
	end

	if @yltID > 0
	begin
		set @qry = 'use '+ @dbName + ' select @nodeDispName = ltrim(rtrim(longname)) from RdbInfo where RdbInfoKey = (select RdbInfoKey from YLTSummary where YLTID = '+ cast(@yltID as varchar(10))+')' 
	end
	else
	begin
		-- do the same query if node type are not account and site
		if @nodeType <> 4 and @nodeType <> 9
		begin
			if @batchJobKey > 0 and @rdbInfoKey > 0
			begin
				set @qry = 'use '+ @dbName + ' select @nodeDispName = case '+ cast(@nodeType as varchar(10)) +
				' when 101 then (select ltrim(rtrim(longname)) from RdbInfo where RdbInfoKey = '+ cast(@RdbInfoKey as varchar(10))+')' +
				' when 103 then (select ltrim(rtrim(longname)) from RdbInfo where RdbInfoKey = '+ cast(@RdbInfoKey as varchar(10))+')' +
				' end '
			end
			else
			begin
			    if @rdbInfoKey > 0 and (@taskKey > 0 or @downloadKey > 0)
					set @qry ='use '+ @dbName + ' select @nodeDispName = case '+ cast(@nodeType as varchar(10))+
					' when 102 then (select ltrim(rtrim(longname)) from RdbInfo where rdbInfoKey = '+ cast(@RdbInfoKey as varchar(10))+')' +
					' when 103 then (select ltrim(rtrim(longname)) from RdbInfo where rdbInfoKey = '+ cast(@RdbInfoKey as varchar(10))+')' +
					' end '
				else
					set @qry ='use '+ @dbName + ' select @nodeDispName = case '+ cast(@nodeType as varchar(10))+
					' when 0 then (select  ltrim(rtrim(longname)) from fldrinfo where  folder_key = '+ cast(@FolderKey as varchar(10))+ ' and curr_node=''N'')' + 
					' when 12 then (select  ltrim(rtrim(longname)) from cfldrInfo where folder_key = '+cast(@FolderKey as varchar(10)) + ' and cf_ref_key = '+ cast(@DBRefKey as varchar(10))+')' +
					' when 1 then (select  ltrim(rtrim(longname)) from AprtInfo where aport_key = '+ cast(@AportKey as varchar(10)) +')' + 
					' when 2 then (select  ltrim(rtrim(longname)) from PprtInfo where pport_key = '+ cast(@PportKey as varchar(10))+')' +
					' when 23 then (select ltrim(rtrim(longname)) from RprtInfo where rport_key = '+ cast(@RportKey as varchar(10))+')' +
					' when 27 then (select ltrim(rtrim(longname)) from ProgInfo where prog_key = '+ cast(@ProgramKey as varchar(10))+')' +
					' when 30 then (select ltrim(rtrim(longname)) from CaseInfo where case_key = '+ cast(@CaseKey as varchar(10))+')' +
					' end '	
			end		
		end
		-- node type is an account or site
		else if @nodeType = 4 or @nodeType = 9
		begin
			--Get parent from exposuremap
			set @qry = 'select @parentKey=ParentKey,@parentType=ParentType from ' + @dbName + '..ExposureMap where ExposureKey  = ' + dbo.trim(cast(@exposureKey as varchar(20)));
			execute sp_executesql @qry,N'@parentKey int output, @parentType int output',@parentKey output, @parentType output

			-- We need to check if the @parentType is null.
			-- This can happen if user deletes an Exposureset but there are Account and Site level Batch Jobs with S/F/C status.
			-- The @qry variable is used later and if @parentType is not 2 or 27 the wrong query is set and later when we try to execute
			-- the incorrect query it fails.
			
			if (isNull(@parentType, -999) = -999)
				set @qry = '';
				
			--Get parent node name where parent is a primary port
			if @parentType = 2
			begin
				if (@nodeType = 4)
				begin
					set @qry = 'select @nodeDispName =  ltrim(rtrim(a.longname)) + '' : '' + b.accountnumber from ' + @dbName + '..pprtinfo a, ' + 
					@dbName + '..account b where b.exposurekey = ' + dbo.trim(cast(@exposureKey as varchar(20))) + 
					' and b.accountKey = ' +  dbo.trim(cast(@accountKey as varchar(20))) + 
					' and a.pport_key = (select parentKey from ' + @dbName + '..exposuremap where exposurekey = ' + dbo.trim(cast(@exposureKey as varchar(20))) + ')';
					--execute sp_executesql @qry,N'@nodeDispName varchar(1000) output',@nodeDispName  output;
				end
				if (@nodeType = 9)
				begin
					if @batchJobKey > 0 
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, @batchJobKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@batchJobKey', cast(@batchJobKey as varchar(20)));
					end
					else if @taskKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, @taskKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@taskKey', cast(@taskKey as varchar(20)));
					end
					else if @analysisRunKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, 0, @analysisRunKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@analysisRunKey', cast(@analysisRunKey as varchar(20)));
					end
					else if @downloadKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, 0, 0, @downloadKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@downloadKey', cast(@downloadKey as varchar(20)));
					end
					--exec sp_executesql @qry, N'@nodeDispName varchar(400) out', @nodeDispName OUTPUT;
				end
			end
				
			--Get parent node name where parent is a program
			else if @parentType = 27
			begin
				if (@nodeType = 4)
				begin
					set @qry = 'select @nodeDispName =  a.longname + '' : '' + b.accountnumber  from ' + @dbName + '..proginfo a, ' +
					@dbName + '..account b , commondb..BatchJob c where b.exposurekey = ' + dbo.trim(cast(@exposureKey as varchar(20))) + 
					' and b.accountkey = c.accountKey and a.prog_key = (select parentKey from ' + 
					@dbName + '..exposuremap where exposurekey = ' + dbo.trim(cast(@exposureKey as varchar(20))) + ')';
					--execute sp_executesql @qry,N'@nodeDispName varchar(1000) output',@nodeDispName  output;
				end
				if (@nodeType = 9)
				begin
					if @batchJobKey > 0 
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, @batchJobKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@batchJobKey', cast(@batchJobKey as varchar(20)));
					end
					else if @taskKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, @taskKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@taskKey', cast(@taskKey as varchar(20)));
					end
					else if @analysisRunKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, 0, @analysisRunKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@analysisRunKey', cast(@analysisRunKey as varchar(20)));
					end
					else if @downloadKey > 0
					begin
						set @qry = 'exec @dbname.dbo.absp_getSiteDetail @nodeDispName output, 0, 0, 0, @downloadKey';
						set @qry = replace(@qry, '@dbname', @dbName);
						set @qry = replace(@qry, '@downloadKey', cast(@downloadKey as varchar(20)));
					end
					--exec sp_executesql @qry, N'@nodeDispName varchar(400) out', @nodeDispName OUTPUT;
				end
			end
		end
	end
  if (@qry <> '')
  begin
  exec sp_executesql @qry, N'@nodeDispName varchar(800) out', @nodeDispName OUTPUT;
  -- prefix node name with database name for download
  	if @downloadKey > 0 set @nodeDispName = @dbName + ' - ' + @nodeDispName;
  end  	
--print @qry
--Select @qry
end