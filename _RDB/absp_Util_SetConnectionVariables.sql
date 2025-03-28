if exists ( select 1 from sysobjects where name = 'absp_Util_SetConnectionVariables' and type = 'P' ) 
     drop procedure absp_Util_SetConnectionVariables;
go
----------------------------------------------------
create procedure absp_Util_SetConnectionVariables 
    @id_val varchar(255),
    @log_file varchar(max),
    @debug_mode_val varchar(1)
 /*
 ##BD_BEGIN
 <font size ="3"> 
 <pre style="font-family: Lucida Console;" > 
 ====================================================================================================
 DB Version:    MSQL
 Purpose:
 
 	This procedure will create and set the connection level variables (ID,LOG_FILE_NAME,DEBUG_MODE)
 	with the given values.
 
 Returns: Nothing
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
  
 ##PD  id_val ^^ The value for the ID variable.
 ##PD  log_file  ^^ The name with full path string of the log file for the LOG_FILE_NAME variable.
 ##PD  debug_mode_val  ^^ The value for the DEBUG_MODE variable.
*/

as 
BEGIN

   	set nocount on
   	--set IMPLICIT_TRANSACTIONS OFF
	/*
	This procedure is called to set the connection level variables.
	This procedure will create three connection level variables and set them to the values
	that is passed in as argument.
	*/

	if not exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##CONNINFO')
		begin
			execute absp_messageEx 'Create the temporary connection level table ##CONNINFO'
			create table ##CONNINFO
			   (
				  session_id smallInt PRIMARY KEY,
				  ID varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS,
				  LOG_FILE_NAME varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS,
				  DEBUG_MODE varchar(1)
			    COLLATE SQL_Latin1_General_CP1_CI_AS)
			 begin transaction;
			 insert into ##CONNINFO (SESSION_ID,ID,LOG_FILE_NAME,DEBUG_MODE) values (@@SPID, @id_val, @log_file, @debug_mode_val);
			 commit transaction;
		end
	else
        begin
			if exists ( select 1 from ##CONNINFO where SESSION_ID = @@SPID)
				begin
					--Update
					begin transaction;
					update ##CONNINFO set ID = @id_val,  LOG_FILE_NAME = @log_file, DEBUG_MODE = @debug_mode_val where SESSION_ID = @@SPID;
					commit transaction;
				end
			else 
				begin
					--Insert
					begin transaction;
					insert into ##CONNINFO (SESSION_ID,ID,LOG_FILE_NAME,DEBUG_MODE) values (@@SPID, @id_val, @log_file, @debug_mode_val);
					commit transaction;
				end
		end
		--If @@TRANCOUNT > 0 COMMIT TRANSACTION
		--set IMPLICIT_TRANSACTIONS ON
END