if exists (select 1 from sysobjects where id = object_id('absvw_SubstitutionList') and type = 'V')
	drop view absvw_SubstitutionList
go

create view absvw_SubstitutionList as
select
	MappingFieldName,
	CountryBasedField,
	UserLookupCode,
	RQELookupCode,
	LookupTableName,
	LookupID,
	ExposureKey,
	'SubstitutionTypeDefID'=1
from UserSubstitutionList
union all
select
	MappingFieldName,
	CountryBasedField,
	UserLookupCode,
	RQELookupCode,
	LookupTableName,
	LookupID,
	'ExposureKey'=0,--Hard-coded System ExposureKey
	'SubstitutionTypeDefID'=2
from SystemSubstitutionList;
--select * from absvw_SubstitutionList
