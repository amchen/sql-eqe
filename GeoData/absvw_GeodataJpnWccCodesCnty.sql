if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataJpnWccCodesCnty') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataJpnWccCodesCnty
end
go
create view absvw_GeodataJpnWccCodesCnty as
	select 
		1 as GEOROW_KEY, 
		COUNTRYKEY as COUNTRYKEY,			ABBREV as COUNTRY_ID, 
		
		
		
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
		
		
		
		
		w.MAPI_STAT as MAPI_STAT, 
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


--select distinct w.LOCATOR, w.COUNTRY_ID, w.STATE_2, C.COUNTY, w.FIPS, w.MAPI_STAT, w.LOC_TYPE, w.zone_name, c.LAT, c.LON, c.THEM_ZIP,
--c.DIST_COAST, c.GRND_ELEV, c.terr_feat1,c.TERR_FEAT2, c.SOIL_TYPE, c.SOIL_FACT 
--from WCCCODES w 
--JOIN  cntyct02 c on (c.state = w.STATE_2 and c.fips=w.fips)
--where W.COUNTRY_ID='02' or c.COUNTY=rtrim(ltrim(SUBSTRING(w.LOCATOR,5,10)))
