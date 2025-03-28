if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_EnableXPCmdShell') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_EnableXPCmdShell
end
go

create procedure absp_Util_EnableXPCmdShell
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQL2005

Purpose:		This procedure enables the xp_cmdshell option in the database.

Returns:        Nothing.
====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin

    -- We no longer EXEC sp_configure
    -- This procedure does nothing, just returns

    return

	set nocount on
	declare @run_value int
	set @run_value = 0;

	if exists (select * from tempdb..sysobjects where id = object_id('tempdb.dbo.#TableForChecking'))
		drop table #TableForChecking

	create table #TableForChecking (name varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS, minimum int, maximum int, config_value int, run_value int)

	-- We need to get status of xp_cmdshell from configuration
	insert into #TableForChecking exec sp_configure

	-- We will check the run_value as config_value may have different value than the currently used value.
	-- @run_value = 0 means disabled and 1 means enabled
	select @run_value = run_value from #TableForChecking where name = 'show advanced options'

	if (@run_value = 0)
	begin
	--To allow advanced options to be changed.
		EXEC sp_configure 'show advanced options', 1
		RECONFIGURE WITH OVERRIDE
	end
	--To enable xp_cmdshell.
	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE WITH OVERRIDE

	if (@run_value = 0)
	begin
		EXEC sp_configure 'show advanced options', 0
		RECONFIGURE WITH OVERRIDE
	end

	if exists (select * from tempdb..sysobjects where id = object_id('tempdb.dbo.#TableForChecking'))
		drop table #TableForChecking

end
