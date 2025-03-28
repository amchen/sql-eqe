if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetAllRegions') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetAllRegions;
end
go

create view absvw_GetAllRegions as
select rtrim(ltrim(CGRPLIST.CLIST_DESC)) as CONTINENT, RRGNLIST.RRGN_KEY, rtrim(ltrim(COUNTRY.COUNTRY)) as COUNTRY, rtrim(ltrim(RREGIONS.NAME)) as REGION_NAME
	from COUNTRY, systemdb.dbo.CGRPLIST, systemdb.dbo.C_RRGNID, systemdb.dbo.RRGNLIST, systemdb.dbo.RREGIONS
	where
		RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and
		C_RRGNID.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and
		C_RRGNID.CLIST_KEY = CGRPLIST.CLIST_KEY and
		RRGNLIST.COUNTRY_ID = COUNTRY.COUNTRY_ID
	union
-- add Puerto Rico "Country" record
select 'North America',RRGNLIST.RRGN_KEY,rtrim(ltrim(COUNTRY.COUNTRY)) as COUNTRY,rtrim(ltrim(RREGIONS.NAME)) as REGION_NAME
	from COUNTRY, systemdb.dbo.RRGNLIST, systemdb.dbo.RREGIONS
	where
		RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and
		RRGNLIST.COUNTRY_ID = COUNTRY.COUNTRY_ID and
		COUNTRY.COUNTRY_ID = 'PRI'
	union
-- add all Continents record
select ' All Continents',RRGNLIST.RRGN_KEY,COUNTRY,rtrim(ltrim(RRGNLIST.NAME)) as REGION_NAME
	from COUNTRY, systemdb.dbo.RRGNLIST
	where
		RRGNLIST.COUNTRY_ID = COUNTRY.COUNTRY_ID and
		COUNTRY.COUNTRY_ID = 'XX';
