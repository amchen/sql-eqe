if exists(select * from SYSOBJECTS where ID = object_id(N'absp_LogsClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_LogsClone
end
go
create procedure absp_LogsClone @nameKey int ,
                                @logKey int ,
                                @portKey int ,
                                @progKey int ,
                                @newProgKey int ,
                                @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones a log record for a given nameKey, logKey and programKey and returns the
key of the new log record.

Returns:       It returns the key of the new log record.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  nameKey ^^  The key of the import file name for which a log record is to be cloned. 
##PD  logKey ^^   The log key for which a log record is to be cloned.
##PD  portKey ^^   The port key of the new log record.
##PD  progKey ^^   The program key for which the log record is to be cloned.
##PD  newProgKey ^^ The program key of the new log record.

##RD  @newKey ^^   The key of the new log record.

*/
as
begin
 
   set nocount on
   
   declare @newKey int
   declare @sql varchar(max)
   
   if @targetDB=''
   	  set @targetDB = DB_NAME()
   	  
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   set @sql = 'begin transaction; insert into ' + dbo.trim(@targetDB)  +'..LOGS (	CHILD_KEY, CHILD_TYPE, PROG_KEY, LPORT_KEY,PORT_ID,
  				 	NAME_KEY, JOB_TYPE, LOG_TYPE, ENGINE_ID, ENG_NAME, START_TIME, DONE_TIME, 
  				 	RET_CODE, LOG_DATA) 
  				 	
  				 	SELECT ' + str(@portKey) + ', CHILD_TYPE, ' + str(@newProgKey) + ', LPORT_KEY,PORT_ID, 
  				 	NAME_KEY, JOB_TYPE, LOG_TYPE, ENGINE_ID, ENG_NAME, START_TIME, DONE_TIME, RET_CODE, LOG_DATA 
  				 	FROM LOGS WHERE NAME_KEY = ' + str(@nameKey ) + 
  				 	' and log_key= ' + str(@logKey) +
  				 	' and prog_key=' + str(@progKey) + 
  				 	' and child_key >= 0 and child_type >= 0; commit transaction; '

   execute (@sql)
   
   select  @newKey = IDENT_CURRENT (dbo.trim(@targetDB) + '..LOGS')
   
   return @newKey
end