if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesCresta') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataFromWccCodesCresta
end
go
Create view absvw_GeodataFromWccCodesCresta
as
select 1 as GEOROW_KEY,
 C.COUNTRYKEY,
 C.COUNTRY_ID,
 
 CASE
 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) = '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 6, 2)
	else SUBSTRING(W.LOCATOR, 6, 99)
	end

 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) <> '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 5, 2)
	else SUBSTRING(W.LOCATOR, 5, 99)
	end
else 
	SUBSTRING(W.LOCATOR, 5, 99)	
end
as CODE_VALUE,

 CASE
 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) = '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 6, 2)
	else SUBSTRING(W.LOCATOR, 6, 99)
	end

 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) <> '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 5, 2)
	else SUBSTRING(W.LOCATOR, 5, 99)
	end
else 
	SUBSTRING(W.LOCATOR, 5, 99)	
end
as CODEVLOCAL,


 LOCATOR as LOCATOR,
 
 '' as MUN_CODE,
 cast(400 as smallint) as GEO_STAT,
 MAPI_STAT,
 LATITUDE as LATITUDE,
 LONGITUDE as LONGITUDE,
 'G' as CNTRD_TYPE,
 W.FIPS as FIPS,
 RRGN_KEY as RRGN_KEY,
 0 as PBCOMB_KEY,

 '' as PBNDY1NAME,
 '' as PBNDY2NAME,


 CASE
 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) = '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 6, 2)
	else SUBSTRING(W.LOCATOR, 6, 99)
	end

 when W.MAPI_STAT = 8 and SUBSTRING(W.LOCATOR, 5, 1) <> '0' then 
	case
	when charindex('*', W.LOCATOR) = 0 then  SUBSTRING(W.LOCATOR, 5, 2)
	else SUBSTRING(W.LOCATOR, 5, 99)
	end
else 
	SUBSTRING(W.LOCATOR, 5, 99)	
end
as CRESTAZONE,


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

from WCCCODES W inner join COUNTRY C on W.COUNTRY_ID = C.COUNTRY_ID,
RRGNLIST RL
where MAPI_STAT = 8 
and LOC_TYPE not in ('geodata','country','postal code','Commune Code')
and  C.COUNTRY_ID = RL.COUNTRY_ID 
and left(W.FIPS, 2) = left(RL.FIPS,2)


