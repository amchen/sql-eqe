if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateUserSnapshot') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateUserSnapshot
end
go

create procedure absp_GenerateUserSnapshot @snapshotKey int, @taskKey int , @debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will create user defined snapshots in order to compare Results due to change
			in data.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on

	declare @exposureReport varchar(1);
	declare @probabilisticReport varchar(1);
	declare @ELTReport varchar(1);
	declare @schemaname varchar(50);
	declare @sql varchar(max);
	declare @sql2 varchar(max);
	declare @tableName varchar(120);
	declare @columnName varchar(120);
	declare @columnName2 varchar(120);
	declare @stepNum int;
	declare @procId int;
	declare @nodeKey int;
	declare @nodeType int;
	declare @reportTableType int;
	declare @reportType varchar(20);
	declare @ebeRumID int;
	declare @inList varchar(max);
	declare @aKeyinList varchar(max);
	declare @doNotSnapshot int;
	declare @whereClause varchar(max);
	declare @tableName2 varchar(120);
	declare @version varchar(25);
	declare @msgTxt varchar(100);

	-- assign task process ID to the task so the task can be cancelled
	update TaskInfo set TaskDBProcessID=@@spid, Status='Running'where TaskKey=@taskKey;

	--Get SnapshotInfo based on the given snapshot key--
	select @schemaName=SchemaName,@exposureReport=ExposureReports,@probabilisticReport=ProbabilisticReports,@ELTReport=ELTReports from SnapshotInfo where SnapshotKey=@snapshotKey;
	--Get Version Info--
	select top (1) @version=SchemaVersion from RQEVersion order by RQEVersion desc, Build desc;
	update Snapshotinfo set DBSchemaVersion=@version where SnapshotKey=@snapshotKey
	-----------------------------------------------------

	--Get nodeInfo--
	select @nodeKey = NodeKey,@nodeType=NodeType from SnapshotMap where SnapshotKey=@snapshotKey;
	if @ELTReport = 'Y'
	begin
		set @sql2='select EBERunID from eltSummary where NodeKey=' + cast(@nodeKey as varchar(30)) + ' and NodeType= ' + cast(@nodeType as varchar(30));
		if @debug=1 exec absp_MessageEx @sql2;
		exec absp_Util_GenInList @InList out,@sql2
	end


	select @columnName = Case @nodeType
		when 1  then 'Aport_Key'
		when 2  then 'Pport_key'
		when 23 then 'RPort_Key'
		when 27 then 'Prog_Key'
		when 30 then 'Case_Key'
	else ''	end

	set @columnName2=replace(@columnName,'_','');
	if @columnName2='ProgKey' set @columnName2='ProgramKey'


	--Get ReportType--
	set @reportType='';
	if @exposureReport = 'Y' set @reportType= '1,'
	if @probabilisticReport = 'Y' set @reportType= @reportType + '3,4,'
	if @ELTReport = 'Y' set @reportType= @reportType +'5,'
	set @reportType=left(@reportType,len(@reportType)-1);

	--Add Steps to TaskStepInfo--
	exec absp_AddTaskSteps  @taskKey,1,'Waiting','Create a new database schema for the snapshot.' ,'',1
	set @stepNum= 2;
	declare  SnapShotCurs cursor for select case when TableType='Reports (Exposure)' then 1
					when TableType='Reports (Analysis)' then 2
					when TableType='Event Loss Tables' then 5 else 999 end,
					TableName from systemdb.dbo.DictTbl where CF_DB in('Y','L') and AllowSnapShot='Y'
					and not SYS_DB in('Y','L')
	union
	select 888,CloneName from systemdb.dbo.DictTbl A inner join DictClon B
				on A.TableName=B.TableName and A.SYS_DB in('Y','L') and B.Sys_DB='N' and AllowSnapShot='Y';
	open SnapShotCurs
	fetch SnapShotCurs into @reportTableType, @tablename
	while @@fetch_status=0
	begin
		set @donotSnapshot=0;
		if (@reportTableType=1 and @exposureReport <> 'Y') or(@reportTableType=2 and @probabilisticReport <>  'Y' ) or	(@reportTableType=5 and @ELTReport <>  'Y')
		begin
			set @donotSnapshot=1;
		end
		if @reportTableType=2
		begin
			if not exists(select 1 from DictCol where TableName=@tableName and FieldName=@columnName)
					set @doNotSnapshot=1;
		end
		if @donotSnapshot=0
		begin
			set @msgTxt='Copy ' + @tableName + ' to new schema';
			exec absp_AddTaskSteps  @taskKey,@stepNum,'Waiting',@msgTxt,'',1;
			set @stepNum=@stepNum+1;
		end
		fetch SnapShotCurs into @reportTableType, @tablename
	end
	close SnapShotCurs
	deallocate SnapShotCurs

	exec absp_AddTaskSteps  @taskKey,@stepNum,'Waiting','Create views for systemdb tables.','',1	;
	set @stepNum=@stepNum+1
	exec absp_AddTaskSteps  @taskKey,@stepNum ,'Waiting','Update SnapshotInfo.Status.','',1	;
 	-----------------------------


	-- Create a new database schema for the snapshot--
	set @stepNum= 1;
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Running','' ,'',0
	exec absp_Util_AddTaskProgress @taskKey, 'Create a new database schema for the snapshot.', @procID;
	exec absp_Util_CleanupSchema @schemaName;
	set @sql='Create Schema ' + @schemaName;
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Completed','' ,'',0
	--------------------------------------------------------------


	--Copy tables based on the selected reportType into the new schema--

	declare SnapShotCurs cursor for
					select case when TableType='Reports (Exposure)' then 1
					when TableType='Reports (Analysis)' then 2
					when TableType='Event Loss Tables' then 5 else 999 end,
					TableName from systemdb.dbo.DictTbl where CF_DB in('Y','L') and AllowSnapShot='Y'
					and not SYS_DB in('Y','L')
		union
		select 888,CloneName from systemdb.dbo.DictTbl A inner join DictClon B
				on A.TableName=B.TableName and A.SYS_DB in('Y','L') and B.Sys_DB='N' and AllowSnapShot='Y';

		open SnapShotCurs
		fetch SnapShotCurs into @reportTableType, @tablename
		while @@fetch_status=0
		begin

			--Do not copy data for unselected reports--
			set @doNotSnapshot=0;
			if (@reportTableType=1 and @exposureReport <> 'Y') or(@reportTableType=2 and @probabilisticReport <>  'Y' ) or	(@reportTableType=5 and @ELTReport <>  'Y')
				set @doNotSnapshot=1;
			if @reportTableType=2
			begin
				if not exists(select 1 from DictCol where TableName=@tableName and FieldName=@columnName)
					set @doNotSnapshot=1;
			end

			--Copy only required rows--
			if @donotSnapshot=0
			begin

				if @reportTableType=5
				begin
					set  @whereClause = ' where EBERunID' + @inList
				end
				else if @reportTableType=1
				begin
					set  @whereClause = ' where NodeKey = ' + cast(@nodeKey as varchar(30)) + ' and NodeType= ' + cast(@nodeType as varchar(30));
				end
				else if @reportTableType=2
				begin
					if exists(select 1 from DictCol where TableName=@tableName and FieldName=@columnName)
					begin
						set  @whereClause = ' where ' + @columnName + '=' + cast(@nodeKey as varchar(30)) ;
					end
					else
					begin
						set @doNotSnapshot=1;--The column does not Exist in the results table i.e. when Aport is snapshoted only copy tables with Aprot_Key
					end
				end
				else
				begin
					--Copy rows for the selected report(s) only for AvailableReport and AnalysisRunInfo
					if @tableName in('AnalysisRunInfo')
					begin
						set @sql='select distinct T1.AnalysisRunKey from AnalysisRunInfo T1
							inner join AvailableReport T2 on T1.AnalysisRunKey=T2.AnalysisRunKey
							inner join ReportQuery T3 on T2.ReportId=T3.ReportId
							where  ReportTypeKey in( ' + @reportType+ ') and NodeType=' + dbo.trim(cast(@NodeType as varchar(30))) +
							' and ' + @columnName2 +'=' + dbo.trim(cast(@NodeKey as varchar(30)));
						print @sql
						exec absp_Util_GenInList @AKeyInList out,@sql
						set @whereClause=' where AnalysisRunKey ' + @AKeyInList;
						print @whereClause
					end
					else if @tableName in('AvailableReport')
					begin
						--Get AnalysisRunKeys--
						set @sql='select T1.AnalysisRunKey from AnalysisRunInfo T1
							inner join AvailableReport T2 on T1.AnalysisRunKey=T2.AnalysisRunKey
							inner join ReportQuery T3 on T2.ReportId=T3.ReportId
							where  ReportTypeKey in( ' + @reportType+ ') and NodeType=' + dbo.trim(cast(@NodeType as varchar(30))) +
							' and ' + @columnName2 +'=' + dbo.trim(cast(@NodeKey as varchar(30)));
						exec absp_Util_GenInList @AKeyInList out,@sql
						set @whereClause=' where AnalysisRunKey ' + @AKeyInList ;
						--Get ReportID--
						set @sql='select T2.ReportId from AnalysisRunInfo T1
							inner join AvailableReport T2 on T1.AnalysisRunKey=T2.AnalysisRunKey
							inner join ReportQuery T3 on T2.ReportId=T3.ReportId
							where  ReportTypeKey in( ' + @reportType+ ') and NodeType=' + dbo.trim(cast(@NodeType as varchar(30))) +
							' and ' + @columnName2 +'=' + dbo.trim(cast(@NodeKey as varchar(30)));
						exec absp_Util_GenInList @AKeyInList out,@sql
						set @whereClause=@whereClause + ' and ReportID ' + @AKeyInList ;

						print @whereClause
					end
					else
						set @whereClause=''
				end
			end

			--Copy to schema-
			if @doNotSnapshot=1 and @tableName='EltSummary'
			begin
				--create empty table--
				exec absp_Util_CreateTableScript @sql2 out, @tableName ,'','',1;
				set @sql2=replace(@sql2,' ' + @tableName + ' ',' ' + @schemaName + '.' +@tableName + ' ');
				if @debug=1 exec absp_MessageEx @sql2;
				exec (@sql2);
			end
			else if @doNotSnapshot=0
			begin
				set @stepNum=@stepNum+1;
				exec absp_AddTaskSteps  @taskKey,@stepNum,'Running','' ,'',0
				set @msgTxt='Copy ' + @tablename + ' into the new schema';
				exec absp_Util_AddTaskProgress @taskKey, @msgTxt, @procID;

				set @sql2 = ' begin transaction select * into '  + @schemaName +'.'+@tableName + ' from ' + @tableName + '  ' + @whereClause + ' commit transaction'
				if @debug=1 exec absp_MessageEx @sql2;
				exec(@sql2)

				--Create indexes--
				if @reportTableType<>888 --_U table
				begin
					exec absp_Util_CreateTableScript @sql2 out, @tableName ,'','',2;
					set @sql2=replace(@sql2,' ' + @tableName + ' ',' ' + @schemaName + '.' +@tableName + ' ');
					if @debug=1 exec absp_MessageEx @sql2;
					exec (@sql2);
				end
				exec absp_AddTaskSteps  @taskKey,@stepNum,'Completed','' ,'',0
			end


			fetch SnapShotCurs into @reportTableType,@tablename
		end
		close SnapShotCurs
		deallocate SnapShotCurs

	exec absp_MessageEx 'User Defined Snapshot Created!';
	----------------------------------------------------------------

	--Create views for systemdb tables--
	set @stepNum=@stepNum+1;
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Running','' ,'',0
	exec absp_Util_AddTaskProgress @taskKey, 'Create views for systemdb tables.', @procID;
	declare SysViewCurs cursor  for select tableName from systemdb.dbo.DictTbl where SYS_DB in('Y','L') and AllowSnapShot='Y';
	open SysViewCurs
	fetch SysViewCurs into @tableName
	while @@fetch_status=0
	begin
		--Drop if exists--
		if exists (select 1 from sys.views where name=@tableName and  schema_name(schema_id)=@schemaName )
		begin
			set @sql='drop view ' + dbo.trim(@schemaName) + '.' + @tableName;
			if @debug=1 exec absp_MessageEx @sql;
			execute(@sql);
		end

		if exists(select 1 from DictClon where tablename=@tableName)
			set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName +
					' as select * from systemdb.dbo.' + @tableName + '_S' +
					' union select * from dbo.' + @tableName + '_U';
		else
			set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName + ' as select * from systemdb.dbo.' + @tableName;

		if @debug=1 exec absp_MessageEx @sql;
		execute(@sql);

		fetch SysViewCurs into @tableName;
	end;
	close SysViewCurs;
	deallocate SysViewCurs;
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Completed','' ,'',0
	---------------------------------------------------------------

	--Set SnapshotInfo.Status--
	set @stepNum=@stepNum+1;
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Running','' ,'',0
	exec absp_Util_AddTaskProgress @taskKey, 'Update SnapshotInfo.Status', @procID;
	update SnapshotInfo set Status='Available' where SnapshotKey=@snapshotKey;
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Completed','' ,'',0
	----------------------------
end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);
	exec absp_AddTaskSteps  @taskKey,@stepNum,'Failed','' ,'',0
	select @ProcName = object_name(@@procid);
    	select	@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch
