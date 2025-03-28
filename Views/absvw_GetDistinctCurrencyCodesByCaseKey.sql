if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetDistinctCurrencyCodesByCaseKey') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetDistinctCurrencyCodesByCaseKey
end
go
create view absvw_GetDistinctCurrencyCodesByCaseKey as
--select distinct CASE_KEY,CTTRIG_CC as CC from CASETRIG where CTTRIG_VAL >= 0 union
select distinct CASE_KEY,CLAAT_CC as CC from CASELAYR where CLAAT_VAL >= 0 union
select distinct CASE_KEY,CLAGG_CC as CC from CASELAYR where CLAGG_VAL >= 0 union
select distinct CASE_KEY,CLATT_CC as CC from CASELAYR where CLATT_VAL >= 0 union
select distinct CASE_KEY,CLLIM_CC as CC from CASELAYR where CLLIM_VAL >= 0 union
select distinct CASE_KEY,CLPRA_CC as CC from CASELAYR where CLPRA_VAL >= 0 union
select distinct CASE_KEY,CLPREM_CC as CC from CASELAYR where CLPREM_VAL >= 0 union
select distinct CASE_KEY,CLPRL_CC as CC from CASELAYR where CLPRL_VAL >= 0 union
select distinct CASE_KEY,CLSPRM_CC as CC from CASELAYR where CLSPRM_VAL >= 0 union
select distinct CASE_KEY, CLRET_CC as CC from CASELAYR  where CLRET_VAL >= 0

