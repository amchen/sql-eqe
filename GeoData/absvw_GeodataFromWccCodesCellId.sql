if not exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesLocator') and objectproperty(id,N'IsView') = 1)
begin
    -- This creates a dummy view if the float absvw_GeodataFromWccCodesLocator does not exist
    -- so the view absvw_GeodataFromWccCodesCellId can load correctly during the build
   declare @sql varchar(8000)
   set @sql = 'create view absvw_GeodataFromWccCodesLocator as select ' +
              ' 1 as GEOROW_KEY, 1 as COUNTRYKEY, '''' as COUNTRY_ID, '''' as CODE_VALUE,' +
              ' '''' as CODEVLOCAL, '''' as LOCATOR, '''' as MUN_CODE, 1 as GEO_STAT,' +
              ' 1 as MAPI_STAT, 0.0 as LATITUDE, 0.0 as LONGITUDE, '''' as CNTRD_TYPE,' +
              ' '''' as FIPS, 1 as RRGN_KEY, 1 as PBCOMB_KEY, '''' as PBNDY1NAME, '''' as PBNDY2NAME,' +
              ' '''' as CRESTAZONE, 0.0 as GRND_ELEV, 0.0 as TERR_FEAT1, 0.0 as TERR_FEAT2,' +
              ' '''' as PSEUDO_PC, 1 as POPULATION, 0.0 as AREA, 0.0 as CELL_ID, 0.0 as DIST_COAST,' +
              ' '''' as SOIL_TYPE, 0.0 as SOIL_FACT, '''' as THEM_ZIP, ' +
              ' ''N''  as IS_ALIAS, ''9999'' as CrestaVintage '
   execute (@sql)
end
go

if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GeodataFromWccCodesCellId') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GeodataFromWccCodesCellId
end
go
Create view absvw_GeodataFromWccCodesCellId
as
select W.GEOROW_KEY,
 C.COUNTRYKEY,
 C.COUNTRY_ID,
 
 W.CODE_VALUE,
 W.CODEVLOCAL,

 W.LOCATOR,
 W.MUN_CODE,
 W.GEO_STAT,
 W.MAPI_STAT,
 W.LATITUDE,
 W.LONGITUDE,
 W.CNTRD_TYPE,
 W.FIPS,
 W.RRGN_KEY,
 W.PBCOMB_KEY,
 W.PBNDY1NAME,
 W.PBNDY2NAME,
 W.CRESTAZONE,

 W.GRND_ELEV,
 W.TERR_FEAT1,
 W.TERR_FEAT2,
 W.PSEUDO_PC,
 W.POPULATION,
 W.AREA,
 CID.Cellid as CELL_ID,
 W.DIST_COAST,
 W.SOIL_TYPE,
 W.SOIL_FACT,
 W.THEM_ZIP,
'N' as IS_ALIAS,
W.CrestaVintage as CrestaVintage  

from absvw_GeodataFromWccCodesLocator W 
inner join COUNTRY C on W.COUNTRY_ID = C.COUNTRY_ID 
inner join CellIdToLocatorXref CID on CID.LOCATOR = W.LOCATOR and  CID.CrestaVintage = W.CrestaVintage and
Case  CID.CountryCode when 'MXQ' then 'MEX' else  CID.CountryCode end = Abbrev


-- LOCATOR		COUNTRY_ID	STATE_2	COUNTY	FIPS	MAPI_STAT		LOC_TYPE	ZONE_NAME	LATITUDE	LONGITUDE	DIST_COAST	GRND_ELEV	TERR_FEAT1	TERR_FEAT2
-- TWN-003-000	TWN			03		03000	03000	10			Cresta Sub-Zone	NULL		24.686214	121.145692	15.56		371.00		0.78187		0.85000