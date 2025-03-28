if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesCntry') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataFromWccCodesCntry
end
go
Create view absvw_GeodataFromWccCodesCntry
as
	select 
		1 as GEOROW_KEY,			
		cast(-99 as smallint) as COUNTRYKEY, 
		C.COUNTRY_ID as COUNTRY_ID,	LOCATOR as	CODE_VALUE, 
		LOCATOR as CODEVLOCAL,		LOCATOR as	LOCATOR, 
		'' as MUN_CODE,				
		cast(800 as smallint) as GEO_STAT, 
		cast(17 as smallint) as MAPI_STAT,		
		LATITUDE as LATITUDE,		LONGITUDE as LONGITUDE,		
		'G' as	CNTRD_TYPE,		W.FIPS as FIPS,				
		RRGN_KEY as	RRGN_KEY,	0 as PBCOMB_KEY,			
		'' as PBNDY1NAME,		'' as PBNDY2NAME,
		STATE_2 as CRESTAZONE,
		GRND_ELEV as GRND_ELEV,
		TERR_FEAT1 as TERR_FEAT1,
		TERR_FEAT2 as TERR_FEAT2,
		'99999' as PSEUDO_PC,
		0 as POPULATION,
		cast(0.0 as float) as AREA,
		CELL_ID as CELL_ID,
		DIST_COAST as DIST_COAST,
		'?' as SOIL_TYPE,
		cast(0.0 as float) as SOIL_FACT,
		'' as THEM_ZIP,
		'N' as IS_ALIAS,
		W.CrestaVintage as CrestaVintage
	from 
		wcccodes W inner join COUNTRY C on W.COUNTRY_ID = C.COUNTRY_ID,
		RRGNLIST RL
	where len(locator)=3 
	and C.COUNTRY_id 	not in 	(select COUNTRY_id from GEODATA  where MAPI_STAT = -8) 	
	and  C.COUNTRY_ID = RL.COUNTRY_ID 
	and left(W.FIPS, 2) = left(RL.FIPS,2) 
			
