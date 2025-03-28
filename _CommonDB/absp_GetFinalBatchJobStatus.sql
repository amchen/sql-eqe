if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetFinalBatchJobStatus') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetFinalBatchJobStatus
end
go

create procedure absp_GetFinalBatchJobStatus @batchJobKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:          MSSQL
Purpose:          This procedure will return the batchjob status for all running batch jobs.

Returns:      None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

       
      set nocount on

      if not exists (select 1 from batchJobStep where BatchJobKey=@batchJobKey and Status <> 'S' and EngineName <> 'POST_PROCESSOR')
	     select 'S' as status;
      else if exists( select 1 from batchJobStep where BatchJobKey=@batchJobKey and Status='F')
	     select 'F' as status;
      else if exists( select 1 from batchJobStep where BatchJobKey=@batchJobKey and Status='C')
	     select 'C' as status;
      else 
	     select 'Unknown' as status


end try

begin catch
       declare @ProcName varchar(100),
                     @msg as varchar(1000),
                     @module as varchar(100),
                     @ErrorSeverity varchar(100),
                     @ErrorState int,
                     @ErrorMsg varchar(4000);

       select @ProcName = object_name(@@procid);
       select @module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
                     '  Line: '+cast(ERROR_LINE() as varchar(10))+
                           '  No: '+cast(ERROR_NUMBER() as varchar(10))+
                           '  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
                     '  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
       raiserror (
              @ErrorMsg,    -- Message text
              @ErrorSeverity,      -- Severity
              @ErrorState          -- State
       )
       return 99;
end catch


