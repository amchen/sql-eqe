if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_UpdateStatusForFailedJobs') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateStatusForFailedJobs
end
go

CREATE procedure [dbo].[absp_UpdateStatusForFailedJobs]  @batchJobKey int
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:      The procedure updates BatchJobStep.Status in case of a failure of a job step. 
 
Returns:    Nothing

====================================================================================================
</pre>
</font>
##BD_END

*/
begin
      set nocount on

     begin transaction
           update commondb..BatchJobStep set Status='C'
                 where BatchJobKey=@batchJobKey and Status in ('W','WL','PS','RS','RW') and EngineName <> 'POST_PROCESSOR';
     commit;
     
end


