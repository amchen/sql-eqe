if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_RaiseError') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_RaiseError
end

go

create procedure absp_Migr_RaiseError @errorCode int,@errorMsg varchar(max)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure generates an error/warning message and also logs it depending on the errorCode and errorMsg passed.

Returns:       Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @errorCode     ^^ An integer value depending on which an error/warning is generated(errorCode >0 error is raised, errorCode <0 warning is raised).
##PD  @errorMsg      ^^ A string containing the error/warning message.
*/
AS
begin

  set nocount on;

  /*
  This proc is used by TDMEngine to detect errors during migration.

  If errorCode = 0, not an error
  If errorCode > 0, RAISERROR 99999 with errorMsg (error)
  If errorCode < 0, RAISERROR 88888 with errorMsg (warning)
  */
   declare @SWV_func_ABSP_MESSAGEEX_par01 varchar(255);

   if(@errorCode > 0)
   begin
      set @SWV_func_ABSP_MESSAGEEX_par01 = 'ERROR: '+@errorMsg;
      execute absp_MessageEx @SWV_func_ABSP_MESSAGEEX_par01;
      raiserror (@errorMsg, 18, 1);
   end
   else
   begin
      if(@errorCode < 0)
      begin
         set @SWV_func_ABSP_MESSAGEEX_par01 = 'WARNING: '+@errorMsg;
         execute absp_MessageEx @SWV_func_ABSP_MESSAGEEX_par01;
         raiserror (@errorMsg, 17, 1);
      end
   end
end
