if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateExposure') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_CreateExposure;
end
go

create procedure absp_Migr_CreateExposure
	@batchJobKey int,
	@nodeKey int = -1,
	@nodeType int = -1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:
This procedure will create all the necessary entries in ExposureInfo, ExposueFile and ExposureTemplate tables.
The procedure will accept the BatchJobKey as parameters and will read all the other information from BatchProperties table.
It will also create the schema which will later be used by the Import process.
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD @batchJobKey ^^  Batch job key
##PD @nodeKey ^^  Node type
##PD @nodeType ^^  Node type
*/
begin try

	set nocount on;
	declare @usrGrpKey int;
	declare @usrKey int;
	declare @createDt varchar(14);
	declare @exposureKey int;
	declare @cnt int;
	declare @sourceCategory varchar(500);
	declare @kname varchar(20);
	declare @sourceDB varchar(120);
	declare @serverName varchar(200);
	declare @portfolioName varchar(200);
	declare @orSrcName varchar(8000);
	declare @tmpOrSrcName varchar(8000);
	declare @templateName varchar(120);
	declare @pKey int
	declare @pType int
	declare @sourceViewName varchar(500);

	exec absp_Util_GetDateString @createDt output, 'yyyymmddhhnnss';

	--Get the user and group key--
	select @usrKey = UserKey from BatchJob where BatchJobKey=@batchJobKey;
	select @usrGrpKey = Group_Key from UsrGpMem where User_Key=@usrKey;

	--Insert ExposureInfo record--
	insert into ExposureInfo
		(Status,ImportStatus,GeocodeStatus,ReportStatus,GroupKey,Attrib,CreateDate,ModifyDate,CreatedBy,ModifiedBy,isBrowserDataGenerated)
		values
		('Submitted','','','',@usrGrpKey,0,@createDt,NULL,@usrKey,@usrKey,'N');

	--Get the new exposureKey--
	select  @exposureKey = IDENT_CURRENT ('ExposureInfo');

	--Insert ExposureFile record--
	select @sourceDB = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = 'Source.DBName';
	select @serverName = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = 'Source.DBServer';
	select @portfolioName = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = 'Source.PortfolioName';
	select @nodeKey = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = 'Target.NodeKey';
	select @nodeType = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = 'Source.NodeType';
	if @nodeType=7 	set @nodeType=27

	set @tmpOrSrcName = dbo.trim(@serverName) + ':' + dbo.trim(@sourceDB) + ':' + dbo.trim(@portfolioName);

	set @cnt = 1;

	while (@cnt <= 9)
	begin
		set @kname = dbo.trim(cast(@cnt as varchar(2))) + '.Category';
		select @sourceCategory = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = @kname;
		set @kname = dbo.trim(cast(@cnt as varchar(2))) + '.ViewName';
		select @sourceViewName = KeyValue from BatchProperties where BatchJobKey = @batchJobKey and KeyName = @kname;
		set @orSrcName = @tmpOrSrcName + ':' + dbo.trim(@sourceViewName);
		insert into ExposureFile
			(ExposureKey,SourceID,SourceType,OriginalSourceName,SourceName,SourceCategory,TableName,Status,ReadyForUse,Delimiter,StartHeaderRow,EndHeaderRow,FirstDataRow)
			values
			(@exposureKey,@cnt,'T',@orSrcName,NULL,@sourceCategory,NULL,'Submitted','Y','Tab',1,1,2);
		set @cnt = @cnt + 1;
	end

	--Insert ExposureTemplate record--
	set @templateName='System Use - Database Migration from WCe 3.16';
	insert into ExposureTemplate (ExposureKey,TemplateName,TemplateType,TemplateXML,CreatedVersion)
		select @exposureKey,TemplateName,TemplateType,TemplateXML,TemplateVersion
			from TemplateInfo
			where TemplateName=@templateName;

	-- Insert ExposureMap record
	if not exists(select 1 from ExposureMap where ExposureKey=@exposureKey and ParentKey=@nodeKey and ParentType=@nodeType)
		insert ExposureMap(ExposureKey,ParentKey,ParentType) values (@exposureKey,@nodeKey,@nodeType);

	-- Update/Insert the new Target.ExposureKey in BatchProperties
	if exists(select 1 from BatchProperties where BatchJobKey = @batchJobKey and KeyName='Target.ExposureKey')
		update BatchProperties set KeyValue = @exposureKey where BatchJobKey = @batchJobKey and KeyName='Target.ExposureKey'
	else
		insert into BatchProperties(BatchJobKey,KeyName,KeyValue) values( @batchJobKey,'Target.ExposureKey',@exposureKey)

	-- Mark BKPROP and VERSION table

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
