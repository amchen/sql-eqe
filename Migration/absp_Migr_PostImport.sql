if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_PostImport') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_PostImport;
end
go

create procedure absp_Migr_PostImport
	@exposureKey int
as

begin try

	set nocount on;

	declare @batchJobKey int;

	--Get the batchJobKey
	select @batchJobKey=max(BatchJobKey) from BatchProperties where KeyName='Target.ExposureKey' and KeyValue=@exposureKey and BatchJobKey in
		( select BatchJobKey from BatchProperties where KeyName='Target.DatabaseName' and KeyValue=DB_NAME() );

	--If batchJobKey is NULL, this is NOT a migration import job
	if @batchJobKey IS NOT NULL
	begin
		exec absp_Migr_UpdateTreaty @batchJobKey;
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
