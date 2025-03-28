if exists (select * from sys.objects where object_id = object_id(N'dbo.absp_ImportSubReport') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	drop function dbo.absp_ImportSubReport;
end
go

create function dbo.absp_ImportSubReport
(
	@ExposureKey int
)
returns @Report table
(
	MappingFieldName		varchar(50),
	CountryBasedField		varchar(20),
	UserLookupCode			varchar(120),
	RQELookupCode			varchar(50),
	Description				varchar(100),
	NumCount				integer,
	SubstitutionTypeName	varchar(120)
)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This function returns Import Code Subsitution report.
Example:    select * from dbo.absp_ImportSubReport(1)
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ExposureKey  ^^  Exposure key.
*/

begin
	if exists (select 1 from SubstitutionUsed where ExposureKey=@ExposureKey and SubstitutionTypeDefID in (1,2))
	begin
		insert @Report (MappingFieldName, CountryBasedField, UserLookupCode, RQELookupCode, Description, NumCount, SubstitutionTypeName)
			select * from absp_getUserSubstitutionForImport(@ExposureKey)
			union all
			select top 20000
				'MappingFieldName'=l.MappingFieldName,
				'CountryBasedField'=l.CountryBasedField + dbo.absp_CountryBasedFieldDisplay(u.CountryKey),
				'UserLookupCode'=l.UserLookupCode,
				'RQELookupCode'=l.RQELookupCode,
				'Description'=dbo.absp_GetLookupDescription(l.LookupTableName,l.LookupID,u.CountryKey),
				'NumCount'=u.NumCount,
				'SubstitutionTypeName'=t.SubstitutionTypeName
			from SubstitutionUsed u
				inner join SystemSubstitutionList l ON u.LookupID=l.LookupID
					and u.UserCode=l.UserLookupCode
					and u.CacheTypeDefID=l.CacheTypeDefID
					and u.CountryBasedField=l.CountryBasedField
				join SubstitutionTypeDef t ON u.SubstitutionTypeDefID = t.SubstitutionTypeDefID
			where u.SubstitutionTypeDefID = 2 --system
				and u.ExposureKey = @ExposureKey;

		if (@@rowcount = 0)
		begin
			insert @Report values ('No Substitutions Found','','','','',NULL,'');
		end
		else
		begin
			-- Convert 00,01,02 to readable codes
			update @Report set CountryBasedField='USA' where CountryBasedField='00';
			update @Report set CountryBasedField='CAN' where CountryBasedField='01';
			update @Report set CountryBasedField='JPN' where CountryBasedField='02';
		end
	end
	else
	begin
		insert @Report values ('No Code Substitutions','','','','',NULL,'');
	end

	return;
end
-- select * from dbo.absp_ImportSubReport(2) order by 1, 2, 3;
