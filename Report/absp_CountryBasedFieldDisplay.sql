IF EXISTS (SELECT 1 FROM sysobjects WHERE id = object_id('dbo.absp_CountryBasedFieldDisplay'))
    DROP FUNCTION dbo.absp_CountryBasedFieldDisplay;
GO

create function dbo.absp_CountryBasedFieldDisplay (
	@CountryKey SMALLINT
)
returns VARCHAR (20)
as
begin
    declare @CountryBasedFieldDisplay varchar(20);

	-- Worldwide, 00, 01, 02
	if (@CountryKey in (0,1,2,3))
	begin
		set @CountryBasedFieldDisplay = '';
	end
	else
	begin
		select @CountryBasedFieldDisplay = ' ('+Country_ID+')' from Country where CountryKey = @CountryKey;
	end

    return @CountryBasedFieldDisplay;
end
