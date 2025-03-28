if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_AnalysisRunInfoByNodeKeyNodeType') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_AnalysisRunInfoByNodeKeyNodeType;
end
go

create view absvw_AnalysisRunInfoByNodeKeyNodeType
as
select
	AnalysisRunKey,
	case NodeType
		when 0  then FolderKey
		when 1  then AportKey
		when 2  then Pportkey
		when 4  then AccountKey
		when 8  then PolicyKey
		when 9  then SiteKey
		when 23 then RPortKey
		when 27 then ProgramKey
		when 30 then CaseKey
		when 64 then ExposureKey
	end as NodeKey,
	NodeType,
	YLTDatabaseName,
	YLTSelectedMetrics,
	YLTCurrencyCode
from AnalysisRunInfo;
