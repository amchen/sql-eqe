if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_PreMigration') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_PreMigration;
end
go

create procedure absp_Migr_PreMigration
	@errorMessage varchar(max) output,
	@batchJobKey int,
	@dbType varchar(3)
as

begin try

	set nocount on;

	declare @returnCode int;
	declare @returnCode1 int;
	declare @returnCode2 int;
	declare @targetDBVersion varchar(8);
	declare @dbName varchar(120);
	declare @sql varchar(max);
	declare @logit varchar(max);

	--Get the migration information
	select @dbName=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='dbName';
	select @targetDBVersion=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Target.RQEVersion';

	if (@dbType = 'IDB')
	begin
		select @dbName = @dbName + '_IR';
	end

	exec @returnCode1 = absp_Migr_LoadProcedure @dbName, @targetDBVersion, '', 'TDMRequired', '', 0;
	exec @returnCode2 = absp_Migr_LoadProcedure @dbName, @targetDBVersion, '', 'RQEMigration', '', 0;
	set @returnCode = @returnCode1 + @returnCode2;
	if @returnCode > 0 return @returnCode;

	set @logit = 'exec absp_Migr_LoadProcedure @dbName=' + @dbName + ', @targetDBVersion=' + @targetDBVersion;
	set @sql   = 'absp_Migr_LogIt ''' + @logit + '''';

	set @sql = replace(@sql, '''', '''''');
	set @sql = 'use ' + quotename(@dbName) + '; exec(''' + @sql + ''')';
	execute(@sql);	-- do it!

	set @errorMessage = '';
	set @returnCode = 0;

	return @returnCode;

end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

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
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch

--exec absp_Migr_PreMigration 1, 'EDB';
