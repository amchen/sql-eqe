if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PopulateFilterTablesWithFilteredData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateFilterTablesWithFilteredData
end
 go

create procedure absp_PopulateFilterTablesWithFilteredData @nodeKey int, @nodeType int, @taskKey int,@userKey int=1,@debug int=0						
as
begin
	set nocount on
	
	declare @sql nvarchar(max);
	declare @colList varchar(max);
	declare @filterTableName varchar(200);
	declare @defaultOrderBy varchar(max);
	declare @orderByClause varchar(max);
	declare @innerJoinStr varchar(max);
	declare @createDt varchar(25);
	declare @FilterKeysTableName varchar(200);
	declare @schemaName varchar(100);
	declare @taskProgressMsg varchar(2000);
	declare @procID int;
	declare @recordFilter varchar(50); 
	declare @exposureKeyList varchar(max);
   	declare @stepNumber int;
   	declare @cntStr varchar(max);
   	
   	set @procID = @@PROCID;
   	set @stepNumber=3;
   	
   	
   	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
   	if @exposureKeyList='' return;
	
	--ExposureBrowserData is being regenerated--
	 exec absp_InfoTableAttribSetBrowserDataRegenerate @nodeType,@nodeKey,1 
	 exec absp_InfoTableAttribSetBrowserFindReplFail @nodeType,@nodeKey,0 
	 exec absp_InfoTableAttribSetBrowserFindReplCancel @nodeType,@nodeKey,0 
	 
	--Create a separate database schema where the temp tables can be stored. The schema name will be like FilterSchema_<NodeKey>_<NodeType>_<Batch/TaskKey>
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	if @debug=1 exec absp_MessageEx 'Create a new database schema..';
	set @schemaName= 'FilterSchema_' + dbo.trim(cast(@nodeKey as varchar(10))) + '_' + dbo.trim(cast(@nodeType as varchar(10)))+'_'+dbo.trim(cast(@taskKey as varchar(10)));
	exec absp_Util_CleanupSchema @schemaName;
	set @sql='create schema ' + @schemaName;
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;
	 
	-- Add a task progress message
	set @taskProgressMsg = 'Generating temporary schema tables for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	exec absp_PopulateSchemaTablesWithFilteredData @schemaName, @nodeKey, @nodeType,0,@debug,@taskKey
	
	--Get RecordFilter--
	--------------------------
	set @recordFilter=''
	select @recordFilter=Value from ExposureDataFilterInfo A 
			inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID
			where Category='RecordFilter' and NodeKey=@NodeKey and NodeType=@nodeType and FilterType =  'P' 		
	select @recordFilter = Case @recordFilter
	when 'Valid Records'  then  'IsValid =1 '
	when 'Invalid Records'  then  'IsValid =0 '
	else ''
	end	
	
	--Generate AccountFilter table--
	set @stepNumber=12;

	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Account table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Accounts'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
	set @taskProgressMsg = 'Generating Account Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	exec absp_GetFilteredTableName @filterTableName out, 'Account',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber';
	set @FilterKeysTableName=@schemaName + '.AccountKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Accounts','Account',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output,@nodeKey, @nodeType,'Accounts','Account'	
	set @sql='insert into ' + @filterTableName +'(AccountRowNum, ExposureKey,AccountKey,AccountNumber,FinancialModelType)'  +
		' select AccountRowNum, Account.ExposureKey,Account.AccountKey,Account.AccountNumber,Account.FinancialModelType from Account  
		 inner loop join ' + @FilterKeysTableName + 	' F on Account.ExposureKey= F.ExposureKey and Account.AccountKey=F.AccountKey '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where Account.ExposureKey ' + @exposureKeyList
	--Add Record filter--
	if @recordFilter<>'' set @sql = @sql + ' and Account.' + @recordFilter
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	
	if @debug=1
	begin		
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in Account filter'
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	--Generate PolicyFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Policy table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policies'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating Policy Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	exec absp_GetFilteredTableName @filterTableName out, 'Policy',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, PolicyNumber';
	set @FilterKeysTableName=@schemaName + '.PolicyKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policies','Policy',@defaultOrderBy 	
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policies','Policy'
	set @sql='insert into ' + @filterTableName + '(PolicyRowNum, ExposureKey,AccountKey, PolicyKey,AccountNumber,PolicyNumber,FinancialModelType)'  +
		' select PolicyRowNum, Policy.ExposureKey,Policy.AccountKey, Policy.PolicyKey,AccountNumber,Policy.PolicyNumber,A.FinancialModelType 
					from Policy inner loop join ' + @FilterKeysTableName +' F on Policy.ExposureKey= F.ExposureKey and Policy.AccountKey=F.AccountKey and Policy.PolicyKey=F.PolicyKey  '
					+ ' inner loop join  ' + @schemaName + '.FinalAccountKeys A  on Policy.ExposureKey=A.ExposureKey and Policy.AccountKey=A.AccountKey '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where Policy.ExposureKey ' + @exposureKeyList
	if @recordFilter<>'' set @sql = @sql + ' and Policy.' + @recordFilter
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in Policy filter'
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------

--	--Generate PolicyFilter  Filter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from PolicyFilter table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policy Filters'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating PolicyFilter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyFilter',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,StructureNumber';
	set @FilterKeysTableName=@schemaName + '.PolicyFilterKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Filter','PolicyFilter',@defaultOrderBy 	
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Filter','PolicyFilter'
	set @sql='insert into ' + @filterTableName + '(PolicyFilterRowNum,ExposureKey,AccountKey,StructureKey,StructureNumber,SiteNumber,StructureName,PolicyConditionNameKey,FinancialModelType)'  +
				' select F.PolicyFilterRowNum, F.ExposureKey,F.AccountKey,F.StructureKey,StructureNumber,SiteNumber,StructureName,F.PolicyConditionNameKey,A.FinancialModelType 
					from  ' + @FilterKeysTableName +' F ' +
					' inner loop join ' + @schemaName + '.FinalAccountKeys A   on F.ExposureKey=A.ExposureKey and F.AccountKey=A.AccountKey ' +
					' inner loop join ' + @schemaName + '.FinalStructureKeys ST   on  ST.ExposureKey=F.ExposureKey and ST.AccountKey=F.AccountKey   and ST.StructureKey=F.StructureKey'+
					' inner loop  join ' + @schemaName + '.FinalSiteKeys S   on  S.ExposureKey=ST.ExposureKey and S.AccountKey=ST.AccountKey   and S.SiteKey=ST.SiteKey'					 				 	
	 if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where A.ExposureKey ' + @exposureKeyList
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in Policy filter'
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	----Generate PolicyConditionFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from PolicyCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policy Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating PolicyCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyCondition',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, PolicyNumber, ConditionPriority';
	set @FilterKeysTableName=@schemaName + '.PolicyConditionKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Conditions','PolicyCondition',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Conditions','PolicyCondition'
	
	set @sql='insert into ' + @filterTableName + '(PolicyConditionRowNum,ExposureKey,AccountKey,PolicyKey,AccountNumber,PolicyNumber,PolicyConditionNameKey,CSLCoverageName,CurrencyCode,FinancialModelType)'  +
				' select PolicyCondition.PolicyConditionRowNum,PolicyCondition.ExposureKey,PolicyCondition.AccountKey,PolicyCondition.PolicyKey,AccountNumber,PolicyNumber,PolicyCondition.PolicyConditionNameKey,'''',P.CurrencyCode,A.FinancialModelType
					from PolicyCondition  
					inner loop join ' + @FilterKeysTableName +' F on PolicyCondition.PolicyConditionRowNum= F.PolicyConditionRowNum  '+
					'inner loop join  ' + @schemaName + '.FinalPolicyKeys P  on PolicyCondition.ExposureKey=P.ExposureKey and PolicyCondition.AccountKey=P.AccountKey and PolicyCondition.PolicyKey=P.PolicyKey
					inner loop join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey = P.ExposureKey and A.AccountKey = P.AccountKey and Coverorderoffshore=0'
    if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
    set @sql = @sql + ' where A.ExposureKey ' + @exposureKeyList
    if @recordFilter<>'' set @sql = @sql + ' and PolicyCondition.' + @recordFilter
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	
	exec absp_GetOffShorePolicyConditionName @filterTableName,@nodeKey,@nodeType
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in PolicyCondition filter'
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	--Generate Account ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating AccountReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	exec absp_GetFilteredTableName @filterTableName out, 'AccountReinsurance',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, TrtyTag.Name, LayerNumber';
	set @FilterKeysTableName=@schemaName + '.AccountReinsuranceKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Account Reinsurance','Reinsurance',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Account Reinsurance','Reinsurance'
	set @sql='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,AccountNumber,FinancialModelType)'  +
				' select Reinsurance.ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,AccountNumber,A.FinancialModelType
					from Reinsurance  inner loop join ' + @FilterKeysTableName +' F on Reinsurance.ReinsuranceRowNum= F.ReinsuranceRowNum '+
					' inner loop join ' + @schemaName + '.FinalAccountKeys A  on Reinsurance.ExposureKey=A.ExposureKey and Reinsurance.AccountKey=A.AccountKey  
					inner loop join TreatyTag  TrtyTag on TrtyTag.TreatyTagID = Reinsurance.TreatyTagID
					and TreatyType <>''F'' and Reinsurance.AppliesTo =''A'' '	
	 if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr	
	 set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList
	 
	if @recordFilter<>'' set @sql = @sql + ' and Reinsurance.' + @recordFilter			
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in AccountRein filter '
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------

	--Generate Policy ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating PolicyReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;	
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyReinsurance',@nodeKey,@nodeType,@userKey	
	set @defaultOrderBy = 'AccountNumber, PolicyNumber, Certificate';
	set @FilterKeysTableName=@schemaName + '.PolicyReinsuranceKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Reinsurance','Reinsurance',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Reinsurance','Reinsurance' 
	
		set @sql='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,PolicyKey,AccountNumber,PolicyNumber,FinancialModelType)'  +
				' select Reinsurance.ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,Reinsurance.PolicyKey,AccountNumber,PolicyNumber,A.FinancialModelType
					from Reinsurance 
					inner loop join ' + @FilterKeysTableName +' F on Reinsurance.ReinsuranceRowNum= F.ReinsuranceRowNum '+
					' inner loop join ' + @schemaName + '.FinalPolicyKeys P  on Reinsurance.ExposureKey=P.ExposureKey and Reinsurance.AccountKey=P.AccountKey and Reinsurance.PolicyKey = P.PolicyKey
					inner loop join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey = P.ExposureKey and A.AccountKey = P.AccountKey
					inner loop join TreatyTag TrtyTag on TrtyTag.TreatyTagID = Reinsurance.TreatyTagID
					and Reinsurance.AppliesTo =''P''  ' -- and TreatyType =''F'' 	
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList	
	if @recordFilter<>'' set @sql = @sql + ' and Reinsurance.' + @recordFilter			
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin		
		exec absp_Util_GetDateString
		@createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in PolicyRein filter '
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	--Generate Site ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating SiteReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	exec absp_GetFilteredTableName @filterTableName out, 'SiteReinsurance',@nodeKey,@nodeType,@userKey
	set @FilterKeysTableName=@schemaName + '.SiteReinsuranceKeys';

	set @defaultOrderBy = 'AccountNumber, SiteNumber, Certificate';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Site Reinsurance','Reinsurance',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Site Reinsurance','Reinsurance' 
	
		set @sql='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,SiteKey,AccountNumber,SiteNumber,FinancialModelType)'  +
		' select  Reinsurance.ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,Reinsurance.SiteKey,AccountNumber,SiteNumber,A.FinancialModelType
		from Reinsurance   inner loop join ' + @FilterKeysTableName +' F on Reinsurance.ReinsuranceRowNum= F.ReinsuranceRowNum '+
		'inner loop join  ' + @schemaName + '.FinalSiteKeys S   on S.ExposureKey = Reinsurance.ExposureKey and S.AccountKey =Reinsurance.AccountKey and S.SiteKey = Reinsurance.SiteKey
		inner loop join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey = F.ExposureKey and A.AccountKey = F.AccountKey
		inner loop join TreatyTag  TrtyTag on TrtyTag.TreatyTagID = Reinsurance.TreatyTagID
		and AppliesTo =''S''  ' -- and TreatyType =''F''	 
	set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList
	if @recordFilter<>'' set @sql = @sql + ' and Reinsurance.' + @recordFilter		
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in SiteRein filter '
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------

	----Generate SiteCondition Filter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from SiteCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Site Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating SiteCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	exec absp_GetFilteredTableName @filterTableName out, 'SiteCondition',@nodeKey,@nodeType,@userKey
	set @FilterKeysTableName=@schemaName + '.SiteConditionKeys';
	set @defaultOrderBy = 'AccountNumber, SiteNumber, ConditionPriority';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Site Conditions','SiteCondition',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Site Conditions','SiteCondition' 
		set @sql='insert into ' + @filterTableName + '(SiteConditionRowNum,ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType)'  +
			' select SiteCondition.SiteConditionRowNum,SiteCondition.ExposureKey,SiteCondition.AccountKey, SiteCondition.SiteKey, 0,AccountNumber,SiteNumber,'''',SiteName,'''',S.CurrencyCode,A.FinancialModelType
			from SiteCondition   inner loop join ' + @FilterKeysTableName +' F on SiteCondition.SiteConditionRowNum= F.SiteConditionRowNum  '+
			' inner loop join ' + @schemaName + '.FinalSiteKeys S   on S.ExposureKey = SiteCondition.ExposureKey and S.AccountKey = SiteCondition.AccountKey and S.SiteKey =SiteCondition.SiteKey
	        inner loop join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey =F.ExposureKey and A.AccountKey = F.AccountKey    
			and SiteCondition.StructureKey=0 ' 
		set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList
	if @recordFilter<>'' set @sql = @sql + ' and SiteCondition.' + @recordFilter	
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in SiteCondition filter '
	end	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------

	----Generate StructureCondition Filter  --
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from SiteCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Site Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating StructureCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	exec absp_GetFilteredTableName @filterTableName out, 'StructureCondition',@nodeKey,@nodeType,@userKey
	set @FilterKeysTableName=@schemaName + '.StructureConditionKeys';
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber, ConditionPriority';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Conditions','SiteCondition',@defaultOrderBy 
		exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Conditions','SiteCondition'
		set @sql='insert into ' + @filterTableName + '(SiteConditionRowNum,ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType) 
	                   select SiteCondition.SiteConditionRowNum,SiteCondition.ExposureKey,SiteCondition.AccountKey, SiteCondition.SiteKey,  SiteCondition.StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,S.CurrencyCode,A.FinancialModelType
	                  from  SiteCondition  inner loop join ' + @FilterKeysTableName +' F on SiteCondition.SiteConditionRowNum= F.SiteConditionRowNum '+
	                  ' inner loop join  ' + @schemaName + '.FinalStructureKeys ST   on ST.ExposureKey = SiteCondition.ExposureKey and ST.AccountKey =  SiteCondition.AccountKey and ST.SiteKey = SiteCondition.SiteKey and ST.StructureKey =  SiteCondition.StructureKey
	                  inner loop join  ' + @schemaName + '.FinalSiteKeys S  on S.ExposureKey = ST.ExposureKey and S.AccountKey = ST.AccountKey and S.SiteKey =ST.SiteKey
	                  inner loop  join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey =F.ExposureKey and A.AccountKey = F.AccountKey                         
                  and SiteCondition.StructureKey > 0 '
      set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList
     if @recordFilter<>'' set @sql = @sql + ' and SiteCondition.' + @recordFilter             
	 if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in StructureCondition filter '
	end	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------

	------Generate Structure Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Structure table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structures'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating Structure Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	exec absp_GetFilteredTableName @filterTableName out, 'Structure',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber';
	set @FilterKeysTableName=@schemaName + '.StructureKeys';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structures','Structure',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structures','Structure'
	
	set @sql='insert into ' + @filterTableName + '(StructureRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,FinancialModelType)'  +
			' select Structure.StructureRowNum ,Structure.ExposureKey,Structure.AccountKey, Structure.SiteKey, Structure.StructureKey,AccountNumber,SiteNumber,StructureNumber,A.FinancialModelType
			from Structure    inner loop join ' + @FilterKeysTableName +' F on Structure.ExposureKey= F.ExposureKey and Structure.AccountKey=F.AccountKey and Structure.StructureKey=F.StructureKey and Structure.SiteKey=F.SiteKey '+
			' inner loop join  ' + @schemaName + '.FinalSiteKeys S  on S.ExposureKey = Structure.ExposureKey and S.AccountKey = Structure.AccountKey and S.SiteKey = Structure.SiteKey
			inner loop join  ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey = F.ExposureKey and A.AccountKey = F.AccountKey'
	 if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	 set @sql = @sql + ' where A.ExposureKey ' + @exposureKeyList
	 if @recordFilter<>'' set @sql = @sql + ' and Structure.' + @recordFilter		
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in Structure filter '
	end	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	------Generate StructureCoverage Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from StructureCoverage table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structure Coverages'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating StructureCoverage Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	set @FilterKeysTableName=@schemaName + '.StructureCoverageKeys';
	exec absp_GetFilteredTableName @filterTableName out, 'StructureCoverage',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Coverages','StructureCoverage',@defaultOrderBy 
		exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Coverages','StructureCoverage'
	
		set @sql='insert into ' + @filterTableName + '(StructureCoverageRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType)'  +
			' select StructureCoverage.StructureCoverageRowNum ,StructureCoverage.ExposureKey,StructureCoverage.AccountKey, StructureCoverage.SiteKey, StructureCoverage.StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,S.CurrencyCode,A.FinancialModelType
			from  StructureCoverage   inner loop join ' + @FilterKeysTableName +' F on StructureCoverage.StructureCoverageRowNum= F.StructureCoverageRowNum '+
			' inner loop join ' + @schemaName + '.FinalStructureKeys ST  on ST.ExposureKey=F.ExposureKey and ST.AccountKey=F.AccountKey  and ST.StructureKey=F.StructureKey and ST.SiteKey = F.SiteKey
			inner loop join ' + @schemaName + '.FinalSiteKeys S  on S.ExposureKey = ST.ExposureKey and S.AccountKey = ST.AccountKey and S.SiteKey = ST.SiteKey
			inner loop join ' + @schemaName + '.FinalAccountKeys A  on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey'
	 if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr	
	 set @sql = @sql + ' where A.ExposureKey ' + @exposureKeyList
	 if @recordFilter<>'' set @sql = @sql + ' and StructureCoverage.' + @recordFilter			
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin

		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in StructureCoverage filter '
	end			
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	------Generate StructureFeature Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from StructureFeature table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structure Features'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	set @taskProgressMsg = 'Generating StructureFeature Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
	set @FilterKeysTableName=@schemaName + '.StructureFeatureKeys';
	exec absp_GetFilteredTableName @filterTableName out, 'StructureFeature',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber,StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Features','StructureFeature',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Features','StructureFeature'
	set @sql='insert into ' + @filterTableName + '(StructureFeatureRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CountryCode,FinancialModelType)'  +
			' select StructureFeature.StructureFeatureRowNum ,StructureFeature.ExposureKey,StructureFeature.AccountKey, StructureFeature.SiteKey, StructureFeature.StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,ST.CountryCode,FinancialModelType
			from  StructureFeature  inner loop join  ' + @FilterKeysTableName +' F on StructureFeature.StructureFeatureRowNum= F.StructureFeatureRowNum '+
			' inner loop join ' + @schemaName + '.FinalStructureKeys ST   on ST.ExposureKey=F.ExposureKey and ST.AccountKey=F.AccountKey and ST.StructureKey=F.StructureKey and St.SiteKey=F.SiteKey
			inner loop join ' + @schemaName + '.FinalSiteKeys S  on S.ExposureKey = St.ExposureKey and S.AccountKey = St.AccountKey and S.SiteKey = St.SiteKey
			inner loop join ' + @schemaName + '.FinalAccountKeys A on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey'
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr	
	 set @sql = @sql + ' where A.ExposureKey ' + @exposureKeyList
	if @recordFilter<>'' set @sql = @sql + ' and StructureFeature.' + @recordFilter			
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause;
	exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql)
	if @debug=1
	begin		
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '---->Inserted in StructureFeature filter '
	end		
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber=@stepNumber +1;
	-------------------------------------------------
	
	-- Add a task progress message-
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	set @taskProgressMsg = 'Dropping schema';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;	
	--drop schema--
	execute absp_Util_CleanupSchema @schemaName
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	-------------------------------------------------
	
end
