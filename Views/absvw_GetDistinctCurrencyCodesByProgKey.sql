if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetDistinctCurrencyCodesByProgKey') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetDistinctCurrencyCodesByProgKey
end
go
create view absvw_GetDistinctCurrencyCodesByProgKey as
select distinct PROG_KEY,IIAGG_CC as CC from INURINFO where IIAGG_VAL >= 0 union
select distinct PROG_KEY, IIOCC_CC as CC from INURINFO where IIOCC_VAL >= 0 union
select distinct PROG_KEY,CIAGG_CC as CC from CASEINFO where CIAGG_VAL >= 0 union
select distinct PROG_KEY,CITRIG_CC as CC from CASEINFO where CITRIG_VAL >= 0 union
select distinct PROG_KEY, CIOCC_CC as CC from CASEINFO where CIOCC_VAL >= 0

