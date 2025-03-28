if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_ElapsedTime') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ElapsedTime
end

go

create procedure absp_Util_ElapsedTime @ret_ElapsedTime char(20) output ,@startTime datetime output ,@caller char(255) = '',@msgFlag bit = 0
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will set the startTime variable to current time if null startTime is passed
and gives us time difference between startTime and calling time of the function if the startTime has any valid value.

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_ElapsedTime ^^  (Output param) Returns a blank string if null startTime is passed and elapsed time between startTime and calling time of the function if the startTime has any value.
##PD  @startTime ^^  Starting time which will be considered for calculating elapsed time.
##PD  @caller ^^  Caller of the function.
##PD  @msgFlag ^^  Flag for showing message. 


*/
as
begin

   set nocount on
   
   declare @endTime datetime
   declare @deltaTime int
   declare @d float
   declare @retString char(20)
  /*
  This function does two thing to help you determine elapsed time:
  1) call it with a startime variable = null and it will set it for you
  2) call it with a startime variable set and it will return a string of the form:
  ddd-hh:mm:ss.mls
  where ddd is days, hh hours, mm minutes, ss seconds, and mls = milliseconds

  test case and sample usage
  begin
  declare @startTime datetime;
  declare @t2 char (20) ;
  call absp_Util_ElapsedTime ( @startTime );
  -- fake it out that it started  19 days, 8 hours, 23 min, .6 seconds and 54 ms
  set @startTime = dateadd ( ms, - (  ( (  ( 60*60*24* 19 ) + ( 60 * 60 * 8 ) + ( 60 * 23 ) + (6) ) * 1000 ) + 54 ) , @startTime );
  @t2 = call absp_Util_ElapsedTime ( @startTime );
  message @t2;
  end;

  begin
  declare @startTime datetime;
  declare @t2 char (20) ;
  declare @cnt integer;
  call absp_Util_ElapsedTime ( @startTime );
  message now ( * );
  select count ( * ) into @cnt  from Policy;
  message now ( * );
  @t2 = call absp_Util_ElapsedTime ( @startTime );
  message 'Policy has ' + trim ( str ( @cnt ) ) + ' records, counted in time of ' + @t2;
  end;


  */
  
   set @retString = ''
   if isnull(@startTime,CONVERT(DATETIME,'1972-01-01 00:00:00')) = CONVERT(DATETIME,'1972-01-01 00:00:00')
   begin
      set @startTime = GetDate()
   end
   else
   begin
      set @endTime = GetDate()
    -- time in seconds
      set @deltaTime = datediff(ss,@startTime,@endTime)
      set @d = datediff(ms,@startTime,@endTime) -(datediff(ss,@startTime,@endTime)*1000)
    -- time in days
      set @retString = right('00'+rtrim(ltrim(str(datediff(dd,@startTime,@endTime)))),3)
    -- adjust out days
      set @deltaTime = @deltaTime -(60*60*24*datediff(dd,@startTime,@endTime))

      set @retString=ltrim(rtrim(@retString))+'-'+
      right('0'+ltrim(rtrim(str((@deltaTime/3600)))),2)+':'+
      right('0'+ltrim(rtrim(str(((@deltaTime-((@deltaTime/3600)*3600)))/60))),2)+':'+
      right('0'+ltrim(str(@deltaTime-((@deltaTime/3600)*3600)-(((@deltaTime-((@deltaTime/3600)*3600)))/60)*60)),2)+'.'+ 
      right(ltrim(rtrim(str((@d/1000.0),6,3))),3)
   end
  
   if @msgFlag = 1
   begin
      print '==>ET for '+@caller+' = '+@retString
   end
   set @ret_ElapsedTime = @retString
end





