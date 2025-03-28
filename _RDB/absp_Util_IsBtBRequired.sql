if exists (select 1 from sysobjects where id = object_id('dbo.absp_Util_IsBtBRequired'))
    drop function dbo.absp_Util_IsBtBRequired;
go

create function dbo.absp_Util_IsBtBRequired()
returns integer
as
begin

	declare @IsBtBRequired integer;
	declare @sysVersion varchar(25);
	declare @dbVersion varchar(25);

	select @dbVersion = dbo.absp_Util_GetFullDBVersion();
	select @sysVersion = systemdb.dbo.absp_Util_GetFullDBVersion();

	-- Set the proper return value
	-- Returns 0 for No, 1 for Yes
	if (@dbVersion <> @sysVersion)
		set @IsBtBRequired = 1;
	else
		set @IsBtBRequired = 0;

	return @IsBtBRequired;
end
