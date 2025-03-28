if exists (select 1 from sysobjects where id = object_id('absvw_ExposureImportCurrencyByCountry') and type = 'V')
   drop view absvw_ExposureImportCurrencyByCountry;
go

create view absvw_ExposureImportCurrencyByCountry as
select
 ParentKey
,ParentType
,Peril
,Country
,CurrencyCode
,'NumStructures'=sum(NumStructures)
,'Validated'=sum(IsValue)
,'NotValidated'=sum(NotValue)
,'Total'=sum(IsValue)+sum(NotValue)
from
(select
 ParentKey
,ParentType
,Peril
,Country
,CurrencyCode
,ExposureKey
,StructureKey
,NumStructures
,sum(IsValid) as IsValue
,sum(NotValid) as NotValue
from
(SELECT     ExposureReport.ParentKey, ExposureReport.ParentType, Country.Country, ExposureReport.CurrencyCode, PTL.PerilDisplayName as Peril, ExposureReport.ExposureKey, ExposureReport.StructureKey, ExposureReport.NumStructures,
                      CASE WHEN ExposureReport.IsValid=1 THEN ExposureReport.NativeValue ELSE 0 END AS 'IsValid',
                      CASE WHEN ExposureReport.IsValid=0 THEN ExposureReport.NativeValue ELSE 0 END AS 'NotValid'
FROM         ExposureReport INNER JOIN
					  CIL ON ExposureReport.CoverageID = CIL.Cover_ID INNER JOIN
					  Country ON ExposureReport.CountryKey = Country.CountryKey INNER JOIN
                      PTL ON ExposureReport.CBPerilID = PTL.Peril_ID INNER JOIN
					  ExposureReportInfo ON ExposureReport.ExposureReportKey = ExposureReportInfo.ExposureReportKey AND ExposureReport.ParentKey = ExposureReportInfo.ParentKey AND
					  ExposureReport.ParentType = ExposureReportInfo.ParentType
where (ExposureReportInfo.[Status]='ACTIVE') and (PTL.Trans_ID in (67))
) as #tmp
group by
 ParentKey
,ParentType
,Peril
,Country
,CurrencyCode
,ExposureKey
,StructureKey
,NumStructures
) as #tmp2
group by
 ParentKey
,ParentType
,Peril
,Country
,CurrencyCode

/*
declare @NodeKey int=6, @NodeType int=2
select CurrencyCode,Country,Peril,NumStructures,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total from absvw_ExposureImportCurrencyByCountry where ParentKey=@NodeKey and ParentType=@NodeType
*/
