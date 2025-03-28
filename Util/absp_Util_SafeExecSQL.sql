if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SafeExecSQL') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SafeExecSQL
end
go

create procedure ----------------------------------------------------
absp_Util_SafeExecSQL  @sqlString varchar(max) , @display int = 0  
as
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure  executes a SQL statement. If it executes successfully, 0 is returned   
(in an OUTPUT parameter) else the procedure catches the exception and returns 1.

Returns:       Nothing 
====================================================================================================
</pre>
</font>
##BD_END  

##PD  @ret_Status  ^^  The return value, 0 if the sql executes successfully, else returns 1.
##PD  @sqlString  ^^  The sql string that is executed.
##PD  @display  ^^  Whether the error message is to be logged or not



*/

begin
 
   set nocount on
   
  declare @ret_Status int
   declare @msgText varchar(max)
begin try
      execute(@sqlString)
      set @ret_Status = 0
      return @ret_Status
      
   end try
begin catch
      if @display > 0
      begin
         set @msgText = 'absp_Util_SafeExecSQL (Duplicate record exists, retrying): '+@sqlString
         execute absp_MessageEx @msgText
      end
      set @ret_Status = 1
      return @ret_Status
      
   end catch
end



