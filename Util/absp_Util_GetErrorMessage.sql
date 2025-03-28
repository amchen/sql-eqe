if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetErrorMessage') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetErrorMessage
end
go

CREATE PROCEDURE absp_Util_GetErrorMessage @errorMessage varchar(4000), @callingProc varchar(100)
AS
BEGIN

Declare @msg as varchar(1000);
Declare @module as varchar(100);
Declare @ErrorSeverity varchar(100);
Declare @ErrorState int;
Declare @message varchar(4000);


SELECT	@module= isnull(ERROR_PROCEDURE(),@callingProc),
        @msg='"'+ERROR_MESSAGE()+'"'+
       		'  Line: '+cast(ERROR_LINE() as varchar(10))+
		'  No: '+cast(ERROR_NUMBER() as varchar(10))+
		'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
       		'  State: '+cast(ERROR_STATE() as varchar(10)),
        	@ErrorSeverity=ERROR_SEVERITY(),
        	@ErrorState=ERROR_STATE(),
        	@message='Exception: Top Level '+@callingProc+'. Occurred in '+@module+'. Error: '+@msg
        
	set @errorMessage = @message;
END