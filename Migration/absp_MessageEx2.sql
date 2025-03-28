if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MessageEx2') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_MessageEx2
end

go

create  procedure absp_MessageEx2 @msg varchar(max),@dtTmStamp bit = 1 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates MESSAGE_EX2 table with data as given in the input parameters.


Returns:       nothing

=================================================================================
</pre>
</font>
##BD_END

##PD @msg ^^ A string containing the message
##PD @dtTmStamp ^^ A flag which indicates if the current date is to be recorded.

*/
as
begin

   set nocount on
   
  -- This will break you message up into chunks as needed
   declare @dtime char(20)
   declare @msg2 varchar(max)
   declare @i int
   declare @indent char(2)
   set @indent = '> '
   set @dtime = ''
   if @dtTmStamp = 1
   begin      
      exec absp_Util_GetDateString @dtime output,'yyyymmddhhnnss'
   end
   set @msg2 = @msg
   if len(@msg2) <= 249
   begin
      insert into MESSAGE_EX2 values(@dtime,@msg2)
      print @msg2
   end
   else
   begin
      set @i = 1
      while @i <= len(@msg)
      begin
         set @msg2 = substring(@msg,@i,249)
         if @i >= 250
         begin
            set @msg2 = @indent + ltrim(rtrim(@msg2))
         end
         insert into MESSAGE_EX2 values(@dtime,@msg2)
         print @msg2
         set @i = @i+249
      end
   end
  -- commit work
end

