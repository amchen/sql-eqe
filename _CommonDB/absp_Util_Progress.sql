if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_Progress') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_Progress
end
 go

create procedure absp_Util_Progress @callingProc char(256),@prgsTblName char(120),@prgsCol char(120),@arcKey int,@prgrsMessage char(254),@prgrsPosition int = 1,@prgrsRange int = 100,@isRes int = 0,@noCancel int = 0 
/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will insert the progress information in the given progress table. It will also check 
that table for the cancel case, and, if set, throw an exception.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @callingProc ^^ Takes the calling procedure name.
##PD  @prgsTblName  ^^ Progress table name to be used.
##PD  @prgsCol  ^^ Progress column name.
##PD  @arcKey  ^^ Key for the archive job.
##PD  @prgrsMessage  ^^ Progress message to be stored.
##PD  @prgrsPosition  ^^ Progress Position.
##PD  @prgrsRange  ^^ Maximum progress range.
##PD  @isRes  ^^ .It denotes that the archive job is in progress when IsRes value = 0 and Cancel status is null in prgsTblName
##PD  @noCancel  ^^ Its a flag which is to be used during database creation or any other critical path area where cancel would prematurely throw an exception.

*/
as
begin
	set IMPLICIT_TRANSACTIONS OFF
   set nocount on
   
  /*

  This will put the progess infomation in any progress table (like ARCPRGRS, SRCHPRGS)
  It will also check that table for the cancel case, and, if set, throw an exception.
  You must catch this exception!!!!


  If the message prgrsMessage starts with a '-', it is an error message and
  engine_abort EXCEPTION is thrown

  SAMPLE: how to use this
  begin
  declare user_cancelled EXCEPTION for sqlstate '17004';
  declare engine_abort EXCEPTION for sqlstate '17005';
  message 'ppp-1';
  call  absp_Util_Progress ( 12,  'ppp',  6 );
  message 'ppp-2';
  EXCEPTION
  when user_cancelled then
  message 'ppp-3';
  when engine_abort then
  message 'ppp-4';
  end;

  end-sample
  to show cancel:
  -- update ARCPRGRS set CANCELSTAT = 'C' where ARC_KEY = 12;    -- to cancel
  to abort the engine
  call absp_Util_Progress( arcKey , '-4 forced abort' , 1 , 1 );


  Note:  06Oct03:   isRes is unused now, but I left it declared just in case we need it in the future.
  Today, the ARCPRGS table is a normal table on the master, and a PROXY table on the
  Results.    MakeArc and LoadArc create these proxy tables by a forward to command.




  SDG__00010653, SDG__00010926 Hang is Results-side absp_Util_Progress and Master-side 
  absp_Arc_PrepLoad when creating the absp_Arc_ManageArcDiskEvent on the MASTER 
  (not the forward to of DiskEvent)   Hang occurs before forward to is even called.
  Phil and kaz discussed and we agreed to turn off the absp_Arc_ManageArcDiskEvent for now.
  Simplified the code here in Arc_Progress.   It was doing multiple-redundent selects.

  15Oct03 -- add noCancel option.   To be used during database creation or any other
  critcal path area where cancel would prematurely throw an exception.
  */
   declare @cancelStat char(10)
   declare @sql nvarchar(4000)
   declare @createDt char(20)  
   declare @msgText varchar(255)
   
   set @sql = ''
  
   set @sql = 'select @cancelStat =CANCELSTAT from ' + @prgsTblName + ' where ' + @prgsCol + ' = ' + ltrim(rtrim(str(@arcKey)))
   execute sp_executesql @sql,N'@cancelStat char(10) output',@cancelStat  output
  
   -- First time handling: On the Master side, initialize the CANCEL stat to 'N' unless it already has a value
   if @isRes = 0 and @cancelStat is null
   begin
      set @cancelStat = 'N'
      set @sql = 'insert into ' + @prgsTblName + ' ( ' + @prgsCol + ',  CANCELSTAT ) values (' + ltrim(rtrim(str(@arcKey))) + ' , ''N'' )'
      execute(@sql)
   end
   -- Set the progress position, range and message
   if @cancelStat = 'N'
   begin
      exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'     
      set @sql = 'update ' + @prgsTblName + ' set RANGE = ' + ltrim(rtrim(str(@prgrsRange))) + ', POSITION = ' + ltrim(rtrim(str(@prgrsPosition))) + ', MSG_TEXT = ''' + @prgrsMessage + ''', MSG_DAT = ' + @createDt + 'where ' + @prgsCol + ' = ' + ltrim(rtrim(str(@arcKey)))	  
      execute sp_executesql @sql,N'@prgrsRange int output, @prgrsPosition int output, @prgrsMessage char(254) output',@prgrsRange  output, @prgrsPosition output,@prgrsMessage output	  
   end
   
   set @msgText=  'prgrsMessage = ' + ltrim(rtrim(@prgrsMessage))
   execute absp_MessageEx @msgText
   
   -- Check if the Cancel has been set by the user or programatically.
   if @noCancel = 1
   begin
      return
   end
  
  -- User clicked on CANCEL button
   if @cancelStat = 'C'
   begin
      set @msgText = convert(varchar,GetDate(),100)+' ' + ltrim(rtrim(@callingProc)) + ' : somebody pushed cancel'
      execute absp_MessageEx @msgText
      raiserror(17004,16,1)
   end
  
  -- Trigger abort due to low disk space
   if @cancelStat = 'D'
   begin
      set @msgText = convert(varchar,GetDate(),100)+ ' ' + ltrim(rtrim(@callingProc)) + ' : low disk space'
      execute absp_MessageEx @msgText
      raiserror(17005,16,1)
   end
  
  -- General abort
   if charindex('-',@prgrsMessage) = 1
   begin
      set @msgText= convert(varchar,GetDate(),100)+ ' ' + ltrim(rtrim(@callingProc)) + ' : engine aborted '+@prgrsMessage
      execute absp_MessageEx @msgText
      raiserror(17005,16,1)
   end
	set IMPLICIT_TRANSACTIONS ON
end