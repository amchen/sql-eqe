if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_IsInvalidationRequired') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_IsInvalidationRequired;
end
go

create procedure absp_Migr_IsInvalidationRequired
	@batchJobKey int,
	@dbType varchar(3)
as

begin try

	set nocount on;

	declare @returnCode int;
	declare @targetDBVersion varchar(8);
	declare @dbName varchar(120);

	--Get the migration information
	select @dbName=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='dbName';
	select @targetDBVersion=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Target.RQEVersion';

	set @returnCode = 1;
	
	select @returnCode;
	return @returnCode;

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
	return 99;
end catch
