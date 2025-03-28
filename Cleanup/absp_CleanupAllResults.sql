if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanupAllResults') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupAllResults;
end
go

create procedure absp_CleanupAllResults as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure cleans up EDB tables when a fresh IDB is used.
Returns:	Nothing
====================================================================================================
</pre>
</font>
##BD_END
*/
begin

   set nocount on;

   declare @msg varchar(max);

   ----- Delete LOGS where JOB_TYPE = 0 -----
   -- Fixed SDG__00024343 - Invalidation of Logs tables is not correctly done
   set @msg = 'Delete Table LOGS where JOB_TYPE = 0';
   exec absp_MessageEx @msg;
   --delete from LOGS where JOB_TYPE = 0;
   set @msg = 'Cleanup completed for LOGS';
   exec absp_MessageEx @msg;

end
-- exec absp_CleanupAllResults
