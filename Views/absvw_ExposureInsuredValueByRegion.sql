if exists (select 1 from sysobjects where id = object_id('absvw_ExposureInsuredValueByRegion') and type = 'V')
   drop view absvw_ExposureInsuredValueByRegion;
go

create view absvw_ExposureInsuredValueByRegion as
select
 ParentKey
,ParentType
,Country
,Region
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
,Country
,Region
,Peril
,ExposureKey
,StructureKey
,NumStructures
,sum(BuildingValue) as BV
,sum(ContentsValue) as CV
,sum(BIValue)       as BI
from
(SELECT     ExposureReport.ParentKey, ExposureReport.ParentType, Country.Country, RRegions.Name Region, PTL.PerilDisplayName as Peril, ExposureReport.ExposureKey, ExposureReport.StructureKey, ExposureReport.NumStructures,
'BuildingValue'=CASE WHEN CIL.Cover_Type = 'B' THEN ExposureReport.Value ELSE 0 END,
'ContentsValue'=CASE WHEN CIL.Cover_Type = 'C' THEN ExposureReport.Value ELSE 0 END,
'BIValue'      =CASE WHEN CIL.Cover_Type = 'T' THEN ExposureReport.Value ELSE 0 END
FROM ExposureReport INNER JOIN
CIL ON ExposureReport.CoverageID = CIL.Cover_ID INNER JOIN
Country ON ExposureReport.CountryKey = Country.CountryKey INNER JOIN
PTL ON ExposureReport.CBPerilID = PTL.Peril_ID INNER JOIN
RRegions ON ExposureReport.RegionKey = RRegions.RRgn_Key INNER JOIN
ExposureReportInfo ON ExposureReport.ExposureReportKey = ExposureReportInfo.ExposureReportKey AND ExposureReport.ParentKey = ExposureReportInfo.ParentKey AND
ExposureReport.ParentType = ExposureReportInfo.ParentType
where (ExposureReport.IsValid=1) and (ExposureReportInfo.[Status]='ACTIVE') and (PTL.Trans_ID in (67))
) as #tmp
group by
 ParentKey
,ParentType
,Country
,Region
,Peril
,ExposureKey
,StructureKey
,NumStructures
) as #tmp2
group by
 ParentKey
,ParentType
,Country
,Region
,Peril

/*
declare @NodeKey int=90, @NodeType int=2
select Country,Peril,NumStructures,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total                       from absvw_ExposureInsuredValueByCountry         where ParentKey=@NodeKey and ParentType=@NodeType
select Country,Region,Peril,NumStructures,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total                from absvw_ExposureInsuredValueByRegion          where ParentKey=@NodeKey and ParentType=@NodeType
*/
