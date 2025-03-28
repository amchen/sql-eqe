if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_LogIt') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_LogIt
end

go

create procedure absp_Util_LogIt @log_msg varchar(max) ,@logLevel int ,@procedure_name char(255) ,@log_file varchar(max) = ''
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MS SQL Server
Purpose:

This procedure writes message to a fully qualified log file

Returns: @retCode = 0 on success, non-zero on failure

====================================================================================================

</pre>
</font>
##BD_END

##PD  @log_msg        ^^ The log message. The log message will be formatted to display the date, ClientId, procedure_name, and log level
##PD  @logLevel       ^^ The log level for the message. If the logLevel is equal to or less than the DEFAULT_LOG_LEVEL then the log will be written to the log file other wise the log_msg will be ignored.( Valid Values: 0 - No Logging //1 - Informational Logging //2 - High Level Debug //3 - Low Level Debug //4 - All)
##PD  @procedure_name ^^ Name of the procedure that is trying to log the message.
##PD  @log_file       ^^ Can be drive letter or UNC path (d:\\mypath\\myfile), no file extension

##RD  @retCode ^^ Returns 0 on success, non-zero on failure.
*/
 ----------------------------------------------------
begin

   set nocount on
  /*
  This function writes the msg to a fully qualified log file,

  Parameters:     log_msg  - 	The log message. The log message will be formatted to display the
  date, ClientId, procedure_name, and log level
  [DateTime][ClientID][Procedure Name][Log Level] -- Message

  logLevel - 	The log level for the message. If the logLevel is equal to or less than
  the DEFAULT_LOG_LEVEL then the log will be written to the log file other
  wise the log_msg will be ignored.

  Valid Values:
  0 - No Logging
  1 - Informational Logging
  2 - High Level Debug
  3 - Low Level Debug
  4 - All

  procedure_name - Name of the procedure that is trying to log the message.

  log_file 	   - Can be drive letter or UNC path (d:\\mypath\\myfile), no file extension

  Returns:        0 on success, non-zero on failure
  */
   declare @retCode int
   declare @len int
   declare @msg2 varchar(255)
   declare @i int
   declare @client_id varchar(255)
   declare @logFileName varchar(max)
   declare @debugMode varchar(1)
   declare @debug_log_level int
   declare @formatted_log_message varchar(max)
   declare @default_log_level int
   declare @createDt char(25)

  -- Set the default_log_level
  -- This variable will be used to Filter log messages.
  -- The logging is dependent on this value. If set to 0 nothing will be logged. If set to 4 we will
  -- log all messages.
   set @default_log_level = 1
   set @retCode = 0
   set @debug_log_level = 0

   -- set the variables to default value
   set @client_id = 'UNKNOWN'
   set @debugMode = 0
   set @logFileName = @log_file

  -- Get the Client_Id, Log_File_Name, Debug_Mode from connection level variable
   if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##CONNINFO')
   begin
   		--Fixed SDG__00024966: Logging does not work for Jobs started by SQL Agent
	    if exists ( select 1 from ##CONNINFO where SESSION_ID = @@SPID)
		  	select  @client_id = ID,  @logFileName = LOG_FILE_NAME, @debugMode = DEBUG_MODE from  ##CONNINFO where SESSION_ID = @@SPID
		else if exists (select 1 from RQEVersion where DBType = 'EDB')
		  	select  @client_id = ID,  @logFileName = LOG_FILE_NAME, @debugMode = DEBUG_MODE from  ##CONNINFO where SESSION_ID =  -1
		else
			select  @client_id = ID,  @logFileName = LOG_FILE_NAME, @debugMode = DEBUG_MODE from  ##CONNINFO where SESSION_ID =  -2
   end

  -- If we are running in DEBUG_MODE then check if the procedure has a overriding log_level
  -- in LOGITTBL
   if(@debugMode = 1)
   begin
      if exists(select top 1 1 from LOGITTBL where PROC_NAME = @procedure_name)
      begin
         select   @debug_log_level = isNull(LOG_LEVEL,@default_log_level)  from LOGITTBL where PROC_NAME = @procedure_name
      -- Now set the DEFAULT_LOG_LEVEL to the Debug_log_level for this procedure
         set @default_log_level = @debug_log_level
      end
   end
  -- Check the Log level
   if(@logLevel <= @default_log_level)
   begin
    -- Format the message
      exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
      set @formatted_log_message = '['+ @createDt +']'
     -- set @formatted_log_message = @formatted_log_message+' ['+@client_id+']'+' ['+@procedure_name+']'+' ['+rtrim(ltrim(str(@logLevel)))+'] -- '
	  set @formatted_log_message = @formatted_log_message+' ['+ rtrim(ltrim(@client_id)) +']'+' ['+ rtrim(ltrim(@procedure_name)) +']'+' ['+rtrim(ltrim(str(@logLevel)))+'] -- '
      set @len = 255 -len(@formatted_log_message)
      set @formatted_log_message = @formatted_log_message+rtrim(ltrim(@log_msg))
      if len(@formatted_log_message) <= @len
      begin
         set @msg2 = @formatted_log_message
         print @msg2

      -- check if we have a log file name set, if empty log the message in database console
         if(len(rtrim(ltrim(@logFileName)))) <> 0
         begin
            set @retCode = dbo.absxp_LogIt(@logFileName,@msg2);
         end
      end
      else
      begin
         set @i = 1
         while @i <= len(@formatted_log_message)
         begin
            set @msg2 = substring(@formatted_log_message,@i,@len)
            print @msg2
        -- check if we have a log file name set, if empty log the message in database console
            if(LEN(rtrim(ltrim(@logFileName)))) <> 0
            begin
               set @retCode = dbo.absxp_LogIt(@logFileName,@msg2);
            end
            set @i = @i+@len
         end
      -- Add a empty line after a multi-line message
         if(len(rtrim(ltrim(@logFileName)))) <> 0
         begin
            set @retCode = dbo.absxp_LogIt(@logFileName,'');
         end
      end
   end
   return @retCode
end