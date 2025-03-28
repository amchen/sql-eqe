if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetEnvironmentVariable') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_GetEnvironmentVariable
end
 go

create procedure absp_Util_GetEnvironmentVariable @ret_EnvironValue varchar(255) output, @environVar varchar(255) ,@doubleSlashFlag int = 1

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

The procedure calls an external function absxp_GetEnvironmentVariable() which in turn returns the value
of a specified system environment variable in an output parameter.


Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_EnvironValue  ^^ An OUT Parameter that holds the value of the given system environment variable
##PD  @environVar ^^  The system environment variable whose value is to be returned.
##PD  @doubleSlashFlag ^^ A flag signifying whether the '\' character is to be replaced to '/'.

*/
as

begin

   set nocount on
   
  -- This procedure calls an external function contained in eqemssql.dll
  -- Returns the environment value, if found
   declare @environName char(255)
   declare @environValue char(255)
   set @environName = upper(rtrim(ltrim(@environVar)))
   set @environValue = dbo.absxp_GetEnvironmentVariable(@environName)
   if(@doubleSlashFlag = 1)
   begin
      execute absp_Util_Replace_Slash @environValue output, @environValue
   end

   set @environValue = rtrim(ltrim(@environValue))
   set @ret_EnvironValue = @environValue
end
