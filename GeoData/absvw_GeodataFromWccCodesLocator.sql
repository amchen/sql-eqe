if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesLocator') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataFromWccCodesLocator;
end
go

create view absvw_GeodataFromWccCodesLocator
as
select 1 as GEOROW_KEY,
 C.COUNTRYKEY,
 C.COUNTRY_ID,

 CASE

when W.LOC_TYPE = 'Country' or W.MAPI_STAT = -8 or W.MAPI_STAT = 17 then
	W.LOCATOR

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


 when W.MAPI_STAT = 10 then
	 -- CODE_VALUE formated as xx.yy or xx.yyy, or if x is not a number,
	 -- then CODE_VALUE is just the string after the COUNTRY_ID


	CASE ISNUMERIC(SUBSTRING(LOCATOR, 5, 1)) when 1
	then

		SUBSTRING(W.LOCATOR, 6, 2) + '.' +
		case SUBSTRING(W.LOCATOR, 9, 1) when '0'
		then
			SUBSTRING(W.LOCATOR, 10, 2)
		else
			SUBSTRING(W.LOCATOR, 9, 3)
		end

	else
		SUBSTRING(LOCATOR, 5, 99)
	end


 when W.MAPI_STAT = 7  then
		SUBSTRING(LOCATOR, 5, LEN(LOCATOR))

 when W.MAPI_STAT = 6 then
	CASE when LOCATOR like '%PC' then
		SUBSTRING(LOCATOR, 5, LEN(LOCATOR) - 5 - 1)
	else
		SUBSTRING(LOCATOR, 5, LEN(LOCATOR))
	end

 when W.MAPI_STAT = 11 then
		SUBSTRING(LOCATOR, 5, LEN(LOCATOR))

else
	W.LOCATOR
end
as CODE_VALUE,




CASE
when W.LOC_TYPE = 'Country' or W.MAPI_STAT = -8 or W.MAPI_STAT = 17 then
	W.LOCATOR

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


 when W.MAPI_STAT = 10 then
	 -- CODE_VALUE formated as xx.yy or xx.yyy, or if x is not a number,
	 -- then CODE_VALUE is just the string after the COUNTRY_ID


	CASE ISNUMERIC(SUBSTRING(LOCATOR, 5, 1)) when 1
	then

		SUBSTRING(W.LOCATOR, 6, 2) + '.' +
		case SUBSTRING(W.LOCATOR, 9, 1) when '0'
		then
			SUBSTRING(W.LOCATOR, 10, 2)
		else
			SUBSTRING(W.LOCATOR, 9, 3)
		end

	else
		SUBSTRING(LOCATOR, 5, 99)
	end

 when W.MAPI_STAT = 7 or W.MAPI_STAT = 6 then
	SUBSTRING(W.LOCATOR, 5, 99)

else
	W.LOCATOR
end
  as CODEVLOCAL,

 LOCATOR as LOCATOR,
 '' as MUN_CODE,


 case
 when W.MAPI_STAT = 6                     then

	CASE when LOCATOR like '%PC' then
		cast((200 + LEN(SUBSTRING(LOCATOR, 5, 99)) - 2)  as smallint)
	else
		cast(200  + LEN(SUBSTRING(LOCATOR, 5, 99))     as smallint)
	end


 when W.MAPI_STAT = 7                     then  cast(300 as smallint)
 when  W.LOC_TYPE = 'COUNTRY' or W.MAPI_STAT = -8  then	cast(800 as smallint)
 when W.MAPI_STAT = 8 and W.LOC_TYPE <> 'COUNTRY' then	cast(400 as smallint)
 when W.MAPI_STAT = 10 and W.LOC_TYPE <> 'COUNTRY' then	cast(430 as smallint)
 else CAST(506 as smallint)
 end as GEO_STAT,


case
when W.LOC_TYPE = 'COUNTRY' or MAPI_STAT = -8 then CAST(17 as smallint)
else W.MAPI_STAT
end as MAPI_STAT,



 LATITUDE as LATITUDE,
 LONGITUDE as LONGITUDE,
 'G' as CNTRD_TYPE,
 W.FIPS as FIPS,
 RRGN_KEY as RRGN_KEY,
 0 as PBCOMB_KEY,
 '' as PBNDY1NAME,
 '' as PBNDY2NAME,

 CASE
 when W.LOC_TYPE = 'Country' or W.MAPI_STAT = -8 or W.MAPI_STAT = 17 then
	W.STATE_2
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

 when W.MAPI_STAT = 10 then
	W.STATE_2

 else
	W.CRESTA
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
where
C.COUNTRY_ID = RL.COUNTRY_ID
and left(W.FIPS, 2) = left(RL.FIPS,2)


-- LOCATOR		COUNTRY_ID	STATE_2	COUNTY	FIPS	MAPI_STAT		LOC_TYPE	ZONE_NAME	LATITUDE	LONGITUDE	DIST_COAST	GRND_ELEV	TERR_FEAT1	TERR_FEAT2
-- TWN-003-000	TWN			03		03000	03000	10			Cresta Sub-Zone	NULL		24.686214	121.145692	15.56		371.00		0.78187		0.85000