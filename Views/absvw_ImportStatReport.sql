if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_ImportStatReport') and objectproperty(id,N'IsView') = 1)
begin
	drop view absvw_ImportStatReport
end
go

create view absvw_ImportStatReport
as
select
	[ExposureKey],
	[StatLabel],
	[StatValue],
	[ImportStatReportKey]
from [ImportStatReport]

--select * from absvw_ImportStatReport where ExposureKey=1
