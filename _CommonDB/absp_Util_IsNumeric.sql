if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsNumeric') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsNumeric
end
go

create procedure ----------------------------------------------------
absp_Util_IsNumeric @String varchar(100),@debug int = 0
as

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return an integer value based on whether or not a given string could be converted into an integer.


Returns: An integer value 0 if string could not be converted into an integer, 1 if string could be converted into an integer. 

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @String ^^  Any string value.
##PD  @debug ^^ The debug Flag

##RD  @ret_Status ^^ An integer value 0 if string could not be converted into an integer, 1 if string could be converted into an integer. 


*/
begin

   set nocount on
   
  /*
  Examines a given String and returns 1 if the string will convert safely to an integer
  */

  declare @ret_Status int;
  declare @n int;
  -- attempt conversion.  Catch the exception if not numeric
  begin try
  set @n=str(@String);
  if @debug > 0 
  begin
    print ''''+@String+''''+' is numeric'
  end 
  set @ret_Status=1
  return @ret_Status
  End Try

  --when others then
  begin catch
    if @debug > 0 
    begin
      print ''''+@String+''''+' is not numeric'
    end 
    set @ret_Status=0
    return @ret_Status
  end catch
end


