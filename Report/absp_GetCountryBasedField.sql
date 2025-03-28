IF EXISTS (SELECT 1 FROM sysobjects WHERE id = object_id('dbo.absp_GetCountryBasedField'))
    DROP FUNCTION dbo.absp_GetCountryBasedField;
GO

create function dbo.absp_GetCountryBasedField (
	@ExposureKey INTEGER,
	@UserCode VARCHAR (120),
	@LookupID INTEGER,
	@SubstitutionTypeDefID INTEGER,
	@CacheTypeDefID INTEGER,
	@CountryKey SMALLINT
)
returns VARCHAR (20)
as
begin
    declare @CountryBasedField varchar(20);
    declare @isFound int;

	set @isFound = NULL;

	if (@CountryKey = 0)
	begin
		set @CountryBasedField = 'Worldwide';
	end
	else
	begin
		select @CountryBasedField = Country_ID from Country where CountryKey = @CountryKey;

		-- Check UserSubstitutionList
		if (@SubstitutionTypeDefID = 1)
		begin
			select @isFound = 1 from UserSubstitutionList
				where ExposureKey = @ExposureKey
				  and CountryBasedField = @CountryBasedField
				  and UserLookupCode = @UserCode
				  and CacheTypeDefID = @CacheTypeDefID
				  and LookupID = @LookupID;
		end
		else
		-- Check SystemSubstitutionList
		begin
			select @isFound = 1 from SystemSubstitutionList
				where CountryBasedField = @CountryBasedField
				  and UserLookupCode = @UserCode
				  and CacheTypeDefID = @CacheTypeDefID
				  and LookupID = @LookupID;
		end

		-- Substitution was not found
		if (@isFound is NULL) set @CountryBasedField = 'Worldwide';
	end

    return @CountryBasedField;
end
/*
update SubstitutionUsed
	set CountryBasedField = dbo.absp_GetCountryBasedField (
		ExposureKey,
		UserCode,
		LookupID,
		SubstitutionTypeDefID,
		CacheTypeDefID,
		CountryKey
	)
	where ExposureKey=1;

select *,
	dbo.absp_GetCountryBasedField (
		ExposureKey,
		UserCode,
		LookupID,
		SubstitutionTypeDefID,
		CacheTypeDefID,
		CountryKey
	)
	from SubstitutionUsed where ExposureKey=1;
*/
