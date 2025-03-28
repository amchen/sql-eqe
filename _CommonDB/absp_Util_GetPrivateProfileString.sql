if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetPrivateProfileString') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetPrivateProfileString
end
go

create procedure absp_Util_GetPrivateProfileString
	@ret_ProfileStr char(255) output,
	@lpAppName varchar(255),
	@lpKeyName varchar(255),
	@lpDefault varchar(255),
	@lpFileName varchar(255),
	@doubleSlashFlag int = 1 
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls an external function absxp_GetPrivateProfileString which in turn returns 
the profile string for a given application and key name from the specified initialization file in
an OUTPUt parameter.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_ProfileStr ^^ An OUTPUT parameter that holda the profile string for a given application and key name from 
				 the specified initialization file.
##PD  @lpAppName ^^ The Application Name
##PD  @lpKeyName ^^ The Key Name
##PD  @lpDefault ^^ The default String
##PD  @lpFileName ^^ The initialization filename
##PD  @doubleSlashFlag ^^ A flag signifying whether the '\' character is to be replaced by '/'.
*/
as
begin

	set nocount on

	-- This procedure calls an external function contained in eqemssql.dll
	-- Returns the key value, if found
	declare @keyValue char(255)
	set @keyValue = dbo.absxp_GetPrivateProfileString(@lpAppName,@lpKeyName,@lpDefault,@lpFileName)
	if(@doubleSlashFlag = 1)
	begin
		execute absp_Util_Replace_Slash @keyValue output, @keyValue
	end
	if @keyValue is NULL
	begin
		set @keyValue = @lpDefault
	end
	print 'absp_Util_GetPrivateProfileString: ['+@lpAppName+'] '+@lpKeyName+'='+@keyValue
	set @ret_ProfileStr = rtrim(ltrim(@keyValue))
end
