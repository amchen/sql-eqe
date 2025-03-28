if exists (select 1 from sysobjects where id = object_id('dbo.absp_Util_IsBtBAvailable'))
    drop function dbo.absp_Util_IsBtBAvailable;
go

create function dbo.absp_Util_IsBtBAvailable(
	@dbType varchar(3)
)
returns integer
as
begin

	declare @IsBtBAvailable integer;

	select @IsBtBAvailable=count(*) from systemdb.dbo.MigrationControl
		where DbType = @dbType
		  and (OnHold in ('Y','') or QAEngineer = '' or Build = '');

	-- Set the proper return value
	-- Returns 0 for No, 1 for Yes
	if (@IsBtBAvailable = 0)
		set @IsBtBAvailable = 1;
	else
		set @IsBtBAvailable = 0;

	return @IsBtBAvailable;
end
