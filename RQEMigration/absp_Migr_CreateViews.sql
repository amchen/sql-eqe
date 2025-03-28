if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateViews') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_CreateViews;
end
go

create procedure absp_Migr_CreateViews
	@batchJobKey int,
	@dbType varchar(3)
as

begin try

	set nocount on;

	declare @returnCode int;

	if @dbType in ('EDB','IDB')
	begin
		exec absp_Util_CreateGenericViews 'systemdb';
		exec absp_Util_CreateGenericViews 'commondb';
	end
	if @dbType in ('COM')
	begin
		exec absp_Util_CreateGenericViews 'systemdb';
	end
	if @dbType in ('RDB')
	begin
		exec absp_CreateRDBViews;
	end

	set @returnCode = 0;

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
