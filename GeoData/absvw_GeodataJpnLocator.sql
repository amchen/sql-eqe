if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataJpnLocator') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataJpnLocator
end
go
create view absvw_GeodataJpnLocator as
	select 
		1 as GEOROW_KEY, 
		COUNTRYKEY as COUNTRYKEY,			
		ABBREV as COUNTRY_ID, 
		
		w.LOCATOR as CODE_VALUE,		
		w.LOCATOR as CODEVLOCAL,		
		w.LOCATOR as LOCATOR,
		
		'' as MUN_CODE, 
						
						
		-- GEO_STAT				
		case 
		when w.MAPI_STAT = 8 and w.LOC_TYPE <> 'Country' then 
			CAST(406 as smallint)
		when w.MAPI_STAT = 10 then
			CAST(430 as smallint)
		when w.LOC_TYPE = 'Country' then
			cast(800 as smallint) 
		end as GEO_STAT, 
		
		
		case when w.LOC_TYPE = 'Country' then
			CAST(17 as smallint)
		else
			w.MAPI_STAT
		end	as MAPI_STAT, 
		
		
		
		Z.LAT as LATITUDE,				Z.LON as LONGITUDE,
		'G' as CNTRD_TYPE,				Z.FIPS as FIPS, 
		RRGN_KEY as RRGN_KEY,				0 as PBCOMB_KEY,
		z.STATE as PBNDY1NAME,				z.COUNTY as PBNDY2NAME, 
		
		
		LEFT(w.FIPS, 2) as CRESTAZONE,
		
		z.GRND_ELEV as GRND_ELEV, 
		z.TERR_FEAT1 as TERR_FEAT1,			z.TERR_FEAT2 as TERR_FEAT2,
		'99999' as PSEUDO_PC,				0 as POPULATION, 
		cast(0.0 as float) as AREA,			w.CELL_ID as CELL_ID, 
		z.DIST_COAST as DIST_COAST, 
		z.SOIL_TYPE as SOIL_TYPE,			z.SOIL_FACT as SOIL_FACT, 
		z.THEM_ZIP as THEM_ZIP,
		'N' as IS_ALIAS,
		'' as CrestaVintage  
	from 
		CNTYCT02 Z, RRGNLIST RL, COUNTRY C, WCCCODES w 
	where 
			C.COUNTRYKEY = 3 
		and C.COUNTRY_ID = RL.COUNTRY_ID 
		and left(z.FIPS, 2) = left(RL.FIPS,2)
		and (z.state = w.STATE_2 and z.fips=w.fips) 
		and (W.COUNTRY_ID='02' or z.COUNTY=rtrim(ltrim(SUBSTRING(w.LOCATOR,5,10))))
		and Z.COUNTY not like '%-ken'




--select distinct w.LOCATOR, w.COUNTRY_ID, w.STATE_2, C.COUNTY, w.FIPS, w.MAPI_STAT, w.LOC_TYPE, w.zone_name, c.LAT, c.LON, c.THEM_ZIP,
--c.DIST_COAST, c.GRND_ELEV, c.terr_feat1,c.TERR_FEAT2, c.SOIL_TYPE, c.SOIL_FACT 
--from WCCCODES w 
--JOIN  cntyct02 c on (c.state = w.STATE_2 and c.fips=w.fips)
--where W.COUNTRY_ID='02' or c.COUNTY=rtrim(ltrim(SUBSTRING(w.LOCATOR,5,10)))
