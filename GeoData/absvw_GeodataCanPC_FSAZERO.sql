if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataCanPC_FSAZERO') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataCanPC_FSAZERO
end
go
create view absvw_GeodataCanPC_FSAZERO as
	select 
		1 as GEOROW_KEY,			
		COUNTRYKEY as COUNTRYKEY, 	ABBREV as COUNTRY_ID,		
		ZIP_CODE as CODE_VALUE, 	ZIP_CODE as CODEVLOCAL,		
		'' as LOCATOR,				CITY as MUN_CODE,				
		cast(LEN(ZIP_CODE) + 200 as smallint) as GEO_STAT, 
		cast(6 as smallint) as MAPI_STAT, 
		LAT as LATITUDE,			LON as LONGITUDE,
		'G' as CNTRD_TYPE,			Z.FIPS as FIPS, 
		RRGN_KEY as RRGN_KEY, 		0 as PBCOMB_KEY,
		STATE as PBNDY1NAME, 		COUNTY as PBNDY2NAME, 
		'' as CRESTAZONE, 		GRND_ELEV as GRND_ELEV, 
		TERR_FEAT1 as TERR_FEAT1,	TERR_FEAT2 as TERR_FEAT2,
		'99999' as PSEUDO_PC, 		0 as POPULATION, 
		cast(0.0 as float) as AREA,	0 as CELL_ID, 
		DIST_COAST as DIST_COAST,	SOIL_TYPE as SOIL_TYPE, 
		SOIL_FACT as SOIL_FACT,		THEM_ZIP as THEM_ZIP,
		'N' as IS_ALIAS,
		'' as CrestaVintage  
	from 
		FSAZERO Z, RRGNLIST RL, COUNTRY C 
	where 
			C. COUNTRYKEY = 2 
		and C.COUNTRY_ID = RL.COUNTRY_ID 
		and Z.FIPS =RL.FIPS 

