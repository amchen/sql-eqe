if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetWceInstallDir') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetWceInstallDir
end
go

create procedure absp_Util_GetWceInstallDir
	@ret_WceInstallDir char(255) output,
	@modeFlag bit = 0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the WCe install directory (if it can) else '' in an OUT parameter
It does this by looking in the file c:\windows\eqe32.ini for the string 'appdir='.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD @ret_WceInstallDir ^^ It is an OUTPUT parameter where the WCE install directory is returned if found else ''
##PD @modeFlag ^^ A flag to check whether to look for 'WCe' or 'EQE' in the .ini file.
*/
begin

   set nocount on
   
   declare @sSection varchar(255)
   declare @sKey varchar(255)
   declare @sFilename varchar(255)
   declare @sAppDir varchar(255)
   
   -- This function returns the WCe install directory (if it can) else ''
   if @modeFlag = 1
   begin
      set @sSection = 'EQE EQE'
   end
   else
   begin
      set @sSection = 'WCE'
   end
   
   set @sKey = 'AppDir'
   set @sFilename = 'C:\\WINDOWS\\eqe32.INI'
   
   exec absp_Util_GetPrivateProfileString @sAppDir output, @sSection, @sKey, '', @sFilename, 0
   
   if (@sAppDir = '')
   begin
	   set @sFilename = 'C:\\WINNT\\eqe32.INI'
	   exec absp_Util_GetPrivateProfileString @sAppDir output, @sSection, @sKey, '', @sFilename, 0
   end
   set @ret_WceInstallDir = @sAppDir
end
