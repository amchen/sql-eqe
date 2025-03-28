if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PopulateSchemaTablesWithFilteredData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateSchemaTablesWithFilteredData
end
 go

create procedure absp_PopulateSchemaTablesWithFilteredData @schemaName varchar(100),@nodeKey int, @nodeType int	,@replaceFlag int =0, @debug int=0, @taskKey int=-1				
as
begin
	set nocount on;
	
	declare @whereClause varchar(max);
	declare @sql varchar(max);
	declare @category varchar(120);
	declare @tableName varchar(120);
	declare @categoryOrder int;
	declare @subCategoryTable varchar(120);
	declare @subCategory varchar(120);
	declare @joinTableName varchar(120);
	declare @keyList varchar(4000);
	declare @keyList1 varchar(4000);
	declare @keyList2 varchar(4000);
	declare @categoryTable varchar(120);
	declare @tName varchar(120);
	declare @colList varchar(4000);
	declare @joinClause varchar(8000);
	declare @KeyStr varchar(50);
	declare @financialModelType varchar(2);
	declare @exposureKey varchar(30);
	declare @recordFilter varchar(20);
	declare @structureFilterDefined int;
	declare @policyFilterDefined int;
	declare @siteFilterDefined int;
	declare @pcFilterDefined int;
	declare @t varchar(120);
	declare @exposureKeyList varchar(max);
	declare @taskProgressMsg varchar(2000);
	declare @procID int;
	declare @FilterDefined int;
	declare @stepNumber int;
	set @FilterDefined=0
			
	set @structureFilterDefined = 0;
	set @policyFilterDefined = 0;
	set @siteFilterDefined = 0;
	set @pcFilterDefined = 0;
	set @procID = @@PROCID;
	set @stepNumber=4;

	--Get RecordFilter--
	--------------------------
	set @recordFilter=''
	select @recordFilter=Value from ExposureDataFilterInfo A 
			inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID
			where Category='RecordFilter' and NodeKey=@NodeKey and NodeType=@nodeType and FilterType = case when @replaceFlag=0 then 'P' else 'G' end		
	select @recordFilter = Case @recordFilter
	when 'Valid Records'  then  ' IsValid =1 '
	when 'Invalid Records'  then  ' IsValid =0 '
	else ''
	end

	--Create AccountKey table in schema--
	--------------------------------------
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @categoryTable=@schemaName + '.AccountKeys';
	print ''
	print 'Get Accounts'
	print '============'
	set @sql='create table ' + @schemaName + '.AccountKeys (ExposureKey int,AccountKey int);'
	if @debug=1	 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql);


	--Generate whereClause--
	------------------------
	exec absp_GenerateExposureWhereClause @whereClause out, @nodeKey, @nodeType,'Accounts','Account',@replaceFlag

	--For ExposureKey of the given node--
	set @sql = 'insert into '+@schemaName + '.AccountKeys'+
			' select  A.ExposureKey,A.AccountKey from Account A inner join ExposureMap B  on A.ExposureKey=B.ExposureKey
			where B.ParentKey= ' + cast(@nodeKey as varchar(30)) + ' and B.ParentType=' + cast (@nodeType as varchar(10)); 

	--Add Record filter--
	if @recordFilter<>'' set @sql = @sql + ' and ' + @recordFilter

	--Get FinancialModelTypeFilter--
	--------------------------------
	set @financialModelType=''
	select @financialModelType=Value from ExposureDataFilterInfo A 
			inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID
			where Category='FinancialModelFilter' and NodeKey=@NodeKey and NodeType=@nodeType and FilterType = case when @replaceFlag=0 then 'P' else 'G' end	 	

	if @financialModelType<>''
		set @sql = @sql + ' and A.FinancialModelType =' + @financialModelType;

	--Get ExposureSetFilter--
	-------------------------------
	set @exposureKey=''
	select @exposureKey=Value from ExposureDataFilterInfo A 
			inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID
			where Category='ExposureSetFilter' and NodeKey=@NodeKey and NodeType=@nodeType and FilterType = case when @replaceFlag=0 then 'P' else 'G' end		


	if @exposureKey<>''
		set @sql = @sql + ' and B.ExposureKey =' + @exposureKey;

	--Add Where Clause--
	if len(@whereClause)>0 	set @sql = @sql + ' and ' + @whereClause
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql);

	set @sql= 'create clustered index  AccountKeys_I1 on ' + @schemaName + '.AccountKeys(ExposureKey ,AccountKey );'
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql)
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;
	-----------------------------------


	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @keyList='ExposureKey,AccountKey';
	--GetExposureKeyList--
	set @sql='select distinct exposureKey from ' +  @schemaName + '.AccountKeys';
	exec absp_Util_GenInList @exposureKeyList out,@sql;

	--Check if Structure filter is defined--
	if exists(select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef  B on A.CategoryId=B.CategoryId 
			where NodeKey=@nodeKey and NodeType = @nodeType  and CategoryOrder=4 and FilterType in('P','G','W') )
		set @structureFilterDefined=1  

	--Check if Policy filter is defined--
	if exists(select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef  B on A.CategoryId=B.CategoryId 
		where NodeKey=@nodeKey and NodeType = @nodeType and CategoryOrder=2 and FilterType in('P','G','W') )
		set @policyFilterDefined=1
		
	--Check if Site filter is defined--
	if exists(select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef  B on A.CategoryId=B.CategoryId 
		where NodeKey=@nodeKey and NodeType = @nodeType and CategoryOrder=3 and FilterType in('P','G','W') )
		set @siteFilterDefined=1

	if @replaceFlag=0 and exists(select 1 from ExposureDataFilterInfo where  NodeKey=@nodeKey and NodeType=@NodeType and FilterType = 'P') 
		set @FilterDefined=1
	if @replaceFlag=1 and exists(select 1 from ExposureDataFilterInfo where  NodeKey=@nodeKey and NodeType=@NodeType and FilterType in('G','W')) 
		set @FilterDefined=1
	
	---Loop through all subcategories with filter and get the keys for category tables--
	--================================================================================
	declare  c1 cursor for select distinct Category,TableName,CategoryOrder  from  ExposureCategoryDef  B
					where len(dbo.trim(TableName))>0  and SubcategoryOrder=0  
					order by CategoryOrder
	open c1
	fetch c1 into @category,@tableName,@categoryOrder
	while @@fetch_status=0
	begin	
		if @tableName='Account'
			set @keyList='ExposureKey,AccountKey';
		else if @tableName='Policy'
			set @keyList='ExposureKey,AccountKey,PolicyKey';
		else if @tableName='Site'
			set @keyList='ExposureKey,AccountKey,SiteKey';
		else if @tableName='Structure'
			set @keyList='ExposureKey,AccountKey,StructureKey,SiteKey';
		if @tableName<>'Account'--AccountKeys table has been created already--
		begin
			print ''
			print 'Get ' + @category
			print '============'
		
			--Create tables in schema--
			set @categoryTable=@schemaName + '.' + @tableName + 'Keys';

			set @sql='create table ' + @categoryTable + ' (' + replace(@KeyList,',',' int,' )+' int'+ ')'
			
			if @debug=1	 exec absp_MessageEx @sql
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			exec(@sql);

			--Generate whereClause--
			exec absp_GenerateExposureWhereClause @whereClause out, @nodeKey, @nodeType,@category,@tableName,@replaceFlag

			--Insert filtered data in Schema table--	
			if (@categoryOrder=2 and @policyFilterDefined=1) or(@categoryOrder=4 and @structureFilterDefined=1)or(@categoryOrder=3 and @siteFilterDefined=1)
			begin
				exec absp_GetJoinString @joinClause out,'A','B','ExposureKey,AccountKey'
				set @joinTableName=@schemaName + '.AccountKeys';		
				set @sql = 'insert into '+@categoryTable+
					' select  A.' + replace(@KeyList,',' ,',A.')+ ' from ' + @tableName +' A inner join ' + @joinTableName + ' B  on '+@joinClause
					+ ' and A.ExposureKey ' + @exposureKeyList;

				--Add Record filter--
				if @recordFilter<>'' set @sql = @sql + ' where ' + @recordFilter

				--Add Where Clause--
				if len(@whereClause)>0 and @recordFilter<>'' 
					set @sql = @sql + ' and ' + @whereClause
				else if len(@whereClause)>0 and @recordFilter='' 
					set @sql = @sql + ' where ' + @whereClause 

				if @debug=1 exec absp_MessageEx @sql
				exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
				exec(@sql);
			end
			
			set @sql= 'create clustered index ' + @tableName + 'Keys_I1 on ' + @categoryTable + ' (' + @KeyList + ')'
			if @debug=1 exec absp_MessageEx @sql
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			exec(@sql)
		end
		
		--Loop through all subcategories which have filter--
		--===============================================

		if @replaceFlag=0
			declare  c2 cursor for select distinct Category,TableName  from  ExposureDataFilterInfo A inner join ExposureCategoryDef   B
				on A.CategoryId=B.CategoryId
					where  CategoryOrder=@categoryOrder and SubcategoryOrder>0 
					and NodeKey=@nodeKey and NodeType=@NodeType
					and FilterType = 'P' 
		else
			declare  c2 cursor for select distinct Category,TableName  from  ExposureDataFilterInfo A inner join ExposureCategoryDef   B
				on A.CategoryId=B.CategoryId
					where  CategoryOrder=@categoryOrder and SubcategoryOrder>0 
					and NodeKey=@nodeKey and NodeType=@NodeType
					and FilterType in('G','W')
		open c2
		fetch c2 into @subCategory,@tName
		while @@fetch_status=0
		begin
			if @tName='PolicyFilter'
			begin
				 set @KeyList1='ExposureKey,AccountKey,PolicyConditionNameKey,StructureKey'
				 set @KeyList2='ExposureKey,AccountKey,StructureKey'
				 
			end
			else
			begin
				set @KeyList1=@KeyList;
				set @KeyList2=@KeyList;
			end
			if (@tName<>'PolicyCondition' ) or (@tName='PolicyCondition' and @structureFilterDefined=0)
			begin
				--Do not create PolicyConditionKeys table if a structure is defined -- we will do it later--
				set @colList=@tName+'RowNum';
				--Create tables in schema--
				if @tName='Reinsurance' and @category ='Account'
					set @t='AccountReinsurance'
				else if @tName='Reinsurance' and @category ='Policy'
					set @t='PolicyReinsurance'
				else if @tName='Reinsurance' and @category ='Site'
					set @t='SiteReinsurance'
				else if @tName='SiteCondition' and @category ='Structure'
					set @t='StructureCondition'
				else set @t=@tName

				set @subCategoryTable=@schemaName + '.' + @t + 'Keys_Temp';	
				set @sql='if exists (select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name =''' +   @t + 'Keys_Temp' + ''' ) drop table ' + @subCategoryTable
				 exec(@sql)
				set @sql='create table ' + @subCategoryTable +  '(' + @colList + ' int,' + replace(@KeyList1,',',' int,' )+' int'+ ')'
				if @debug=1 exec absp_MessageEx @sql
				exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
				exec(@sql);

				--Generate whereClause--
				exec absp_GenerateExposureWhereClause @whereClause out, @nodeKey, @nodeType,@subCategory,@t,@replaceFlag;
				
				if (@categoryOrder=2  and @policyFilterDefined=1) or (@categoryOrder=3  and @siteFilterDefined=1)or @categoryOrder=4  and @structureFilterDefined=1
				begin
					--Insert in Schema table--
					exec absp_GetJoinString @joinClause out,'A','B',@KeyList2

					set @sql = 'insert into '+@subCategoryTable+
						' select  A.' + @colList + ',A.' + replace(@KeyList1,',' ,',A.')+ ' from ' + @tName +' A inner join ' + @schemaName + '.' + @tableName + 'Keys  B  on '+@joinClause+
						 ' and A.ExposureKey ' + @exposureKeyList;
				end
				else
				begin
					--Insert in Schema table--
					exec absp_GetJoinString @joinClause out,'A','B','ExposureKey,AccountKey'

					set @sql = 'insert into '+@subCategoryTable+
						' select  A.' + @colList + ',A.' + replace(@KeyList1,',' ,',A.')+ ' from ' + @tName +' A inner join ' + @schemaName + '.AccountKeys  B  on '+@joinClause+
						 ' and A.ExposureKey ' + @exposureKeyList;
				end
				--Add Record filter--
				if @recordFilter<>'' set @sql = @sql + ' where ' + @recordFilter

				--Add Where Clause--
				if len(@whereClause)>0 and @recordFilter<>'' 
					set @sql = @sql + ' and ' + @whereClause
				else if len(@whereClause)>0 and @recordFilter='' 
					set @sql = @sql + ' where ' + @whereClause 

				if @debug=1 exec absp_MessageEx @sql
				exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
				exec(@sql);

				--Remove the extra keys from main table--
				exec('truncate table ' +  @categoryTable)
				if (@tName<>'PolicyFilter')
				begin	
					set @sql='insert into ' + @categoryTable +
						' select distinct ' + @KeyList1 + ' from ' + @subCategoryTable
					if @debug=1 exec absp_MessageEx @sql
					exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
					exec(@sql)
				end
				else
				begin
					set @sql='insert into ' + @categoryTable +
						' select distinct A.ExposureKey,A.AccountKey,A.StructureKey,SiteKey from ' + @subCategoryTable + ' A ' + 
						' inner join Structure B on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey and A.StructureKey=B.StructureKey ' +
						 ' and A.ExposureKey ' + @exposureKeyList;
					if @debug=1 exec absp_MessageEx @sql
					exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
					exec(@sql)
				end
				
				set @sql= 'create clustered index ' + @t + 'Keys_Temp_I1 on ' + @subCategoryTable+ '(' + @KeyList1 +')'
				exec (@sql)
				if @debug=1 exec absp_MessageEx @sql
			
			end
			fetch c2 into @subCategory,@tName
		end
		close c2
		deallocate c2

		fetch c1 into @category,@tableName,@categoryOrder

	end
	close c1
	deallocate c1			
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	if @structureFilterDefined=0 and @siteFilterDefined=0 --create StructureKeys from Account
	begin		
		exec('truncate table ' +  @schemaName + '.StructureKeys');
		set @sql='insert into ' + @schemaName + '.StructureKeys' +
				' select  B.ExposureKey,B.AccountKey,B.StructureKey,B.SiteKey  from ' +  @schemaName + '.AccountKeys ' +
				' A inner join Structure' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey'+
				 ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
		
		exec('truncate table ' +  @schemaName + '.SiteKeys');
		set @sql='insert into ' + @schemaName + '.SiteKeys' +
				' select  B.ExposureKey,B.AccountKey,B.SiteKey  from ' +  @schemaName + '.AccountKeys ' +
				' A inner join Site' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey'+
				 ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end
	else if  @structureFilterDefined=0 and @siteFilterDefined=1 --create structureKeys from Site
	begin
		exec('truncate table ' +  @schemaName + '.StructureKeys');
		set @sql='insert into ' + @schemaName + '.StructureKeys' +
					' select  B.ExposureKey,B.AccountKey,B.StructureKey,B.SiteKey   from ' +  @schemaName + '.SiteKeys ' +
				  ' A inner join Structure' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey and A.SiteKey=B.SiteKey'+
				   ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
		set @structureFilterDefined=1
	end

	if (@policyFilterDefined=0)  --Get policyKey from account
	begin
		exec('truncate table ' +  @schemaName + '.PolicyKeys');
		set @sql='insert into ' + @schemaName + '.PolicyKeys' +
				' select  B.ExposureKey,B.AccountKey,B.PolicyKey  from ' +  @schemaName + '.AccountKeys ' +
				' A inner join Policy' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey'+
				 ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;

	print ''
	print 'Get PolicyConditions associated to structures'
	print '============================================='
	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql='if exists (select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name =''' +  '' + 'PolicyConditionKeys_Temp'' )
			 drop table ' +@schemaName + '.PolicyConditionKeys_Temp' ;
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql) 

	set @sql='create table ' + @schemaName + '.PolicyConditionKeys_Temp (PolicyConditionRowNum int,ExposureKey int,AccountKey int,PolicyKey int)'
			
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql);

	--Generate whereClause--
	exec absp_GenerateExposureWhereClause @whereClause out, @nodeKey, @nodeType,'Policy Conditions','PolicyCondition',@replaceFlag,'PC';
	if len(@whereClause)>0 set @pcFilterDefined = 0;
	 
	--Get PolicyConditons  associated to structures--
	set @sql = 'insert into ' + @schemaName + '.PolicyConditionKeys_Temp  
	select PolicyConditionRowNum ,PC.ExposureKey,PC.AccountKey,PC.PolicyKey from  PolicyCondition PC '	;

	if @FilterDefined = 1 and exists(select 1 from ExposureDataFilterInfo where CategoryID =12  and NodeKey=@nodeKey and NodeType=@NodeType)
	begin
		--Filter on policyfilter
		set @sql = @sql + ' inner join  ' + @schemaName + '.policyFilterKeys_Temp A on PC.PolicyConditionNameKey=A.PolicyConditionNameKey and PC.ExposureKey=A.ExposureKey and PC.AccountKey=A.AccountKey '
		set @sql = @sql + '	inner join ' + @schemaName + '.StructureKeys B on B.ExposureKey=A.ExposureKey and B.AccountKey=A.AccountKey and B.StructureKey=A.StructureKey'
	end
	else if @FilterDefined = 1 and exists(select 1 from ExposureDataFilterInfo A inner join ExposureCategorydef B on A.CategoryId=B.CategoryId and CategoryOrder =4  and NodeKey=@nodeKey and NodeType=@NodeType )
	begin
		--Filter on structure
		set @sql = @sql + '	inner join ' + @schemaName + '.StructureKeys A on PC.ExposureKey=A.ExposureKey and PC.AccountKey=A.AccountKey '
	end
	else
	begin
		set @sql = @sql + ' inner join ' + @schemaName + '.PolicyKeys P on PC.ExposureKey=P.ExposureKey and PC.AccountKey=P.AccountKey and PC.PolicyKey =P.PolicyKey '
	end
	set @sql = @sql + ' and PC.ExposureKey ' + @exposureKeyList
 			
	--Add Record filter--
		if @recordFilter<>'' set @sql = @sql + ' where ' + @recordFilter

	--Add Where Clause--
	if len(@whereClause)>0 and @recordFilter<>'' 
		set @sql = @sql + ' and ' + @whereClause
	else if len(@whereClause)>0 and @recordFilter='' 
		set @sql = @sql + ' where ' + @whereClause 
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;

	
	--Get PolicyConditons not associated to structures--
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'insert into ' + @schemaName + '.PolicyConditionKeys_Temp 
					select PolicyConditionRowNum,  PC.ExposureKey,PC.AccountKey,PC.PolicyKey from  PolicyCondition PC  '
	if @FilterDefined=1 and exists(select 1 from ExposureDataFilterInfo where CategoryID =12 and NodeKey=@nodeKey and NodeType=@NodeType )
	begin
		set @sql = @sql + ' inner join ' + @schemaName + '.policyFilterKeys_Temp  P on PC.ExposureKey=P.ExposureKey and PC.AccountKey=P.AccountKey  '
	end
	else if @FilterDefined = 1 and exists(select 1 from ExposureDataFilterInfo A inner join ExposureCategorydef B on A.CategoryId=B.CategoryId and CategoryOrder =4  and NodeKey=@nodeKey and NodeType=@NodeType 	)
	begin
		--Filter on structure
		set @sql = @sql + '	inner join ' + @schemaName + '.StructureKeys A on PC.ExposureKey=A.ExposureKey and PC.AccountKey=A.AccountKey '
	end
	else
	begin
		set @sql = @sql + ' inner join ' + @schemaName + '.PolicyKeys P on PC.ExposureKey=P.ExposureKey and PC.AccountKey=P.AccountKey and PC.PolicyKey =P.PolicyKey '
	end
	set @sql = @sql + ' where PC.PolicyConditionNameKey=0'	+ ' and PC.ExposureKey ' + @exposureKeyList
	
	--Add Record filter--
	if @recordFilter<>'' set @sql = @sql + ' and ' + @recordFilter
	--Add Where Clause--
	if len(@whereClause)>0  set @sql = @sql + ' and ' + @whereClause
	if @debug=1 exec absp_MessageEx @sql
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec(@sql)

	set @sql= 'create clustered index  PolicyConditionKeys_Temp_I1 on ' + @schemaName + '.PolicyConditionKeys_Temp(ExposureKey,AccountKey,PolicyKey)'
	exec (@sql)
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;
			
	print ''
	print 'Get Final Policy list'
	print '===================='
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	if @FilterDefined = 1 and exists(select 1 from ExposureDataFilterInfo where CategoryID in(12,6) and NodeKey=@nodeKey and NodeType=@NodeType )
	begin 
		exec('truncate table ' +  @schemaName + '.PolicyKeys');
		set @sql='insert into ' + @schemaName + '.PolicyKeys' +
				' select distinct ExposureKey,AccountKey,PolicyKey from ' +  @schemaName + '.PolicyConditionKeys_Temp '
	
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end

	print ''
	print 'Get Final Account,Policy,Location list'
	print '===================='


	if @policyFilterDefined=1 and  @structureFilterDefined=1
	begin
		exec('truncate table ' +  @schemaName + '.AccountKeys');
		set @sql='insert into ' + @schemaName + '.AccountKeys' +
					' select distinct ExposureKey,AccountKey from ' +  @schemaName + '.StructureKeys '+
					' intersect ' +
					' select distinct ExposureKey,AccountKey from ' +  @schemaName + '.PolicyKeys '
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
		
		
		create table #T1(ExposureKey int, AccountKey int, PolicyKey int);
		set @sql='insert into #T1 ' + 
				' select  A.ExposureKey,A.AccountKey,A.PolicyKey  from ' +  @schemaName + '.PolicyKeys ' +
				' A inner join ' + @schemaName + '.AccountKeys ' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey'+
				' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)

		exec('truncate table ' +  @schemaName + '.PolicyKeys');
		exec('insert into ' + @schemaName + '.PolicyKeys  select ExposureKey,AccountKey,PolicyKey  from #T1' );
		
		create table #t2(ExposureKey int, AccountKey int,StructureKey int,SiteKey int);			
		set @sql='insert into #T2 ' +
					' select  A.ExposureKey,A.AccountKey,A.StructureKey,A.SiteKey  from ' +  @schemaName + '.StructureKeys A ' +
					' inner join ' + @schemaName + '.AccountKeys ' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey' +
				  ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
		
		exec('truncate table ' +  @schemaName + '.StructureKeys');
		exec('insert into ' + @schemaName + '.StructureKeys  select ExposureKey,AccountKey,StructureKey,SiteKey  from #T2' );

	end
	else if @policyFilterDefined=0 and  @structureFilterDefined=1 --Structure filter has been defined
	begin
		exec('truncate table ' +  @schemaName + '.AccountKeys');
		set @sql='insert into ' + @schemaName + '.AccountKeys' +
					' select distinct ExposureKey,AccountKey from ' +  @schemaName + '.StructureKeys '
					 
		if @debug=1 exec absp_MessageEx @sql
		exec(@sql)

		exec('truncate table ' +  @schemaName + '.PolicyKeys');
		set @sql='insert into ' + @schemaName + '.PolicyKeys' +
				' select  B.ExposureKey,B.AccountKey,B.PolicyKey  from ' +  @schemaName + '.AccountKeys ' +
				' A inner join Policy' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey' +
				+ ' and A.ExposureKey ' + @exposureKeyList
				
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end
	else if @policyFilterDefined=1 and  @structureFilterDefined=0 --PolicyFilter has been defined
	begin
		exec('truncate table ' +  @schemaName + '.AccountKeys');
		set @sql='insert into ' + @schemaName + '.AccountKeys' +
					' select distinct ExposureKey,AccountKey from ' +  @schemaName + '.PolicyKeys '
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
			
		exec('truncate table ' +  @schemaName + '.StructureKeys');
		set @sql='insert into ' + @schemaName + '.StructureKeys' +
				' select  B.ExposureKey,B.AccountKey,B.StructureKey,B.SiteKey  from ' +  @schemaName + '.AccountKeys ' +
				' A inner join Structure' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey'+
				 ' and A.ExposureKey ' + @exposureKeyList
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;
	
	if @siteFilterDefined=0 and  @structureFilterDefined=1
	begin
	
		exec('truncate table ' +  @schemaName + '.SiteKeys');
		--set @sql='insert into ' + @schemaName + '.SiteKeys' +
		--		' select  B.ExposureKey,B.AccountKey,B.SiteKey  from ' +  @schemaName + '.StructureKeys ' +
		--		' A inner join Site' + ' B  on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey and A.SiteKey=B.SiteKey'+
		--		+ ' and A.ExposureKey ' + @exposureKeyList
		set @sql='insert into ' + @schemaName + '.SiteKeys' +
                        ' select  A.ExposureKey,A.AccountKey,A.SiteKey  from ' +  @schemaName + '.StructureKeys A';
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql)
	end
	--In case of replace we need not find all the keys--
	if @replaceFlag=1 return;


	print ''
	print 'Get Final list of  tables'
	print '===================================='
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	--Fill subcategory table --
	declare  c3  cursor for select distinct TableName,CategoryOrder  from  ExposureCategoryDef  B
					where len(dbo.trim(TableName))>0 and SubcategoryOrder=0  order by CategoryOrder
	open c3
	fetch c3 into @category,@categoryOrder
	while @@fetch_status=0
	begin
		print @category
		print '--------------'
		if @category='Account'
			set @keyList='ExposureKey,AccountKey';
		else if @category='Policy'
			set @keyList='ExposureKey,AccountKey,PolicyKey';
		else if @category='Site'
			set @keyList='ExposureKey,AccountKey,SiteKey';
		else if @category='Structure'
			set @keyList='ExposureKey,AccountKey,StructureKey,SiteKey';
	

		set @categoryTable=@schemaName + '.' + @category + 'Keys';

		declare  c4 cursor for select distinct TableName from  ExposureCategoryDef  
			where CategoryOrder=@categoryOrder and SubCategoryOrder>0 
		open c4
		fetch c4 into @tName
		while @@fetch_status=0
		begin

			if @tName='Reinsurance' and @category ='Account'
				set @tableName='AccountReinsurance'
			else if @tName='Reinsurance' and @category ='Policy'
				set @tableName='PolicyReinsurance'
			else if @tName='Reinsurance' and @category ='Site'
				set @tableName='SiteReinsurance'
			else if @tName='SiteCondition' and @category ='Structure'
				set @tableName='StructureCondition'
			else set @tableName=@tName
			
			if @tName='PolicyFilter'
			begin
				 set @KeyList1='ExposureKey,AccountKey,PolicyConditionNameKey,StructureKey'
				 set @KeyList2='ExposureKey,AccountKey,StructureKey'
				 
			end
			else
			begin
				set @KeyList1=@KeyList;
				set @KeyList2=@KeyList;
			end

			--Create tables in schema--
			set @subCategoryTable=@schemaName + '.' + @tableName + 'Keys';
			set @sql= 'create table ' + @subCategoryTable +  ' (' +@tName + 'RowNum int,'+ replace(@KeyList1,',',' int,' )+' int'+ ')'
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql);

			--Insert in SubCategory Schema table--
			exec absp_GetJoinString @joinClause out,'A','B',@keyList2

			set @sql='if exists(select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name=''' + @tableName + 'Keys_Temp'')'
			set @sql =@sql + 'insert into '+@subCategoryTable+
					' select  distinct A.' + @tName+'RowNum,A.' + replace(@KeyList1,',' ,',A.')+ ' from ' + @subCategoryTable+'_Temp A inner join ' +
					 @categoryTable + ' B  on '+@joinClause+ ' and A.ExposureKey ' + @exposureKeyList;
			if @debug=1 exec absp_MessageEx @sql
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			exec(@sql);

			set @sql='if not exists(select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name=''' + @tableName + 'Keys_Temp'')'
			set @sql =@sql + 'insert into '+@subCategoryTable+
					' select  distinct A.' + @tName+'RowNum,A.' + replace(@KeyList1,',' ,',A.')+ ' from ' + @tName+' A inner join ' +
					 @categoryTable + ' B  on '+@joinClause + ' and A.ExposureKey ' + @exposureKeyList ;
			if @debug=1 exec absp_MessageEx @sql
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			exec(@sql);
			
			--set @sql= 'create index ' +@tableName + 'Keys_I1 on ' + @subCategoryTable+ '(' + @tName+'RowNum) INCLUDE (' + @KeyList1 +')'
			set @sql= 'create clustered index ' +@tableName + 'Keys_I1 on ' + @subCategoryTable+ '(' + @tName+'RowNum,' + @KeyList1 +')'
			if @debug=1 exec absp_MessageEx @sql
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
			exec(@sql)

			fetch c4 into @tName
		end
		close c4
		deallocate c4

		fetch c3 into @category,@categoryOrder		
	end
	close c3
	deallocate c3	
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	
	set @stepNumber=@stepNumber +1;

	--Get Names and Numbers for Account,Policy, Site,Structure
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0	
	set @sql = 'select A.ExposureKey,A.AccountKey,AccountNumber,AccountName,FinancialModelType  into ' + @schemaName + '.FinalAccountKeys from ' + @schemaName + '.AccountKeys A
				inner join Account B on A.ExposureKey=B.ExposureKey and A.AccountKey = B.AccountKey'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	set @sql= 'create clustered index FinalAccountKeys_I1 on ' + @schemaName + '.FinalAccountKeys(ExposureKey ,AccountKey );'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	
	set @sql = 'select A.ExposureKey,A.AccountKey,A.PolicyKey,PolicyNumber,PolicyName,CurrencyCode  into ' + @schemaName + '.FinalPolicyKeys from ' + @schemaName + '.PolicyKeys A
				inner join Policy B on A.ExposureKey=B.ExposureKey and A.AccountKey = B.AccountKey and A.PolicyKey = B.PolicyKey'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	set @sql= 'create clustered index FinalPolicyKeys_I1 on ' + @schemaName + '.FinalPolicyKeys(ExposureKey ,AccountKey,PolicyKey );'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	
	set @sql = 'select A.ExposureKey,A.AccountKey,A.SiteKey,SiteNumber,SiteName,CurrencyCode  into ' + @schemaName + '.FinalSiteKeys from ' + @schemaName + '.SiteKeys A
				inner join Site B on A.ExposureKey=B.ExposureKey and A.AccountKey = B.AccountKey and A.SiteKey = B.SiteKey'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	set @sql= 'create clustered index FinalSiteKeys_I1 on ' + @schemaName + '.FinalSiteKeys(ExposureKey ,AccountKey,SIteKey );'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);

	set @sql = 'select A.ExposureKey,A.AccountKey,A.StructureKey,A.SiteKey,StructureNumber,StructureName ,COuntryCode into ' + @schemaName + '.FinalStructureKeys from ' + @schemaName + '.StructureKeys A
				inner join Structure B on A.ExposureKey=B.ExposureKey and A.AccountKey = B.AccountKey and A.StructureKey = B.StructureKey
				and A.SiteKey = B.SiteKey'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	set @sql= 'create clustered index FinalStructureKeys_I1 on ' + @schemaName + '.FinalStructureKeys(ExposureKey ,AccountKey,StructureKey,SiteKey );'
	exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	exec (@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Completed','' ,'',0	

end

