if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckAndDeleteLogFile') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckAndDeleteLogFile
end

go
create procedure absp_Util_CheckAndDeleteLogFile as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will check if the Log file exceeded the max log file size in BKPROP
If the file size is greater than the size specified then delete the file. The log
file will get created the next time we try to log any message.

Returns:        Returns 0 .                  
====================================================================================================
</pre>
</font>
##BD_END

##RD  	@rc	^^  Returns 0 .

*/
begin

   set nocount on
   
  /*
  This procedure will check if the Log file exceeded the max log file size in BKPROP
  If the file size is greater than the size specified then delete the file. The log
  file will get created the next time we try to log any message.

  Returns 0 for success, non-zero for failure

  */
   declare @rc int
   declare @logFileName char(255)
   declare @maxFileSize varchar(100)
   declare @actualFileSize int
   declare @msg varchar(max)
   declare @retry int
   set @rc = 0
   set @retry = 0
   while(@retry < 3)
   begin
      if exists(select 1 from RQEVersion where DBType = 'EDB')
      begin
         select   @logFileName = BK_VALUE  from BKPROP where BK_KEY = 'DBLog.MasterLogFile'
         select   @maxFileSize = BK_VALUE  from BKPROP where BK_KEY = 'DBLog.MaxFileSize'
      end
      else
      begin
         select   @logFileName = BK_VALUE  from BKPROP where BK_KEY = 'DBLog.ResultLogFile'
         select   @maxFileSize = BK_VALUE  from BKPROP where BK_KEY = 'DBLog.MaxFileSize'
      end
      execute @actualFileSize = absp_Util_GetFileSizeMB @logFileName
     -- Leave loop
      if(@actualFileSize >= cast(@maxFileSize as varchar(10)))
      begin
         execute @rc =absp_Util_DeleteFile @logFileName
         set @msg = 'Truncated log file since file size was = '+rtrim(ltrim(str(@actualFileSize)))+' MB. Maximum Log File size allowed = '+rtrim(ltrim(str(@maxFileSize)))+' MB.'
         execute absp_Util_Log_Info @msg,'absp_Util_CheckAndDeleteLogFile',@logFileName
         set @retry = 4
      end
    -- If the @actualFileSize < 0 it means either the file path is wrong or some other 
    -- processes is accessing the log file. Sleep for a second and try again. 
    -- Try 3 times the quit.
      if(@actualFileSize < 0)
      begin
         set @msg = 'Failed to truncate log file since file size returned = '+rtrim(ltrim(str(@actualFileSize)))+' MB. Sleeping for 1 second'
         execute absp_Util_Log_Info @msg,'absp_Util_CheckAndDeleteLogFile',@logFileName
         execute absxp_sleep 1000
      end
      set @retry = @retry+1
   end
   return @rc
end
