if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateNameWithKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateNameWithKey
end

go

create  procedure absp_Util_CreateNameWithKey @ret_Name varchar(max) output, @name varchar(max) ,@number int ,@maxZeroes int = 5 ,@debug int = 0 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

    This procedure will create a name with filled-in zeroes between a name and a number 
        
Returns:       Name with filled-in zeroes

====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_Name      ^^  Name with filled-in zeroes
##PD  @name          ^^  The name to be concatenated
##PD  @number        ^^  The number to be concatenated.
##PD  @maxZeroes     ^^  The maximum number of zeroes.
##PD  @debug     ^^  The flag to display message.


*/
begin

   set nocount on
   
   declare @i int
   declare @j int
   declare @lowPwr int
   declare @highPwr int
   declare @highestNoZeroes int
   declare @filledInZeroes char(50)
   declare @outName varchar(max)
   declare @msgText varchar(max)
   set @lowPwr = 1
   set @highPwr = 10
   set @i = 0
   set @j = 1
  -- get the highest number of zeroes needed
   lbl: while 1 = 1
   begin
      set @lowPwr = cast(power(10,@i) as INT)
      set @highPwr = cast(power(10,@j) as INT)
      if @number >= @lowPwr and @number < @highPwr
      begin
         break
      end
      set @i = @i+1
      set @j = @j+1
   end
   set @highestNoZeroes = @maxZeroes -@j+1
  -- fill in zeroes
   set @filledInZeroes = ''
   set @i = 1
   while @i <= @highestNoZeroes
   begin
      set @filledInZeroes = rtrim(ltrim(@filledInZeroes))+'0'
      set @i = @i+1
   end
   set @outName = rtrim(ltrim(@name))+rtrim(ltrim(@filledInZeroes))+rtrim(ltrim(str(@number)))
   if @debug > 0
   begin
      set @msgText = '@outname = '+rtrim(ltrim(@name))+rtrim(ltrim(@filledInZeroes))+rtrim(ltrim(str(@number)))
      execute absp_MessageEx @msgText
   end
   set @ret_Name = @outName
   
end

