if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_FindReplaceValueInExposureSet ') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_FindReplaceValueInExposureSet
end
 go

create procedure absp_FindReplaceValueInExposureSet @nodeKey int, @nodeType int, @taskKey int =0, @debug int=0
as
begin try
	set nocount on

	declare @schemaName varchar(100);
	declare @keyList varchar(2000);
	declare @categoryTable varchar(120);
	declare @replFieldName varchar(120);
	declare @replOperation varchar(20);
	declare @replValue varchar(120);
	declare @replTableName varchar(120);
	declare @chunkSize int;
	declare @taskCancelled int;
	declare @startRowNum int;
	declare @endRowNum int;
	declare @categoryId int
	declare @maxRowNum int;
	declare @tempTblName varchar(120);
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @subCategory int;
	declare @joinClause varchar(1000);
	declare @category int;
	declare @whereClause varchar(4000);
	declare @taskProgressMsg varchar(2000);
	declare @procID int;
	declare @exposureKeyList varchar(max);
	declare @doNotReplace int;
	declare @startTime datetime;
	declare @endMsg varchar(120);
	declare @fieldName varchar(120)
	declare @stepNumber int;
	declare @statlabel varchar(50);
	declare @cntStr varchar(max);

	set @chunkSize=10000;
	set @taskCancelled=0;
	set @procID = @@PROCID;

	-- assign task process ID to the task so the task can be cancelled
	begin transaction;
	update TaskInfo set TaskDBProcessID=@@spid where TaskKey=@taskKey;
	commit transaction;

	-- wait until the task is ready
	exec absp_TaskExecutionTimer @taskKey, 0

	--Add Steps to TaskStepInfo--
	exec absp_AddTaskSteps  @taskKey,1,'Waiting','Get list of exposures for the given portfolio' ,'',1
	exec absp_AddTaskSteps  @taskKey,2,'Waiting','Create temp table to hold the Replace information' ,'',1
	exec absp_AddTaskSteps  @taskKey,3,'Waiting','Create schema to store intermediate tables' ,'',1
	exec absp_AddTaskSteps  @taskKey,4,'Waiting','Retrieve Filter and Sort information' ,'',1
	exec absp_AddTaskSteps  @taskKey,5,'Waiting','Determine intermediate list of keys for all Exposureset tables based on the filter criteria' ,'',1
	exec absp_AddTaskSteps  @taskKey,6,'Waiting','Determine final list of Account, Policy,Site and Stricture Keys based on the filter criteria' ,'',1
	exec absp_AddTaskSteps  @taskKey,7,'Waiting','Generate PolicyCondition keys based on the associated Structures which have been determined' ,'',1
	exec absp_AddTaskSteps  @taskKey,8,'Waiting','Generate PolicyCondition keys not associated to the structures' ,'',1
	exec absp_AddTaskSteps  @taskKey,9,'Waiting','Get final Policy key list based on PolicyCondition keys' ,'',1
	exec absp_AddTaskSteps  @taskKey,10,'Waiting','Retrive Replace Information' ,'',1
	exec absp_AddTaskSteps  @taskKey,11,'Waiting','Create keys table if it does not already exist anf populate temporary table with old and new values to be replace so that it can be rolled back' ,'',1
	exec absp_AddTaskSteps  @taskKey,12,'Waiting','Start replacing data in chunks' ,'',1
	exec absp_AddTaskSteps  @taskKey,13,'Waiting','Invalidate Results' ,'',1
	exec absp_AddTaskSteps  @taskKey,14,'Waiting','Drop temporary schema' ,'',1

	if not exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType) return;
	if @debug = 1
	begin
		if OBJECT_ID('tempdb..##TMP_TASKTIME','u') is null
		create table ##TMP_TASKTIME (ID int identity not null,TaskKey int, NodeKey int, NodeType int, TaskStatus char(1), elapseTime varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS)
		-- mark the start time
		execute absp_Util_ElapsedTime @endMsg output, @startTime output;
	end

	set @stepNumber=1;
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0
	set @stepNumber=@stepNumber +1;

	--Create temp table to hold the Replace information--
	set @tempTblName = 'TmpReplaceInfo_' + dbo.trim(cast(@taskKey as varchar(30)));
	if exists ( select 1 from sysobjects where name =  @tempTblName and type = 'U' )
	begin
		exec('drop table ' + @tempTblName);
	end

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	set @sql='create table ' + @tempTblName + '( RowNum int identity(1,1),
					ExpTableRowNum varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS,
					FieldName varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS,
					OldValue varchar(6000) COLLATE SQL_Latin1_General_CP1_CI_AS,
					NewValue varchar(6000) COLLATE SQL_Latin1_General_CP1_CI_AS,
					Status int default 0)';
	if @debug=1 exec absp_MessageEx @sql
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0
	set @stepNumber=@stepNumber +1;

	--Create a separate database schema where the temp tables can be stored. The schema name will be like FilterSchema_<NodeKey>_<NodeType>_<Batch/TaskKey>
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	if @debug=1 exec absp_MessageEx 'Create a new database schema..';
	set @schemaName= 'FilterSchema_' + dbo.trim(cast(@nodeKey as varchar(10))) + '_' + dbo.trim(cast(@nodeType as varchar(10)))+'_'+dbo.trim(cast(@taskKey as varchar(10)));
	exec absp_Util_CleanupSchema @schemaName;
	set @sql='create schema ' + @schemaName;
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0



	set @taskProgressMsg = 'Searching Data..'
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

 	exec absp_PopulateSchemaTablesWithFilteredData @schemaName,@nodeKey,@nodeType,1,@debug,@taskKey;

	-- Add a task progress message
	set @taskProgressMsg = 'Getting replace Information..'
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	set @stepNumber=10;
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
 	--Get replace Info--
 	if exists(	select 1 from   ExposureDataFilterInfo A inner join ExposureCategoryDef  B 	on A.CategoryId=B.CategoryId where FilterType = 'R' and len(dbo.trim(TableName )) > 0 and A.NodeKey = @nodeKey and A.NodeType = @nodeType)
	begin
		select @replFieldName=FieldName,@replOperation=Operation,@replValue=Value,@replTableName=TableName, @subCategory=SubCategoryOrder,@category=CategoryOrder, @categoryID=A.CategoryId
		from   ExposureDataFilterInfo A inner join ExposureCategoryDef  B
		on A.CategoryId=B.CategoryId
		where FilterType = 'R' and len(dbo.trim(TableName))>0 and NodeKey = @nodeKey and NodeType = @nodeType
	end
	else
	begin
		exec('drop table ' + @tempTblName );
		execute absp_Util_CleanupSchema @schemaName
		return 1
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0
	set @stepNumber=@stepNumber +1;


	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	if @category=1
	begin
		set @keyList='ExposureKey,AccountKey';
		set @categoryTable=@schemaName + '.AccountKeys'
	end
	else if  @category=2
	begin
		set @keyList='ExposureKey,AccountKey,PolicyKey';
		set @categoryTable=@schemaName + '.PolicyKeys'
	end
	else if  @category=3
	begin
		set @keyList='ExposureKey,AccountKey,SiteKey';
		set @categoryTable=@schemaName + '.SiteKeys'
	end
	else if  @category=4
	begin
		if @replTableName='PolicyFilter'
		begin
			set @keyList='ExposureKey,AccountKey,StructureKey';
		end
		else
		begin
			set @keyList='ExposureKey,AccountKey,SiteKey,StructureKey';
		end
		set @categoryTable=@schemaName + '.StructureKeys'
	end

	if @subCategory>0
	begin
		--Get the Keys for the table--
		--Create tables in schema if it a sub category table--
		set @tableName=@schemaName + '.' + @replTableName + 'Key';
		set @sql= 'create table ' + @tableName +  ' (' +@replTableName + 'RowNum int,'+ replace(@KeyList,',',' int,' )+' int'+ ')'
		if @debug=1 exec absp_MessageEx @sql
		exec(@sql);

		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;

		--Insert in SubCategory Schema table--
		exec absp_GetJoinString @joinClause out,'A','B',@keyList

		--if keys table exist
		set @sql='if exists(select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name=''' + @replTableName + 'Keys'+'_Temp'')'
		set @sql =@sql + 'insert into '+@tableName +
			' select distinct A.' + @replTableName+'RowNum,A.' + replace(@KeyList,',' ,',A.')+ ' from ' + @schemaName + '.' + @replTableName + 'Keys'+'_Temp A inner join ' +
						@replTableName + ' B  on '+@joinClause;
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql);

		--create index--
		set @sql='create index ' + @tempTblName + '_I1 on ' + @tempTblName + ' ( RowNum)';
		if @debug=1 exec absp_MessageEx @sql
		exec (@sql)

		--if keys table does not exist
		set @whereClause='';
		if @categoryID=10
			set @whereClause=' and A.StructureKey=0'
		else if @categoryID=16
			set @whereClause=' and A.StructureKey>0'
		else if @categoryID=13
			set @whereClause=' and A.AppliesTo=''A'''
		else if @categoryID=14
			set @whereClause=' and A.AppliesTo=''P'''
		else if @categoryID=15
			set @whereClause=' and A.AppliesTo=''S'''

		set @sql='if not exists(select 1 from sys.tables where schema_Name(schema_id) = ''' + @schemaName + ''' and name=''' + @replTableName + 'Keys'+'_Temp'')'
		set @sql =@sql + 'insert into '+@tableName +
					' select distinct A.' + @replTableName+'RowNum,A.' + replace(@KeyList,',' ,',A.')+ ' from ' + @replTableName+' A inner join ' +
					 @categoryTable + ' B  on '+@joinClause + @whereClause;
		if @debug=1 exec absp_MessageEx @sql
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql);

		 set @doNotReplace=0;
		--Special handling for PolicyConditionName--
		if @replFieldName='PolicyConditionNameKey'
		begin

			set @sql = 'select top(1) PolicyConditionNameKey from PolicyConditionName where ConditionName =' + @replValue
			set @sql = @sql + ' and ExposureKey ' + @exposureKeyList
			--select @sql
			exec absp_Util_GenInListString @replValue out, @sql;

			if @replValue='' set @doNotReplace=1;
		end
		set @sql=''
		if @doNotReplace=0
		begin
			set @sql = 'insert into ' + @tempTblName +
			' select  distinct A.'  + @replTableName+'RowNum , ''' + @replFieldName + ''', ' + @replFieldName + ',' +@replValue + ',0 from ' + @replTableName +
			' A inner join ' + @tableName + ' B on A.' + @replTableName+'RowNum=B.' + @replTableName+'RowNum'
			exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		end
	end
	else
	begin
		set @tableName=@schemaName + '.' + @replTableName + 'Keys';
		exec absp_GetJoinString @joinClause out,'A','B',@keyList
		set @sql = 'insert into ' + @tempTblName +
		' select  distinct '  + @replTableName+'RowNum , ''' + @replFieldName + ''', ' + @replFieldName + ',' +@replValue + ',0 from ' + @replTableName +
		' A inner join ' + @tableName + ' B on ' + @joinClause
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
	end
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0
	set @stepNumber=@stepNumber +1;

	--Start replacing values in chunks --
	set @sql = 'select @maxRowNum=max(RowNum) from ' + @tempTblName
	exec sp_executesql @sql,N'@maxRowNum int out', @maxRowNum out;;
	set @startRowNum=1;

	set @taskProgressMsg = 'Replacing Data in table..'
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	--
	select @statlabel = Case @replTableName
		when 'Account'  then 'Accounts'
		when 'Policy'  then 'Policies'
		when 'PolicyFilter'  then 'Policy Filters'
		when 'PolicyCondition' then 'Policy Conditions'
		when 'Reinsurance' then 'Reinsurance Entries'
		when 'SiteCondition'  then 'Site Conditions'
		when 'Structure' then 'Structures'
		when 'StructureCoverage' then 'Structure Coverages'
		when 'StructureFeature' then 'Structure Features'
		else ''
	end;

	set @sql='select @cntStr=''Replacing data values from ' + @replTableName +' table having  '' + cast(sum(cast (StatValue as bigint)) as varchar(30)) + '' rows''
			from ImportStatReport
			where StatLabel = ''Number of ' + @statlabel +''' and ExposureKey ' + @exposureKeyList + ' group by StatLabel'
	execute sp_executesql @sql,N'@cntStr varchar(max) output',@cntStr output;

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,@cntStr,0
	while @startRowNum<=@maxRowNum
	begin
		set @endRowNum=@startRowNum + @chunkSize ;

		set @sql = 'update ' + @replTableName + ' set ' + @replFieldName + '=' + @replValue
			 + ' from ' + @replTableName + ' A inner join ' +  @tempTblName + ' B on  A.' + @replTableName + 'RowNum = B.ExpTableRowNum' +
			 ' where RowNum>=' + cast(@startRowNum as varchar(30)) + ' and RowNum< ' + cast(@endRowNum as varchar(30))
		if @debug=1 exec absp_MessageEx @sql;
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql);

		set @sql = 'update  '+ @tempTblName + ' set Status=1 where RowNum>= ' + cast(@startRowNum as varchar(30)) + ' and RowNum<' + cast(@endRowNum as varchar(30));
		if @debug=1 exec absp_MessageEx @sql;
		exec absp_Util_AddTaskProgress @taskKey, @sql, @procID;
		exec(@sql);

		set @startrowNum = @endRowNum ;

		if exists(select 1 from TaskInfo where TaskKey=@taskKey and Status='Cancelled')
		begin
			return;
		end
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,@cntStr,0
	set @stepNumber=@stepNumber +1;

	-- mark the finish findReplace time
	execute absp_Util_ElapsedTime @endMsg output, @startTime output;

	if @debug = 1
	begin
		insert into ##TMP_TASKTIME values(@taskKey, @NodeKey, @nodeType, 'S', @endMsg)
		-- reset the start time
		set @startTime = null
		execute absp_Util_ElapsedTime @endMsg output, @startTime output;
	end

	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	-- invalidate the results only when DictExpEdit.InvalidateResult = Y
	select distinct @tablename = TableName, @fieldName = FieldName from ExposureDataFilterInfo F inner join  ExposureCategoryDef C on F.CategoryID = C.CategoryID
	if exists (select 1 from DictExpEdit where TableName = @tablename and FieldName = @fieldName and InvalidateResult='Y')
	begin
		--Invalidate results--
		set @taskProgressMsg = 'Invalidating Results..'
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

		exec absp_InvalidateResultsUpDownAndSelf  @nodeKey, @nodeType
	end
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0
	set @stepNumber=@stepNumber +1;

	exec('drop table ' + @tempTblName );

	--drop schema--
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Running','' ,'',0
	execute absp_Util_CleanupSchema @schemaName
	exec absp_AddTaskSteps  @taskKey,@stepNumber,'Complete','' ,'',0

	if @debug =1
	begin
		-- mark the finish invalidation time
		execute absp_Util_ElapsedTime @endMsg output, @startTime output;
		insert into ##TMP_TASKTIME values(@taskKey, @NodeKey, @nodeType, 'I', @endMsg)
	end

	return 0 --success

end try
begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
--	set @taskProgressMsg = 'Exposure Set Find and Replace process was cancelled.';
--	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	-- Log it and raise error
	exec absp_Util_GetErrorInfo @ProcName
end catch

