if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SetLogFile') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SetLogFile
end
 go
create procedure absp_Util_SetLogFile @logFile char(248) ,@bOverWrite int = 0 

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls an external function residing in eqesyb.dll to set the log file name.

Returns:       It returns 0 if it succeeds and non zero for failure.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @logFile ^^  Log file Name with full path string.
##PD  @bOverWrite ^^  A flag which indicates if the log file is to be overwritten. 

##RD  @rc ^^  Holds 0 for success, non-zero for failure.

*/
as
begin

   set nocount on
   
 -- This procedure calls an external function contained in eqesyb.dll
 -- Returns 0 for success, non-zero for failure
        declare @rc int
	declare @newLogFile char(248)
	-- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
	execute absp_Util_Replace_Slash @newLogFile output, @logFile
	exec @rc = absxp_SetLogFile @newLogFile,@bOverWrite
	if(@rc = 0)
	begin
	    print 'absp_Util_SetLogFile: '+@newLogFile+', Success'
	end
	else
	begin
	    print 'absp_Util_SetLogFile: Failed!'
	end
	return @rc
end



