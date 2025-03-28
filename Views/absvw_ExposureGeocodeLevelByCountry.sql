if exists (select 1 from sysobjects where id = object_id('absvw_ExposureGeocodeLevelByCountry') and type = 'V')
   drop view absvw_ExposureGeocodeLevelByCountry;
go

create view absvw_ExposureGeocodeLevelByCountry as
select
 ParentKey
,ParentType
,'GeocodeLevel'=GeocodeLevelDescription
,Country
,Peril
,'NumStructures'=sum(NumStructures)
,'BuildingValue'=sum(BV)
,'ContentsValue'=sum(CV)
,'TotalPropertyValue'=sum(BV)+sum(CV)
,'BIValue'=sum(BI)
,'Total'=sum(BV)+sum(CV)+sum(BI)
from
(select
 ParentKey
,ParentType
,GeocodeLevelDescription
,Country
,Peril
,ExposureKey
,StructureKey
,NumStructures
,sum(BuildingValue) as BV
,sum(ContentsValue) as CV
,sum(BIValue)       as BI
from
(SELECT     ExposureReport.ParentKey, ExposureReport.ParentType, Country.Country, PTL.PerilDisplayName as Peril, ExposureReport.ExposureKey, ExposureReport.StructureKey, ExposureReport.NumStructures,
                      CASE WHEN CIL.Cover_Type = 'B' THEN ExposureReport.Value ELSE 0 END AS 'BuildingValue',
                      CASE WHEN CIL.Cover_Type = 'C' THEN ExposureReport.Value ELSE 0 END AS 'ContentsValue',
                      CASE WHEN CIL.Cover_Type = 'T' THEN ExposureReport.Value ELSE 0 END AS 'BIValue', GeocodeLevel.GeocodeLevelDescription
FROM         ExposureReport INNER JOIN
                      CIL ON ExposureReport.CoverageID = CIL.Cover_ID INNER JOIN
                      Country ON ExposureReport.CountryKey = Country.CountryKey INNER JOIN
                      PTL ON ExposureReport.CBPerilID = PTL.Peril_ID INNER JOIN
                      GeocodeLevel ON ExposureReport.GeocodeLevelID = GeocodeLevel.GeocodeLevel INNER JOIN
                      ExposureReportInfo ON ExposureReport.ExposureReportKey = ExposureReportInfo.ExposureReportKey AND ExposureReport.ParentKey = ExposureReportInfo.ParentKey AND
                      ExposureReport.ParentType = ExposureReportInfo.ParentType
where (ExposureReport.IsValid=1) and (ExposureReportInfo.[Status]='ACTIVE') and (PTL.Trans_ID in (67))
) as #tmp
group by
 ParentKey
,ParentType
,GeocodeLevelDescription
,Country
,Peril
,ExposureKey
,StructureKey
,NumStructures
) as #tmp2
group by
 ParentKey
,ParentType
,GeocodeLevelDescription
,Country
,Peril

/*
declare @NodeKey int=90, @NodeType int=2
select GeocodeLevel,Country,Peril,NumStructures,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total            from absvw_ExposureGeocodeLevelByCountry        where ParentKey=@NodeKey and ParentType=@NodeType
*/
