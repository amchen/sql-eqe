if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataUsaPC') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataUsaPC
end
go
create view absvw_GeodataUsaPC as
select  1 as GEOROW_KEY,			COUNTRYKEY as COUNTRYKEY, 
		ABBREV as COUNTRY_ID,		ZIP_CODE as CODE_VALUE, 
		ZIP_CODE as CODEVLOCAL,		'' as LOCATOR,
		CITY as MUN_CODE,				cast(205 as smallint) as GEO_STAT, 
		cast(6 as smallint) as MAPI_STAT, 
		cast(LAT as float(53)) as LATITUDE,			cast(LON as float(53)) as LONGITUDE, 
		'G' as CNTRD_TYPE,			Z.FIPS as FIPS, 
		RRGN_KEY as RRGN_KEY,		0 as PBCOMB_KEY, 
		STATE as PBNDY1NAME,		COUNTY as PBNDY2NAME, 
		'' as CRESTAZONE,			cast(GRND_ELEV as float(53)) as GRND_ELEV, 
		cast(TERR_FEAT1 as float(53)) as TERR_FEAT1,	cast(TERR_FEAT2 as float(53)) as TERR_FEAT2, 
		'99999' as PSEUDO_PC,		0 as POPULATION, 
		cast(0.0 as float(53)) as AREA,				0 as CELL_ID, 
		cast(DIST_COAST as float(53)) as DIST_COAST, 
		SOIL_TYPE as SOIL_TYPE, cast(SOIL_FACT as float(53)) as SOIL_FACT, 
		THEM_ZIP as THEM_ZIP,
		IS_ALIAS as IS_ALIAS,
		'' as CrestaVintage
from 
		ZIPCT Z, RRGNLIST RL, COUNTRY C 
where 
		C. COUNTRYKEY = 1 and C.COUNTRY_ID = RL.COUNTRY_ID 
	and left(Z.FIPS,2) = left(RL.FIPS,2) 
	and STATE not in ('G0','G1','G2','G3','G4','G5','G6','G7')   

