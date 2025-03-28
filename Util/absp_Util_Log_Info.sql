if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_Log_Info') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_Log_Info
end
go

create procedure absp_Util_Log_Info @log_msg varchar(max), @procedure_name char(255), @log_file varchar(max) = '' 
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls another procedure absp_Util_LogIt which writes the given message to the specified log file.


Returns: Nothing.


====================================================================================================
</pre>
</font>
##BD_END 

##PD  @log_msg ^^  The message that is to be logged.
##PD  @procedure_name ^^ The procedure name for which the log is to be craeted having loglevel 1 in LOGITTBL.
##PD  @log_file ^^ A valid log file path.



*/
 ----------------------------------------------------
begin
 
   set nocount on
   
 /*

  This procedure will call absp_Util_LogIt with Log_Level = 1
  */
   execute absp_Util_LogIt @log_msg,1,@procedure_name,@log_file
end



