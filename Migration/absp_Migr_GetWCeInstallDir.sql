if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_GetWCeInstallDir') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_GetWCeInstallDir
end

go
create procedure --------------------------------------------------------------------------------
absp_Migr_GetWCeInstallDir @ret_APPDIR char(255) output ,@modeFlag bit = 0 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the Application Directory for EQE EQE or WCE (based on modeFlag value)
as defined in C:/WINDOWS/eqe32.INI file in an OUTPUT parameter.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END


##PD  @ret_APPDIR ^^ An output parameter that holds a string containing the APPDIR for EQE EQE or WCe as defined in eqe32.INI.
##PD  @modeFlag ^^  A flag value for the application name(0 WCE, 1 EQE EQE).

*/
as
begin

   set nocount on
   
  -- This function returns the WCe install directory,
  -- else '' empty string
   declare @iniFile char(255)
   declare @installDir char(255)
   declare @section char(25)
   declare @key char(25)
  -- get --WINDIR--
   execute absp_Util_GetEnvironmentVariable @iniFile output,'WINDIR'
   set @iniFile = ltrim(rtrim(@iniFile))+'/eqe32.INI'
   if @modeFlag = 1
   begin
	set @section = 'EQE EQE'
   end
   else
   begin
	set @section = 'WCE'
   end
   set @key = 'APPDIR'

   execute absp_Util_GetPrivateProfileString @installDir output,@section,@key,'',@iniFile

   set @ret_APPDIR = @installDir
end


