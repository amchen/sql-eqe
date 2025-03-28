if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetDistinctCurrencyCodesByRtroKey') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetDistinctCurrencyCodesByRtroKey
end
go
create view absvw_GetDistinctCurrencyCodesByRtroKey as
select distinct RTRO_KEY,RIAGG_CC as CC from RTROINFO where RIAGG_VAL >= 0 union
select distinct RTRO_KEY,RITRIG_CC as CC from RTROINFO where RITRIG_VAL >= 0 union
select distinct RTRO_KEY,RLAGG_CC as CC from RTROLAYR where RLAGG_VAL >= 0 union
select distinct RTRO_KEY,RLATT_CC as CC from RTROLAYR where RLATT_VAL >= 0 union
select distinct RTRO_KEY,RLLIM_CC as CC from RTROLAYR where RLLIM_VAL >= 0 union
select distinct RTRO_KEY,RLPRA_CC as CC from RTROLAYR where RLPRA_VAL >= 0 union
select distinct RTRO_KEY,RLPREM_CC as CC from RTROLAYR where RLPREM_VAL >= 0 union
select distinct RTRO_KEY,RLPRL_CC as CC from RTROLAYR where RLPRL_VAL >= 0 union
select distinct RTRO_KEY,RLSPRM_CC as CC from RTROLAYR where RLSPRM_VAL >= 0
-- union select distinct RTRO_KEY,RTTRIG_CC as CC from RTROTRIG where RTTRIG_VAL >= 0

