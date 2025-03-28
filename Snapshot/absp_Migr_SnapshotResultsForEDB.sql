if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_SnapshotResultsForEDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_SnapshotResultsForEDB
end
go

create procedure absp_Migr_SnapshotResultsForEDB @nodeKey int =1, @nodeType int=12, @debug int =0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will preserve the old results during migration in order to compare
		Results Due to Model Changes between Releases

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on

	declare @currentDate varchar(14);
	declare @userName varchar(25);
	declare @currskkey int;
	declare @snapshotName varchar(50);
	declare @rqeversion varchar(25);
	declare @version varchar(25);
	declare @schemaVersion varchar(25);
	declare @schemaname varchar(50);
	declare @snapshotKey int;
	declare @sql varchar(max);
	declare @sql2 varchar(max);
	declare @description varchar(256);
	declare @tableName varchar(120);
	declare @systemSchema varchar(100);
	declare @IsClone int;

	if @nodeType<>12 return;

	--Get Version Info--
	select top (1) @rqeversion = RQEVersion,@schemaVersion=SchemaVersion,@version=replace(left(rqeversion,5),'.','') from RQEVersion order by RQEVersion desc, Build desc;
	set @snapshotName='Snapshot - RQE' + @rqeversion;
	set @systemSchema='RQE'+@version;

	--Get info for SnapshotInfo--
	exec absp_Util_GetDateString @currentDate output,'yyyymmddhhnnss';
	set @userName='Admin';
	select top (1) @currSkKey=Currsk_Key from FldrInfo where Curr_Node='Y';
	set @description='Snapshot created during migration';

	--0008541: In RQE 16 we need to verify that we are keeping snapshot results for only last two releases--
	if not exists (select 1 from  AvailableReport where ReportID >= 6000) return;


	-- Add a new entry to SnapshotInfo table.
	insert into SnapshotInfo
		(SnapshotName,CreateDate,UserName,DBSchemaVersion,RQEVersion,Currsk_Key,Description,Status,SystemGenerated)
		values (@snapshotName, @currentDate,@userName, @schemaVersion,@rqeVersion,@currSkKey,@description,'InProgress','Y');
	if @debug=1 exec absp_MessageEx 'SnapshotInfo record created..';

	--Get the snapshot key--
	select  @snapShotKey = IDENT_CURRENT ('dbo.SnapshotInfo');

	-- Create a new database schema for the snapshot.
	if @debug=1 exec absp_MessageEx 'Create a new database schema for the snapshot..';
	set @schemaName= 'Snapshot_' + dbo.trim(cast(@snapShotKey as varchar(20)));
	exec absp_Util_CleanupSchema @schemaName;
	set @sql='create schema ' + @schemaName;
	if @debug=1 exec absp_MessageEx @sql;
	exec(@sql);

	-- Copy all the tables into the new schema.
	if @debug=1 exec absp_MessageEx 'Transfer tables to new schema..';
	declare cursT cursor  for
		select TableName, 0 from systemdb.dbo.DictTbl where CF_DB in('Y','L') and AllowSnapShot='Y'
		union
		select CloneName, 1 from systemdb.dbo.DictTbl A inner join DictClon B
			on A.TableName=B.TableName and A.SYS_DB in('Y','L') and B.Sys_DB='N' and AllowSnapShot='Y';
	open cursT
	fetch cursT into @tablename, @IsClone
	while @@fetch_status=0
	begin
		if @tableName='CrolInfo' or @tableName='Reinsurer' or @tableName='ExchRate' or @tableName='CurrInfo'
		begin
			set @sql='select * into ' + @schemaName + '.' + @tableName + ' from dbo.' + @tableName
			exec(@sql)
		end
		else if @tableName='AvailableReport'
		begin
			-- Preserve Import reports in AvailableReport table
			set @sql='select * into ' + @schemaName + '.' + @tableName + ' from dbo.' + @tableName + ' where Status=''Available'' and ReportID >= 6000';
			exec(@sql)
			delete AvailableReport where ReportID >= 6000;
		end
		else
		begin
			if exists(select 1 from sys.tables where name=@tableName  and schema_id =SCHEMA_ID('dbo'))
			begin
				if (@IsClone = 1)
				begin
					--Get the tablescript from system before moving--
					exec absp_Util_CreateSysTableScript @sql2 out, @tableName ,'','',1;
				end
				else
				begin
					--Get the tablescript from DataDict before moving--
					exec absp_Util_CreateTableScript @sql2 out, @tableName ,'','',1;
				end

				--Move table to new schema--
				set @sql = 'alter schema ' + @schemaName + ' transfer  dbo.' + dbo.trim(@tableName);
				if @debug=1 exec absp_MessageEx @sql;
				exec(@sql)

				--Create empty table in dbo--
				if @debug=1 exec absp_MessageEx @sql2;
				exec (@sql2);
			end
		end

		fetch cursT into @tablename, @IsClone
	end
	close cursT
	deallocate cursT

	-- Create views for the new tables that are required from the systemdb snapshot schema.
	if exists(select 1 from systemdb.sys.schemas where name = @systemSchema)
	begin
		if @debug=1 exec absp_MessageEx 'Create views for systemdb tables..';
		declare cursV cursor  for select tableName from systemdb.dbo.DictTbl where SYS_DB in('Y','L') and AllowSnapShot='Y';
		open cursV
		fetch cursV into @tableName
		while @@fetch_status=0
		begin

			if exists (select 1 from sys.views where name=@tableName and  schema_name(schema_id)=@schemaName )
			begin
				set @sql='drop view ' + dbo.trim(@schemaName) + '.' + @tableName;
				execute(@sql);
			end

			if exists(select 1 from DictClon where tablename=@tableName)
				set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName +
					' as select * from systemdb.' + dbo.trim(@SystemSchema) + '.' + @tableName + '_S' +
					' union select * from ' + dbo.trim(@schemaName) +'.' + @tableName + '_U';
			else
				set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName + ' as select * from systemdb.' + @SystemSchema+'.' + @tableName;

			if @debug=1 exec absp_MessageEx @sql;
			execute(@sql);

			fetch cursV into @tableName;
		end;
		close cursV;
		deallocate cursV;
	end;

	-- Get the list of all child information (recursively) and update SnapshotMap table.
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
  	execute absp_PopulateChildList @nodeKey, @nodeType;
  	--Insert NodeKey
  	insert into SnapshotMap(SnapshotKey,NodeKey,NodeTYpe) values (@snapshotKey, @nodeKey, @nodeType);
  	--Get child treaty
  	insert into #NODELIST select Case_Key,30,Prog_Key,27 from #NodeList inner join CaseInfo on Prog_Key=Node_Key where node_Type=27
  	insert into SnapshotMap(SnapshotKey,NodeKey,NodeTYpe) select @snapshotKey,NODE_KEY,NODE_TYPE from #NODELIST order by NODE_TYPE desc;

	if @debug=1 exec absp_MessageEx 'Snapshot Map entry created..';

	--Update SnapshotInfo.SnapshotKey, SnapShotInfo.Staus--
	update SnapshotInfo set SchemaName = @schemaName , Status='Active' where SnapshotKey=@snapShotKey

	-- Delete enties from ReportsDone table. If we do not delete the entries from reports done then
	-- when we re-analyze the portfolios the planner will not plan all the steps correctly

	DELETE FROM ReportsDone
	 	FROM ReportsDone w
		INNER JOIN SnapshotMap sm
	  	ON w.NodeKey = sm.NodeKey and w.NodeType = sm.NodeType;


	exec absp_MessageEx 'Snapshot Created!';

end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

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
