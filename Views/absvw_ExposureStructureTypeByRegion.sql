if exists(select 1 from sysobjects where ID = object_id(N'absp_Util_CreateLookupViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   exec absp_Util_CreateLookupViews;
end
go

if exists (select 1 from sysobjects where id = object_id('absvw_ExposureStructureTypeByRegion') and type = 'V')
   drop view absvw_ExposureStructureTypeByRegion;
go

create view absvw_ExposureStructureTypeByRegion as
select
 ParentKey
,ParentType
,Country
,Region
,Peril
,'StructureType'=Comp_Descr
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
,Comp_Descr
,ExposureKey
,StructureKey
,NumStructures
,sum(BuildingValue) as BV
,sum(ContentsValue) as CV
,sum(BIValue)       as BI
from
(SELECT     ExposureReport.ParentKey, ExposureReport.ParentType, Country.Country, RRegions.Name AS Region, PTL.PerilDisplayName as Peril, StructureType.Comp_Descr,
                      ExposureReport.ExposureKey, ExposureReport.StructureKey, ExposureReport.NumStructures,
                      CASE WHEN CIL.Cover_Type = 'B' THEN ExposureReport.Value ELSE 0 END AS 'BuildingValue',
                      CASE WHEN CIL.Cover_Type = 'C' THEN ExposureReport.Value ELSE 0 END AS 'ContentsValue',
                      CASE WHEN CIL.Cover_Type = 'T' THEN ExposureReport.Value ELSE 0 END AS 'BIValue'
FROM         ExposureReport INNER JOIN
                      CIL ON ExposureReport.CoverageID = CIL.Cover_ID INNER JOIN
                      Country ON ExposureReport.CountryKey = Country.CountryKey INNER JOIN
                      RRegions ON ExposureReport.RegionKey = RRegions.RRgn_Key INNER JOIN
                      PTL ON ExposureReport.CBPerilID = PTL.Peril_ID INNER JOIN
                      StructureType ON ExposureReport.StructureID = StructureType.Str_ID AND ExposureReport.Country_ID = StructureType.Country_ID and ExposureReport.PerilType = StructureType.PerilType INNER JOIN
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
,Comp_Descr
,ExposureKey
,StructureKey
,NumStructures
) as #tmp2
group by
 ParentKey
,ParentType
,Comp_Descr
,Country
,Region
,Peril

/*
declare @NodeKey int=90, @NodeType int=2
select StructureType,Country,Region,Peril,NumStructures,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total                              from absvw_ExposureStructureTypeByRegion         where ParentKey=@NodeKey and ParentType=@NodeType
*/
