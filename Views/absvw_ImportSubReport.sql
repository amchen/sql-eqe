if exists (select 1 from sysobjects where id = object_id('absvw_ImportSubReport') and type = 'V')
	drop view absvw_ImportSubReport;
go

create view absvw_ImportSubReport as
select
	u.ExposureKey,
	'MappingFieldName'=l.MappingFieldName,
	'CountryBasedField'=l.CountryBasedField,
	'UserLookupCode'=l.UserLookupCode,
	'RQELookupCode'=l.RQELookupCode,
	'Description'=dbo.absp_GetLookupDescription(l.LookupTableName,l.LookupID,u.CountryKey),
	'NumCount'=u.NumCount,
	'SubstitutionTypeName'=t.SubstitutionTypeName
from SubstitutionUsed u
	join UserSubstitutionList l ON l.ExposureKey = u.ExposureKey
		and u.LookupID=l.LookupID
--		and l.UserLookupCode=u.UserCode
		and u.CacheTypeDefID=l.CacheTypeDefID
	join SubstitutionTypeDef t ON t.SubstitutionTypeDefID = u.SubstitutionTypeDefID
where u.SubstitutionTypeDefID=1 --user
union all
select
    u.ExposureKey,
	'MappingFieldName'=l.MappingFieldName,
	'CountryBasedField'=l.CountryBasedField,
	'UserLookupCode'=l.UserLookupCode,
	'RQELookupCode'=l.RQELookupCode,
	'Description'=dbo.absp_GetLookupDescription(l.LookupTableName,l.LookupID,u.CountryKey),
	'NumCount'=u.NumCount,
	'SubstitutionTypeName'=t.SubstitutionTypeName
from SubstitutionUsed u
	inner join SystemSubstitutionList l ON u.LookupID=l.LookupID
--		and l.UserLookupCode=u.UserCode
		and u.CacheTypeDefID=l.CacheTypeDefID
	join SubstitutionTypeDef t ON t.SubstitutionTypeDefID = u.SubstitutionTypeDefID
where u.SubstitutionTypeDefID=2; --sys
go

--select * from absvw_ImportSubReport where ExposureKey=1
