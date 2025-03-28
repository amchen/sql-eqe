if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsUseXPCmdShell') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsUseXPCmdShell;
end
go

create procedure absp_Util_IsUseXPCmdShell
/*
====================================================================================================
Purpose:		This procedure checks the BKPROP setting for xp_cmdshell (DatabaseSettings.config).
Returns:        Returns 1 if xp_cmdshell is enabled, 0 if xp_cmdshell is disabled.
====================================================================================================
*/
as
begin

    set nocount on;

	declare @rc int;

	set @rc = 1;

	if exists (select 1 from commondb.dbo.BkProp where Bk_Key='Use_xp_cmdshell' and Bk_Value='False')
	begin
		set @rc = 0;
	end

	return @rc;
end
