if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesPC') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataFromWccCodesPC
end
go
Create view absvw_GeodataFromWccCodesPC
as
select 1 as GEOROW_KEY,
 C.COUNTRYKEY,
 C.COUNTRY_ID,
 
 SUBSTRING(W.LOCATOR, 5, 99) as CODE_VALUE,
 SUBSTRING(W.LOCATOR, 5, 99) as CODEVLOCAL,


 LOCATOR as LOCATOR,
 
 '' as MUN_CODE,
 
 CAST(
 CASE when LOCATOR like '%PC' then
	cast(200 as smallint) + LEN(SUBSTRING(LOCATOR, 5, 99)) - 2
 else
	cast(200 as smallint) + LEN(SUBSTRING(LOCATOR, 5, 99))
 end
 
 as smallint) as GEO_STAT,
 
 
 
 MAPI_STAT as MAPI_STAT,
 LATITUDE as LATITUDE,
 LONGITUDE as LONGITUDE,
 'G' as CNTRD_TYPE,
 W.FIPS as FIPS,
 RRGN_KEY as RRGN_KEY,
 0 as PBCOMB_KEY,

 '' as PBNDY1NAME,
 '' as PBNDY2NAME,


Cresta as CRESTAZONE,


	GRND_ELEV as GRND_ELEV,
	TERR_FEAT1 as TERR_FEAT1,
	TERR_FEAT2 as TERR_FEAT2,
	SUBSTRING(W.LOCATOR, 5, 99) as PSEUDO_PC,
	0 as POPULATION,
	cast(0.0 as float) as AREA,
	CELL_ID as CELL_ID,
	DIST_COAST as DIST_COAST,
	'?' as SOIL_TYPE,
	cast(0.0 as float) as SOIL_FACT,
	'' as THEM_ZIP,
	'N' as IS_ALIAS,
	W.CrestaVintage as CrestaVintage

from WCCCODES W inner join COUNTRY C on W.COUNTRY_ID = C.COUNTRY_ID,
RRGNLIST RL
where MAPI_STAT = 6
and  C.COUNTRY_ID = RL.COUNTRY_ID 
and left(W.FIPS, 2) = left(RL.FIPS,2)




