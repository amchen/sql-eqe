if exists (select 1 from sysobjects where id = object_id('dbo.absp_Util_GetFullDBVersion'))
    drop function dbo.absp_Util_GetFullDBVersion;
go

create function dbo.absp_Util_GetFullDBVersion()
returns varchar(25)
as
begin

	declare @verString varchar(25);
	declare @buildString varchar(5);

	select @verString = max(RQEVersion) from RQEVersion;
	select @buildString = substring(max(Build),15,3) from RQEVersion;

	set @verString = @verString + '.' + @buildString;

	return @verString;
end
