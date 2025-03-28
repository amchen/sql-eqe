if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_UpdateTreaty') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_UpdateTreaty;
end
go

create procedure absp_Migr_UpdateTreaty
	@batchJobKey int
as

begin try

	set nocount on;
	declare @sql varchar(max);
	declare @serverName varchar(500);
	declare @lknServerName varchar(500);
	declare @instanceName varchar(500);
	declare @userName varchar(100);
	declare @password varchar(100);
	declare @sourceDB varchar(120);
	declare @nodeKey  int;
	declare @nodeType int;
	declare @status int;
	
	--Fixed defect 6380,6396
	return
	
	-- Get values from BatchProperties table based on batchJobKey
	select @serverName=KeyValue   from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBServer';
	select @instanceName=KeyValue from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.DBInstance';
	select @userName=KeyValue     from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.User';
	select @password=KeyValue     from BatchProperties where BatchJobKey=@batchjobKey and KeyName='Source.Password';
	select @sourceDB=KeyValue     from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.DBName';
	select @nodeKey=KeyValue      from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.NodeKey';
	select @nodeType=KeyValue     from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Source.NodeType';

	-- Create link server to Source.DBName
	set @lknServerName='Svr_' + dbo.trim(cast(@batchJobKey as varchar(20)));
	if not exists(select 1 from master.sys.servers where name=@lknServerName and data_source= dbo.trim(@serverName) and catalog= @sourceDB)
	begin
		exec @status=absp_CreateLinkedServer @lknServerName,@serverName,@instanceName,@sourceDB,@userName,@password;
		if @status=1 return; --Error creating linked server
		exec absp_MessageEx  'Created Linked server';
	end
	
	
	-- Clone Source.DBName.COBL (COB_ID, COB_ID, U_COB_ID) to MigrLineOfBusinessRemap (OldID, NewID, Name)
	create table #MigrLineOfBusinessRemap (OldID int, NewID int, Name varchar(254)  COLLATE SQL_Latin1_General_CP1_CI_AS);
	set @sql='insert into #MigrLineOfBusinessRemap select COB_ID, COB_ID, U_COB_ID from ' + @lknServerName + '.[' + @sourceDB + '].dbo.COBL' ;
	exec(@sql)
	
	-- Update MigrLineOfBusinessRemap.NewID with LineOfBusiness.LineOfBusinessID where MigrLineOfBusinessRemap.Name = LineOfBusiness.Name
	update #MigrLineOfBusinessRemap set NewID=LineOfBusinessID
		from #MigrLineOfBusinessRemap A inner join LineOfBusiness B
		on A.Name=B.Name
	
	-- Clone Source.DBName.TRTYL (TREATY_ID, TREATY_ID, U_TR_ID) to MigrTreatyRemap (OldID, NewID, Name)
	create table #MigrTreatyRemap (OldID int, NewID int, Name varchar(254)  COLLATE SQL_Latin1_General_CP1_CI_AS)
	set @sql='insert into #MigrTreatyRemap select TREATY_ID, TREATY_ID, U_TR_ID from ' + @lknServerName + '.[' + @sourceDB + '].dbo.TRTYL'; 
	exec(@sql)

	-- Update #MigrTreatyRemap.NewID with TreatyTag.TreatyTagID where MigrTreatyRemap.Name = TreatyTag.Name
	update #MigrTreatyRemap set NewID=TreatyTagID
		from #MigrTreatyRemap A inner join TreatyTag B
		on A.Name=B.Name
		
	-- Clone Source.DBName.COBMAP to AportRtroLayerMap (drop COB_ID column)
	--Cloned in absp_Migr_AprtParts since we need to renumber AportKey,RtroKey,RtLayrKey--
	
	
	-- Clone Source.DBName.CaseCob to CaseLineOfBusiness
	--Cloned in absp_Migr_CaseParts--
	--Resolve Ids--
	update CaseLineOfBusiness set LineOfBusinessID=NewID
		from CaseLineOfBusiness A 
		inner join #MigrLineOfBusinessRemap B on A.LineOfBusinessID=B.OldId
		inner join LineOfBusiness C on B.Name=C.Name
		
	
	-- Clone Source.DBName.RtroCob to RtroLineOfBusiness
	--Cloned in absp_Migr_AportParts--
	--Resolve Ids--
	update RtroLineOfBusiness set LineOfBusinessID=NewID
		from RtroLineOfBusiness A 
		inner join #MigrLineOfBusinessRemap B on A.LineOfBusinessID=B.OldId
		inner join LineOfBusiness C on B.Name=C.Name
	
	-- Clone Source.DBName.CaseLayr to CaseLayr
	--Cloned in absp_Migr_CaseParts--
	--Resolve Ids--
	update CaseLayr set Treaty_ID=NewID
		from CaseLayr A 
		inner join #MigrTreatyRemap B on A.Treaty_ID=B.OldId
		inner join TreatyTag C on B.Name=C.Name
		
		
	-- Clone Source.DBName.RtroLayr to RtroLayr
	--Cloned in absp_Migr_AportParts--
	--Resolve Ids--
	update RtroLayr set Treaty_ID=NewID
		from RtroLayr A 
		inner join #MigrTreatyRemap B on A.Treaty_ID=B.OldId
		inner join TreatyTag C on B.Name=C.Name
		
	
	--Drop linked server
	if exists(select 1 from master.sys.sysservers where srvName=@lknServerName)
	begin
		exec sp_dropserver @lknServerName, 'droplogins';
	end


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
