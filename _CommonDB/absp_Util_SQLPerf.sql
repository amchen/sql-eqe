if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_SQLPerf') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SQLPerf
end

go
create procedure absp_Util_SQLPerf 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	SQL Server has a command that you can run to see the current size of the transaction logs and 
	how much space is currently being utilized. The command is DBCC SQLPERF(logspace).
	The only purpose of this procedure is to be able to send the output from the DBCC command 
	into a temporary table 

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

##PD  @logSizeThreshold ^^  The maximum allowed size of a log file before we truncate it.


*/
AS

-- This procedure is implemented to fix Mantis Defect: 1167.

DBCC SQLPERF(logspace)
