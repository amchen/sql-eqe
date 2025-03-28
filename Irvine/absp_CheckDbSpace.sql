if exists(select * from SYSOBJECTS WHERE id = object_id(N'absp_CheckDbSpace') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckDbSpace
end
go
create procedure absp_CheckDbSpace as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure is called while database space is low. It updates certain 
Keys in Backup Property table(BKPROP) with some specific values. 

Returns: 0 on successful execution.
=================================================================================
</pre>
</font>
##BD_END

*/
begin
 
   set nocount on
   
  declare @dbName char(255)
   declare @restart char(3)
   declare @timestamp char(60)
   declare @logMsg char(800)
   declare @threshold char(20)
   set @threshold = '20' -- precautious - assigned by Java 
   select  @threshold = bk_value  from bkprop where bk_key = 'CheckSpace.Threshold'
   set @dbName = 'Main' -- precautious only - assigned by Java
   select  @dbName = bk_value  from bkprop where bk_key = 'DatabaseName'
   set @timeStamp = GetDate()
   
  -- clear an refill log variables
   update bkprop set bk_value = @timeStamp  where bk_key = 'CheckSpace.Start'
   update bkprop set bk_value = 'R'  where bk_key = 'CheckSpace.Status'
   update bkprop set bk_value = null  where bk_key = 'CheckSpace.StatusMsg'
   update bkprop set bk_value = null  where bk_key = 'CheckSpace.Stop'
   update bkprop set bk_value = null  where bk_key = 'CheckSpace.SendStart'
   update bkprop set bk_value = null  where bk_key = 'CheckSpace.SendDone'
   --commit work
  -- delete the log file if there is a server restart
   set @restart = 'N'
   select  @restart = bk_value  from bkprop where bk_key = 'Restart'
   if rtrim(ltrim(@restart)) = 'Y'
   begin
      update bkprop set bk_value = 'N'  where bk_key = 'Restart'
      --commit work
   end
  -- write message
   set @timeStamp = GetDate()
   set @logMsg = @timeStamp+': '+rtrim(ltrim(@dbName))+' database disk space is low, free disk space < '+rtrim(ltrim(@threshold))+'%'
   update bkprop set bk_value = @timeStamp  where bk_key = 'CheckSpace.Stop'
   update bkprop set bk_value = 'S'  where bk_key = 'CheckSpace.Status'
   update bkprop set bk_value = rtrim(ltrim(@logMsg))  where bk_key = 'CheckSpace.StatusMsg'
   --commit work
  --message @logMsg type info to console;
   return 0
end




