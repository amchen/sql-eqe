if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsBackupInProgress') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsBackupInProgress
end
go

create procedure ----------------------------------------------------
absp_Util_IsBackupInProgress  
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure checks if any backup process is in progress  and returns 1 if it
is in progress or 0 if not.

Returns:       1 if backup is in progress, 0 if no backup is in progress.

====================================================================================================
</pre>
</font>
##BD_END 

##RD @ret_Status ^^ An integer value 1 if backup is in progress, 0 if no backup is in progress. 
*/
as
begin

   set nocount on
   
  --  Returns 1 if backup is inProgress
  --  Returns 0 if backup is NOT inProgress
   declare @ret_Status int
   set @ret_Status = 0
   if exists( select 1 from SYSCOLUMNS where object_name(id)= 'BKPROP' and NAME = 'BK_KEY')
   begin
      if exists(select 1 from BKPROP where BK_KEY = 'inProgress')
      begin
         execute absp_Util_Log_LowLevel 'absp_Util_IsBackupInProgress: Yes','absp_Util_IsBackupInProgress'
         set @ret_Status = 1
      end
      else
      begin
         execute absp_Util_Log_LowLevel 'absp_Util_IsBackupInProgress: No','absp_Util_IsBackupInProgress'
         set @ret_Status = 0
      end
   end
   return @ret_Status 
end




