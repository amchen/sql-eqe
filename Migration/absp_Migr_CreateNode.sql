if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateNode') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_CreateNode;
end
go

-- This procedure creates and copies a WCe database source node to an RQE database
-- This procedure is executed from within the destination RQE database
-- All information needed can be obtained from BatchProperties table with @batchJobKey

create procedure absp_Migr_CreateNode
	@batchJobKey int
as

begin try

	set nocount on;

	declare @serverName varchar(500);
	declare @lknServerName varchar(500);
	declare @instanceName varchar(500);
	declare @userName varchar(100);
	declare @password varchar(100);
	declare @sourceDB varchar(120);
	declare @nodeKey  int;
	declare @nodeType int;
	declare @nodeExists int;
	declare @dt varchar(25);
	declare @srcCurrSkKey int;
	declare @newCurrSkKey int;
	declare @sql nvarchar(max);
	declare @status int;
	declare @whereClause varchar(255);
	declare @newKey int;
	declare @newCFRefKey int;
	declare @msgTxt varchar(1000);
	declare @newPortName varchar(130);
	declare @fieldValueTrios varchar(8000);
	declare @tabSep char(2);
	declare @newNodeKey int;
	declare @newFolderKey int;
	declare @createDt varchar(14);
	declare @usrKey int;
	declare @nodeName varchar(130);
	declare @targetDB varchar(120);

------------------------------
declare @context binary(128);
set @context = cast(@batchjobKey as binary(128));
set context_info @context;
------------------------------

	execute  absp_GenericTableCloneSeparator @tabSep output;

	--Query the BatchProperties table to get the WCE database information
	select @serverName=KeyValue   from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBServer';
	select @instanceName=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBInstance';
	select @userName=KeyValue     from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.User';
	select @password=KeyValue     from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.Password';
	select @sourceDB=KeyValue     from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.DBName';
	select @nodeKey=KeyValue      from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.NodeKey';
	select @nodeType=KeyValue     from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.NodeType';
	select @targetDB=KeyValue     from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Target.DatabaseName';

	--Create a link server to the WCe database.
	set @lknServerName='WCEDBSvr_' + dbo.trim(cast(@batchJobKey as varchar(20)));
	if not exists(select 1 from master.sys.servers where name=@lknServerName and data_source= dbo.trim(@serverName) and catalog= @sourceDB)
	begin
		exec @status=absp_CreateLinkedServer @lknServerName,@serverName,@instanceName,@sourceDB,@userName,@password;
		if @status=1 return; --Error creating linked server
		exec absp_MessageEx  'Created Linked server';
	end

	--Get source PPort or Program LONGNAME
	if (@nodeType=2)
		set @sql='select @nodeName=LONGNAME from @lknServerName.[@sourceDB].dbo.PPRTINFO where PPORT_KEY=@nodeKey';
	else
		set @sql='select @nodeName=LONGNAME from @lknServerName.[@sourceDB].dbo.PROGINFO where PROG_KEY=@nodeKey';
	set @sql = replace(@sql, '@lknServerName', @lknServerName);
	set @sql = replace(@sql, '@sourceDB', @sourceDB);
	set @sql = replace(@sql, '@nodeKey', cast(@nodeKey as varchar(30)));
	exec absp_MessageEx @sql;
	execute sp_executesql @sql,N'@nodeName varchar(120) output',@nodeName output;

	-- Check if the node has already been migrated
	set @nodeName = 'RQE_'+@nodeName;
	set @status = -1;
	if (@nodeType=2)
		set @sql = 'select @status=1,@newNodeKey=Pport_Key from [@targetDB].dbo.PPRTINFO where LONGNAME=''@nodeName''';
	else
		set @sql = 'select @status=1,@newNodeKey=Prog_Key  from [@targetDB].dbo.PROGINFO where LONGNAME=''@nodeName''';
	set @sql = replace(@sql, '@targetDB', @targetDB);
	set @sql = replace(@sql, '@nodeName', @nodeName);
	exec absp_MessageEx @sql;
	execute sp_executesql @sql,N'@status int output,@newNodeKey int output',@status output,@newNodeKey output;

	if (@status = 1)
		exec absp_MessageEx 'Node has already been cloned';
	else
	begin
		--All these steps will execute once and NOT each time we migrate different portfolios

		--Check nodeType since we converted Program to Account (RPort to RAP)
		if (@nodeType = 7)
			set @nodeType = 27;

 		-- Clone currency schema and exchange rates
		--Get Source CF_REF_KEY
		set @sql='select @srcCurrSkKey=CurrSk_Key from ' + @lknServerName + '.[' + @sourceDB + '].dbo.FldrInfo where CURR_NODE=''Y''';
		exec absp_MessageEx @sql;
		execute sp_executesql @sql,N'@srcCurrSkKey int output',@srcCurrSkKey output;
		exec absp_MessageEx @srcCurrSkKey;

		--Create CFLDRINFO row if not exists--
		--CFLDRINFO row may not exist in 3.16--
		if not exists(select 1 from CFldrInfo where DB_NAME=@targetDB)
		begin
			exec absp_Util_GetDateString @dt output,'yyyymmddhhnnss'
			insert into CFldrInfo (Folder_Key,LongName,Create_Dat,Create_By,Group_Key,Currsk_Key,Attrib,DB_NAME)
				values (1,@targetDB,@dt,1,1,1,32,@targetDB)
			exec absp_MessageEx 'Created CFldrinfo record';
			select @newCFRefKey=Max(cf_ref_key) from CfldrInfo
		end
		else
			select @newCFRefKey = cf_ref_key from CFldrInfo where DB_NAME=@targetDB;

		exec absp_Util_GetDateString @createDt output, 'yyyymmddhhnnss';

		--Since this is  a new database, it will have FolderKey=1
		update FLDRINFO set LONGNAME= @targetDB, cf_ref_Key=@newCFRefKey, Create_Dat = @createDt where folder_Key=1;

		-- Mark the Attrib column to MIGRATION_IN_PROGRESS (use the procedure to do this update; do not update the column directly).
		exec absp_InfoTableAttribSetCurrencyMigrationInProgress @newCFRefKey,1;
		exec absp_InfoTableAttribSetCurrencyNodeAvailable  @newCFRefKey,0;

		--Clone Currency schema
		--delete rows first
		delete from ExchRate where CurrSk_Key > 1;
		delete from CurrInfo where CurrSk_Key > 1;

		select @usrKey = UserKey from BatchJob where BatchJobKey=@batchJobKey;
		set @whereClause='CurrSk_Key=' + dbo.trim(cast(@srcCurrSkKey as varchar(10) ));
		set @fieldValueTrios = 'int'+@tabSep+'Create_By'+@tabSep+cast(@usrKey as varchar(20));
		print @fieldValueTrios;
		execute @newKey=absp_Migr_TableCloneRecords 'CurrInfo',1,@whereClause,'', @lknServerName, @sourceDB;
		exec absp_MessageEx 'Created CurrInfo record';

		set @fieldValueTrios = 'int'+@tabSep+'CurrSk_key'+@tabSep+dbo.trim(cast(@newKey as varchar(20)));
		execute absp_Migr_TableCloneRecords 'ExchRate',0,@whereClause,@fieldValueTrios, @lknServerName, @sourceDB;
		exec absp_MessageEx 'Created exchange rates';

		update FLDRINFO set CurrSk_key = @newKey where folder_Key=1;
		update CFLDRINFO set folder_Key=1, CurrSk_key = @newKey where DB_NAME=@targetDB;

		--Copy all Crolinfo rows so no need to renumber
		truncate table CrolInfo;
		execute absp_Migr_TableCloneRecords 'CrolInfo',0,'','', @lknServerName, @sourceDB;
		exec absp_MessageEx 'Created CrolInfo rows';

		-- Clone Treeview and all node-related data
		exec @newNodeKey = absp_Migr_TreeviewClone @batchJobKey, @lknServerName, @sourceDB, @nodeKey, @nodeType, 1;
	end

	---- Update/Insert the new Target.NodeKey in BatchProperties
	if exists(select 1 from BatchProperties where BatchJobKey = @batchJobKey and KeyName='Target.NodeKey')
		update BatchProperties set KeyValue = @newNodeKey where BatchJobKey = @batchJobKey and KeyName='Target.NodeKey';
	else
		insert into BatchProperties(BatchJobKey,KeyName,KeyValue) values( @batchJobKey,'Target.NodeKey',@newNodeKey);

	-- Mark BKPROP and VERSION table

------------------------------
set context_info 0x00;
------------------------------

end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMessage varchar(4000);

	select @ProcName = object_name(@@procid);
    select
		@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMessage='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMessage,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
end catch

--exec absp_Migr_CreateNode 1
