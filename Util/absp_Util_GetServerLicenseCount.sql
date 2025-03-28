if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetServerLicenseCount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetServerLicenseCount
end

go

create  procedure absp_Util_GetServerLicenseCount 
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedure returns the License count of the database server.

Returns:       Nothing.

====================================================================================================
</pre>
</font>
##BD_END

##RS  LICCOUNT 	^^  License count of the database server
*/

begin
	declare @licType nvarchar(128)
	select @licType = convert(nvarchar ,SERVERPROPERTY('LicenseType'))
	if(@licType = 'DISABLED' or @licType = 'PER_PROCESSOR')
	begin
		select 50 as LICCOUNT
	end 
	else
	begin
		select SERVERPROPERTY('NumLicenses') as LICCOUNT
	end
end
  
  