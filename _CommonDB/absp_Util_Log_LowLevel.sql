if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_Log_LowLevel') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_Log_LowLevel
end
go

create procedure absp_Util_Log_LowLevel @log_msg varchar(max), @procedure_name char(255), @log_file varchar(max) = '' 
as
/*
##FND_BEGIN absp_Util_Log_LowLevel ^^ 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MS SQL
Purpose:

This function calls another function absp_Util_LogIt which writes the given message to the specified log file.


Returns: Nothing.


====================================================================================================
</pre>
</font>
##FND_END 

##PD  @log_msg ^^  A message that is to be logged.
##PD  @procedure_name ^^ Any procedure name with loglevel 3 in LOGITTBL.
##PD  @log_file ^^ A valid log file path.



*/
 ----------------------------------------------------
begin
 
   set nocount on
   
 /*

  This procedure will call absp_Util_LogIt with Log_Level = 3
  */
   execute absp_Util_LogIt @log_msg,3,@procedure_name,@log_file
end


