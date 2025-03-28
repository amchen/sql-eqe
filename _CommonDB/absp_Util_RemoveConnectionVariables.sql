if exists ( select 1 from sysobjects where name = 'absp_Util_RemoveConnectionVariables' and type = 'P' ) 
     drop procedure absp_Util_RemoveConnectionVariables;
go
----------------------------------------------------
create procedure absp_Util_RemoveConnectionVariables
 @deleteAll int = 0
 /*
 ##BD_BEGIN
 <font size ="3"> 
 <pre style="font-family: Lucida Console;" > 
 ====================================================================================================
 DB Version:    MSQL
 Purpose:
 
 	This procedure will remove the connection level variables (ID,LOG_FILE_NAME,DEBUG_MODE)
 	from ##CONNINFO 
 
 Returns: Nothing
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
  
*/

as 
BEGIN

	set nocount on
	
	/*
	This procedure is called to remove the connection level variables of this connection
	*/
	if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##CONNINFO')
	begin
	begin transaction;
		--delete
		if @deleteAll = 1
			delete ##CONNINFO
		else
			delete ##CONNINFO where SESSION_ID = @@SPID
	commit transaction;			
	end
		
	else 
	begin
		Print 'The connection level table ##CONNINFO does not exist. No deletion will be applied'	

	end	

END