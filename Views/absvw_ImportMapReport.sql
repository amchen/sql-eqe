if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_ImportMapReport') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_ImportMapReport;
end
go

create view absvw_ImportMapReport
as
select
	i.ExposureKey,
	i.SourceID,
	i.ColID,
	'SourceCategory'=case i.TargetTableName when 'PolicyCondition'   then 'Policy Condition'
	                                        when 'PolicyFilter'      then 'Policy Filter'
	                                        when 'SiteCondition'     then 'Site Condition'
	                                        when 'StructureCoverage' then 'Structure Coverage'
	                                        when 'StructureFeature'  then 'Structure Feature'
	                                        else i.TargetTableName end,
	'TargetFieldName'=i.TargetFieldName,
	'MapType'=case i.MapType when 'AutoLookup'    then 'Mapped'
	                         when 'FixedPickList' then 'Mapped'
	                         when 'FixedValue'    then 'Constant'
	                         when 'Formula'       then 'Formula'
	                         when 'NormalMap'     then 'Mapped'
	                         else i.MapType end,
	'SourceFieldName'=case i.MapType when 'FixedValue' then i.SourceFieldName
	                                 else 'Source ' + cast(i.SourceID as varchar(3)) + ': ' + i.SourceFieldName end
from ImportMapReport i;
go
--select * from absvw_ImportMapReport where ExposureKey=1
