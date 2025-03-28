if exists (select 1 from sysobjects where id = object_id('absvw_ImportErrorReport') and type = 'V')
	drop view absvw_ImportErrorReport
go

create view absvw_ImportErrorReport as
select
	ExposureKey,
	'MessageLevelName'=case left(MessageCode,1) when 'E' then 'Error' else 'Warning' end,
	'MessageCode'=MessageCode,
	'SourceCategory'=SourceID,
	'UserRowNumber'=UserRowNumber,
	'UserColumnName'=UserColumnName,
	'UserValue'=UserValue,
	'MessageText'=MessageText
from ImportErrorWarning

--SELECT * FROM absvw_ImportErrorReport WHERE ExposureKey=1
