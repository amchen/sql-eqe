if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetErrorInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetErrorInfo
end
go

CREATE PROCEDURE absp_Util_GetErrorInfo @callingProc varchar(100)
AS
BEGIN
DECLARE @msg as varchar(1000), @module as varchar(100),@ErrorSeverity varchar(100),@ErrorState int,@ErrorMessage varchar(4000)
    SELECT
		@module= isnull(ERROR_PROCEDURE(),@callingProc),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMessage='Exception: Top Level '+@callingProc+'. Occurred in '+@module+'. Error: '+@msg
	EXEC absp_Util_LogIt @msg, 1, @module
	RAISERROR (
		@ErrorMessage,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
END
