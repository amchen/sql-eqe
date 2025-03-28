if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckIfXPCmdShellEnabled') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckIfXPCmdShellEnabled;
end
go

create procedure absp_Util_CheckIfXPCmdShellEnabled
/*
====================================================================================================
Purpose:		This procedure checks if xp_cmdshell option is enabled or not in the database.
Returns:        Returns 1 if xp_cmdshell is enabled, 0 if xp_cmdshell is disabled.
====================================================================================================
*/
as
begin

    set nocount on;

	declare @run_value int;

	set @run_value = 0;

	-- check if xp_cmdshell is enabled
    select @run_value = convert(int, isnull(value, value_in_use))
        from  sys.configurations
        where name = 'xp_cmdshell';

	--resultset required by hibernate
	select @run_value;
	return @run_value;
end
