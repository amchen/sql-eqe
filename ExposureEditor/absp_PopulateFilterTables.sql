if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PopulateFilterTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateFilterTables
end
 go

create procedure absp_PopulateFilterTables @nodeKey int, @nodeType int,@taskKey int, @userKey int=1,@debug int=0						
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
	declare @exposureKeyList varchar(max);
	declare @cnt int;
	declare @insertStr varchar(2000);
	declare @dbName varchar(200);
	declare @schemaname varchar(200);
	set @dbName=QUOTENAME(DB_NAME());
	declare @IsValidStr varchar(100);
	declare @stepNumber int;
	declare @cntStr varchar(max);
	declare @taskInProgress int;
	declare @procId int;
	declare @taskProgressMsg varchar(1000);
    
    set @procID = @@PROCID;
	set @IsValidStr= '';
	set @stepNumber =3;
	set @taskInProgress=0;
	
	if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records'  and FilterType='P')
	begin
		set @IsValidStr= ' and IsValid=0';
		set @taskInProgress=1
	end
	
	if not exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType)
	begin
		if @nodeType=2 and exists(select 1 from taskInfo where taskKey=@taskKey and PPortKey=@nodeKey and NodeType=@nodeType and TaskTypeID=4)
			set @taskInProgress=1
		else if  @nodeType=27 and exists(select 1 from taskInfo where taskKey=@taskKey and ProgramKey=@nodeKey and NodeType=@nodeType and TaskTypeID=4)
			set @taskInProgress=1
	end
	
	--Create a separate database schema where the temp tables can be stored. The schema name will be like FilterSchema_<NodeKey>_<NodeType>_<Batch/TaskKey>
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	if @taskInProgress=1 exec absp_Util_AddTaskProgress @taskKey, 'Create schema to store intermediate tables.', @procID;
	set @schemaName= 'FilterSchema_' + dbo.trim(cast(@nodeKey as varchar(10))) + '_' + dbo.trim(cast(@nodeType as varchar(10)))+'_'+dbo.trim(cast(@taskKey as varchar(10)));
	exec absp_Util_CleanupSchema @schemaName;
	set @sql='create schema ' + @schemaName;
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;
	
	--Get  exposure keys--
	if exists(select * from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=1 )
	begin
		select @exposureKeyList=Value from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=1 ;
		set @exposureKeyList = ' in (' + @exposureKeyList + ')'
	end
	else
		exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
   	if @exposureKeyList='' return;
   	
	set @sql = 'select ExposureMap.ExposureKey,FinancialModelType into ' + @schemaname + '.ExposureKeys from ExposureMap inner join ExposureInfo on ExposureMap.ExposureKey=ExposureInfo.ExposureKey
		where ParentKey=' + cast( @nodeKey as varchar(30)) + ' and ParentType=' + cast(@nodeType as varchar(30));
	exec(@sql);
	
	print 'Create temp tables to hold the Keys'	
	--Get Names and Numbers for Account,Policy, Site,Structure
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'select A.ExposureKey,A.AccountKey,AccountNumber,AccountName,A.FinancialModelType  into ' + @schemaname + '.AccountKeys from Account A
				where ExposureKey ' + @exposureKeyList
	exec(@sql);
	set @sql = 'create clustered index AccountKeys_I1 on  ' + @schemaname + '.AccountKeys (ExposureKey ,AccountKey )';
	exec(@sql);
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber =@stepNumber +1;
	---------------------
	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'select A.ExposureKey,A.AccountKey,A.PolicyKey,PolicyNumber,PolicyName,CurrencyCode  into ' + @schemaname + '.PolicyKeys from Policy A 
				where ExposureKey ' + @exposureKeyList
	exec(@sql);
	set @sql = 'create clustered index PolicyKeys_I1 on   ' + @schemaname + '.PolicyKeys (ExposureKey ,AccountKey,PolicyKey )';
	exec(@sql);
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber =@stepNumber +1;
	----------------------
	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'select A.ExposureKey,A.AccountKey,A.SiteKey,SiteNumber,SiteName,CurrencyCode  into ' + @schemaname + '.SiteKeys from Site A
				where ExposureKey ' + @exposureKeyList
	exec(@sql);
	set @sql = 'create clustered index SiteKeys_I1 on  ' + @schemaname + '.SiteKeys (ExposureKey ,AccountKey,SiteKey )';
	exec(@sql);
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber =@stepNumber +1;
	----------------------
	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'select A.ExposureKey,A.AccountKey,A.StructureKey,A.SiteKey,StructureNumber,StructureName,CountryCode  into ' + @schemaname + '.StructureKeys from Structure A
				 where ExposureKey ' + @exposureKeyList
	exec(@sql);
	set @sql = 'create clustered index StructureKeys_I1 on  ' + @schemaname + '.StructureKeys (ExposureKey ,AccountKey,StructureKey,SiteKey )';
	exec(@sql);
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber =@stepNumber +1;
	---------------------

	--Generate AccountFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Account table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Accounts'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
 
	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating Account Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	exec absp_GetFilteredTableName @filterTableName out, 'Account',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Accounts','Account',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Accounts','Account'					
	set @insertStr='insert into ' + @filterTableName +'(AccountRowNum, ExposureKey,AccountKey,AccountNumber,FinancialModelType)'  
	set @sql=' select AccountRowNum, Account.ExposureKey,Account.AccountKey,Account.AccountNumber,Account.FinancialModelType from ' + @dbName + '.dbo.Account  '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where Account.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated Account filter --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	
	--Generate PolicyFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Policy table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policies'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating Policy Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	exec absp_GetFilteredTableName @filterTableName out, 'Policy',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,PolicyNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policies','Policy',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policies','Policy'
	set @insertStr='insert into ' + @filterTableName + '(PolicyRowNum, ExposureKey,AccountKey, PolicyKey,AccountNumber,PolicyNumber,FinancialModelType)'  
	set @sql=' select PolicyRowNum, Policy.ExposureKey,Policy.AccountKey, Policy.PolicyKey,AccountNumber,Policy.PolicyNumber,FinancialModelType ' +
					' from ' + @dbName + '.dbo.Policy inner join ' +  @dbName + '.' + @schemaname + '.AccountKeys A on Policy.ExposureKey=A.ExposureKey and Policy.AccountKey=A.AccountKey '	
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where Policy.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)
	
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated Policy filter --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------
	
	--Generate PolicyFilter  Filter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from PolicyFilter table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policy Filters'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating PolicyFilter Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyFilter',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Filter','PolicyFilter',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Filter','PolicyFilter'	
	set @insertStr='insert into ' + @filterTableName + '(PolicyFilterRowNum,ExposureKey,AccountKey,StructureKey,StructureNumber,SiteNumber,StructureName,PolicyConditionNameKey,FinancialModelType)'  
	set @sql=' select PolicyFilter.PolicyFilterRowNum, PolicyFilter.ExposureKey,PolicyFilter.AccountKey,PolicyFilter.StructureKey,StructureNumber,SiteNumber,' +
						'StructureName,PolicyFilter.PolicyConditionNameKey, FinancialModelType ' +
					' from ' + @dbName + '.dbo.PolicyFilter  ' +
					' inner loop join  ' + @dbName + '.' +  @schemaname + '.AccountKeys A on  A.ExposureKey=PolicyFilter.ExposureKey and A.AccountKey=PolicyFilter.AccountKey ' +
					' inner loop join  ' + @dbName + '.' +  @schemaname + '.StructureKeys ST on  ST.ExposureKey=PolicyFilter.ExposureKey and ST.AccountKey=PolicyFilter.AccountKey   and ST.StructureKey=PolicyFilter.StructureKey ' +
					' inner loop join  ' + @dbName + '.' +  @schemaname + '.SiteKeys S on  S.ExposureKey=ST.ExposureKey and S.AccountKey=ST.AccountKey   and S.SiteKey=ST.SiteKey ' 
	set @sql = @sql + ' where PolicyFilter.ExposureKey ' + @exposureKeyList 
	if  @IsValidStr= ' and IsValid=0' set @sql =@sql + ' and 1=0'
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr 
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated Policy filter filter --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	----Generate PolicyConditionFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from PolicyCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Policy Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating PolicyCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyCondition',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,PolicyNumber,ConditionPriority';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Conditions','PolicyCondition',@defaultOrderBy 	
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Conditions','PolicyCondition'
	set @insertStr='insert into ' + @filterTableName + '(PolicyConditionRowNum, ExposureKey, AccountKey, PolicyKey, PolicyConditionNameKey, CSLCoverageName, AccountNumber, PolicyNumber, CurrencyCode,FinancialModelType)'  
	set @sql=' select PolicyConditionRowNum, PolicyCondition.ExposureKey,PolicyCondition.AccountKey, PolicyCondition.PolicyKey,	PolicyCondition.PolicyConditionNameKey, '''', AccountNumber, PolicyNumber,P.CurrencyCode, A.FinancialModelType'+
					' from ' + @dbName + '.dbo.PolicyCondition ' +  
					' inner loop join  ' + @dbName + '.' +@schemaname + '.PolicyKeys P  on PolicyCondition.ExposureKey=P.ExposureKey and PolicyCondition.AccountKey=P.AccountKey and PolicyCondition.PolicyKey=P.PolicyKey ' +
					' inner loop join ' + @dbName + '.' +@schemaname + '.AccountKeys A on A.ExposureKey = P.ExposureKey and A.AccountKey = P.AccountKey' +
					' and Coverorderoffshore=0'
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' where PolicyCondition.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)
	
	exec absp_GetOffShorePolicyConditionName @filterTableName,@nodeKey,@nodeType
	
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated PolicyCondition filter'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	--Generate Account ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating AccountReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	
	exec absp_GetFilteredTableName @filterTableName out, 'AccountReinsurance',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,TreatyTag.Name,LayerNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Account Reinsurance','Reinsurance',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Account Reinsurance','Reinsurance'
		
	set @insertStr='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,AccountNumber,FinancialModelType)'  
	set @sql=' select ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,AccountNumber,A.FinancialModelType ' +
					' from ' + @dbName + '.dbo.Reinsurance ' + 
					' inner loop join  ' + @dbName + '.' +@schemaname + '.AccountKeys A  on Reinsurance.ExposureKey=A.ExposureKey and Reinsurance.AccountKey=A.AccountKey '+  
					' inner loop join ' + @dbName + '.dbo.TreatyTag  on TreatyTag.TreatyTagID = Reinsurance.TreatyTagID ' +
					' where TreatyType <>''F'' and Reinsurance.AppliesTo =''A'' '	 
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and Reinsurance.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated AccountRein filter --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	--Generate Policy ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating PolicyReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	exec absp_GetFilteredTableName @filterTableName out, 'PolicyReinsurance',@nodeKey,@nodeType,@userKey
	--For Policy (Fac records)--
	set @defaultOrderBy = 'AccountNumber,PolicyNumber,Certificate';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Policy Reinsurance','Reinsurance',@defaultOrderBy
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Policy Reinsurance','Reinsurance' 
	set @insertStr='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,PolicyKey,AccountNumber,PolicyNumber,FinancialModelType)'  
	set @sql=' select Reinsurance.ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,Reinsurance.PolicyKey,AccountNumber,PolicyNumber,A.FinancialModelType ' +
					' from ' + @dbName + '.dbo.Reinsurance ' +
					' inner loop join  ' +@dbName + '.' + @schemaname + '.PolicyKeys P  on Reinsurance.ExposureKey=P.ExposureKey and Reinsurance.AccountKey=P.AccountKey and Reinsurance.PolicyKey = P.PolicyKey ' +
					' inner loop join  ' + @dbName + '.' +@schemaname + '.AccountKeys A   on A.ExposureKey = P.ExposureKey and A.AccountKey = P.AccountKey '+
					' inner loop join '+@dbName + '.dbo.TreatyTag  on TreatyTag.TreatyTagID = Reinsurance.TreatyTagID ' +
					' where Reinsurance.AppliesTo =''P''  ' -- and TreatyType =''F'' 	 
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and Reinsurance.ExposureKey ' + @exposureKeyList	 + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated PolicyRein filter  --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------


	--Generate Site ReinsuranceFilter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Reinsurance table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Reinsurance Entries'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating SiteReinsurance Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	
	
	exec absp_GetFilteredTableName @filterTableName out, 'SiteReinsurance',@nodeKey,@nodeType,@userKey
	--For Site (Fac records)--
	set @defaultOrderBy = 'AccountNumber,SiteNumber,Certificate';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Site Reinsurance','Reinsurance',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Site Reinsurance','Reinsurance' 
	set @insertStr='insert into ' + @filterTableName + '(ReinsuranceRowNum,ExposureKey,AccountKey,SiteKey,AccountNumber,SiteNumber,FinancialModelType)'  
	set @sql=' select  Reinsurance.ReinsuranceRowNum,Reinsurance.ExposureKey,Reinsurance.AccountKey,Reinsurance.SiteKey,AccountNumber,SiteNumber,A.FinancialModelType ' +
		' from ' + @dbName + '.dbo.Reinsurance ' + 
		' inner loop join  ' + @dbName + '.' + @schemaname + '.SiteKeys S  on S.ExposureKey = Reinsurance.ExposureKey and S.AccountKey = Reinsurance.AccountKey and S.SiteKey = Reinsurance.SiteKey ' +
		' inner loop join  ' + @dbName + '.' + @schemaname + '.AccountKeys A  on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey '+
		' inner loop join  ' + @dbName + '.dbo.TreatyTag  on TreatyTag.TreatyTagID = Reinsurance.TreatyTagID ' +
		' where AppliesTo =''S''  ' 	 
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and Reinsurance.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)
	
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '-- Populated SiteRein filter --'
	end
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	----Generate SiteCondition Filter table--
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from SiteCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Site Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;
	
	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating SiteCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	
	exec absp_GetFilteredTableName @filterTableName out, 'SiteCondition',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber,SiteNumber,ConditionPriority';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Site Conditions','SiteCondition',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Site Conditions','SiteCondition' 
	set @insertStr='insert into ' + @filterTableName + '(SiteConditionRowNum,ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType)'  
	set @sql=' select SiteConditionRowNum,SiteCondition.ExposureKey,SiteCondition.AccountKey, SiteCondition.SiteKey, 0,AccountNumber,SiteNumber,'''',SiteName,'''',S.CurrencyCode,A.FinancialModelType ' +
			' from ' + @dbName + '.dbo.SiteCondition ' + 
			' inner loop join  ' + @dbName + '.' + @schemaname + '.SiteKeys S  on S.ExposureKey = SiteCondition.ExposureKey and S.AccountKey = SiteCondition.AccountKey and S.SiteKey =SiteCondition.SiteKey ' +
	        ' inner loop join  ' +@dbName + '.' +  @schemaname + '.AccountKeys A  on A.ExposureKey =S.ExposureKey and A.AccountKey = S.AccountKey '+
			' and SiteCondition.StructureKey=0 ' 
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and SiteCondition.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)
	
	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '--- Populated SiteCondition filter --'
	end	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	----Generate StructureCondition Filter  --
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from SiteCondition table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Site Conditions'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;	

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating StructureCondition Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	
	exec absp_GetFilteredTableName @filterTableName out, 'StructureCondition',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber, ConditionPriority';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Conditions','SiteCondition',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Conditions','SiteCondition'
	set @insertStr='insert into ' + @filterTableName + '(SiteConditionRowNum,ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType)'
	set @sql =' select SiteConditionRowNum,SiteCondition.ExposureKey,SiteCondition.AccountKey, SiteCondition.SiteKey, SiteCondition.StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,S.Currencycode,A.FinancialModelType ' +
	                  ' from ' + @dbName + '.dbo.SiteCondition ' +
	                  ' inner loop join  ' + @dbName + '.' + @schemaname + '.StructureKeys ST on ST.ExposureKey = SiteCondition.ExposureKey and ST.AccountKey = SiteCondition.AccountKey and ST.SiteKey =SiteCondition.SiteKey and ST.StructureKey = SiteCondition.StructureKey ' +
	                  ' inner loop join  ' + @dbName + '.' + @schemaname + '.SiteKeys S  on S.ExposureKey = ST.ExposureKey and S.AccountKey = ST.AccountKey and S.SiteKey =ST.SiteKey ' +
	                  ' inner loop join  ' + @dbName + '.' + @schemaname + '.AccountKeys A  on A.ExposureKey =sT.ExposureKey and A.AccountKey = ST.AccountKey '+       
                  ' and SiteCondition.StructureKey > 0 '
                  
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and SiteCondition.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '--- Populated StructureCondition filter --'
	end	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------
	
	------Generate Structure Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from Structure table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structures'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating Structure Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end
	exec absp_GetFilteredTableName @filterTableName out, 'Structure',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structures','Structure',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structures','Structure'
	set @insertStr='insert into ' + @filterTableName + '(StructureRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,FinancialModelType)'  
	set @sql =' select StructureRowNum ,Structure.ExposureKey,Structure.AccountKey, Structure.SiteKey, Structure.StructureKey,AccountNumber,SiteNumber,StructureNumber,A.FinancialModelType ' +
			' from ' + @dbName + '.dbo.Structure ' + 
			' inner loop join  ' + @dbName + '.' + @schemaname + '.SiteKeys S  on S.ExposureKey = Structure.ExposureKey and S.AccountKey = Structure.AccountKey and S.SiteKey = Structure.SiteKey ' +
			' inner loop join  ' + @dbName + '.' + @schemaname + '.AccountKeys A   on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and Structure.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '--- Populated Structure filter --'
	end	
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------
	
	------Generate StructureCoverage Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from StructureCoverage table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structure Coverages'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0	
		set @taskProgressMsg = 'Generating StructureCoverage Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	
	exec absp_GetFilteredTableName @filterTableName out, 'StructureCoverage',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber, StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Coverages','StructureCoverage',@defaultOrderBy
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Coverages','StructureCoverage'
	set @insertStr='insert into ' + @filterTableName + '(StructureCoverageRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,FinancialModelType)'  
	set @sql =' select StructureCoverageRowNum ,StructureCoverage.ExposureKey,StructureCoverage.AccountKey, StructureCoverage.SiteKey, StructureCoverage.StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,S.CurrencyCode,A.FinancialModelType '+
			' from ' + @dbName + '.dbo.StructureCoverage '+
			' inner loop join  ' + @dbName + '.' + @schemaname + '.StructureKeys ST  on ST.ExposureKey=StructureCoverage.ExposureKey and ST.AccountKey=StructureCoverage.AccountKey and ST.SiteKey = StructureCoverage.SiteKey  and ST.StructureKey=StructureCoverage.StructureKey ' +
			' inner loop join  ' + @dbName + '.' + @schemaname + '.SiteKeys S  on S.ExposureKey = ST.ExposureKey and S.AccountKey = ST.AccountKey and S.SiteKey = ST.SiteKey ' +
			' inner loop join  ' + @dbName + '.' + @schemaname + '.AccountKeys A  on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and StructureCoverage.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '--- Populated StructureCoverage filter --'
	end			
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	------Generate StructureFeature Filter table--	
	set @sql='select @cntStr=''Processing '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' '' + replace(StatLabel,''Number of'','''') 
				+ '' records from StructureFeature table to match the filter criteria. ''  
			from ImportStatReport 
			where StatLabel = ''Number of Structure Features'' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output

	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
		set @taskProgressMsg = 'Generating StructureFeature Filter table for NodeKey= ' + cast(@nodeKey as varchar(30)) + ' and NodeType = '+ cast(@nodeType as varchar(30)) ;
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	
	exec absp_GetFilteredTableName @filterTableName out, 'StructureFeature',@nodeKey,@nodeType,@userKey
	set @defaultOrderBy = 'AccountNumber, SiteNumber,StructureNumber';
	exec absp_GenerateExposureOrderByClause @orderByClause output,@nodeKey, @nodeType,'Structure Features','StructureFeature',@defaultOrderBy 
	exec absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr output, @nodeKey, @nodeType,'Structure Features','StructureFeature'
	set @insertStr='insert into ' + @filterTableName + '(StructureFeatureRowNum ,ExposureKey,AccountKey, SiteKey, StructureKey,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CountryCode,FinancialModelType)'  
	set @sql =' select StructureFeatureRowNum ,StructureFeature.ExposureKey,StructureFeature.AccountKey, StructureFeature.SiteKey, StructureFeature.StructureKey,AccountNumber,' +
			' SiteNumber,StructureNumber,SiteName,StructureName,ST.CountryCode,A.FinancialModelType ' +
			' from ' + @dbName + '.dbo.StructureFeature ' + 
			' inner loop join ' + @dbName + '.' + @schemaname + '.StructureKeys ST on ST.ExposureKey=StructureFeature.ExposureKey and ST.AccountKey=StructureFeature.AccountKey and ST.SiteKey = StructureFeature.SiteKey  and ST.StructureKey=StructureFeature.StructureKey '+
			' inner loop join ' + @dbName + '.' + @schemaname + '.SiteKeys  S on S.ExposureKey = ST.ExposureKey and S.AccountKey = ST.AccountKey and S.SiteKey = ST.SiteKey '+
			' inner loop join ' + @dbName + '.' + @schemaname + '.AccountKeys A on A.ExposureKey = S.ExposureKey and A.AccountKey = S.AccountKey '
	if  len(@innerJoinStr)>0 set @sql = @sql + @innerJoinStr
	set @sql = @sql + ' and StructureFeature.ExposureKey ' + @exposureKeyList + @IsValidStr
	set @sql = @insertStr+@sql
	if len(@orderByClause)>0 	set @sql = @sql + ' order by ' + @orderByClause
	exec absp_MessageEx @sql
	exec (@sql)

	if @debug=1
	begin
		exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';
		print @createDt + '--- Populated StructureFeature filter --'
	end		
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,@cntStr,0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

	--drop schema--
	if @taskInProgress=1 
	begin
		exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
		set @taskProgressMsg = 'Cleanup schema.'
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	end	

	execute absp_Util_CleanupSchema @schemaName
	if @taskInProgress=1  exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber =@stepNumber +1;
	-------------------------------

end
