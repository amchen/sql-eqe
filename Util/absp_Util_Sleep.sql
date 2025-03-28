if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_Sleep') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_Sleep
end

go

create procedure absp_Util_Sleep @msecs int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls an external function residing in eqesyb.dll to suspend the current 
operation for a given amount of time.


Returns:  Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @msecs  ^^ The number of milliseconds to suspend operation.
*/
as
begin

   set nocount on
   
  -- This procedure calls an external function contained in eqesyb.dll
  --
  -- The sleep parameter is milliseconds
   execute absxp_sleep @msecs
end

