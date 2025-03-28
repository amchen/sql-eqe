if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_Geodata') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_Geodata
end
go
Create view absvw_Geodata
as
	select 
		GEOROW_KEY,			COUNTRYKEY, 
		COUNTRY_ID,			CODE_VALUE, 
		CODEVLOCAL,			LOCATOR, 
		MUN_CODE,			GEO_STAT, 
		
		CAST(
		CASE MAPI_STAT
		WHEN -8 THEN 17 
		ELSE MAPI_STAT
		END as smallint) MAPI_STAT,
		
		LATITUDE,
		LONGITUDE,			CNTRD_TYPE,
		FIPS,				RRGN_KEY, 
		PBCOMB_KEY,			PBNDY1NAME, 
		PBNDY2NAME,			CRESTAZONE, 
		GRND_ELEV,			TERR_FEAT1, 
		TERR_FEAT2,			PSEUDO_PC, 
		POPULATION,			AREA, 
		-- todo:Change to read the actual CELL_ID 
		-- once we add it to GeoData table
		0 as CELL_ID,		cast(1000.00 as float) as DIST_COAST,  
		'?' as SOIL_TYPE,	cast(0.0 as float) as SOIL_FACT, 
		'' as THEM_ZIP,
		'N' as IS_ALIAS,
		CrestaVintage as CrestaVintage  
	from 
		GEODATA
