if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckDLL') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckDLL
end
go

create procedure absp_Util_CheckDLL
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQL2005

Purpose:		This procedure checks if the external eqemssql.dll is properly installed.

Returns:        Returns 1 if eqemssql.dll is found, -1 if not found.
====================================================================================================
</pre>
</font>
##BD_END

##RD	@ret_status  ^^  Returns 1 if eqemssql.dll is found, -1 if not found.
*/
as
begin

   set nocount on
   
	-- This procedure calls an external function contained in eqemssql.dll
	-- Returns 1 for success, -1 for failure.

	declare @ret_status int
	set @ret_status = dbo.absxp_check_dll()

	-- NULL handling for could not load dynamic library
	set @ret_status = isnull(@ret_status, -1)

	if (@ret_status = -1)
	begin
		print 'absp_Util_CheckDLL: External EQEMSSQL.DLL not found!'
	end
	
	--resultset required in hibernet
	select @ret_status
	
	return @ret_status
end
go
