if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetDistinctCurrencyCodesByInurKey') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetDistinctCurrencyCodesByInurKey
end
go
create view absvw_GetDistinctCurrencyCodesByInurKey as
select distinct INUR_KEY,ILAGG_CC as CC from INURLAYR where ILAGG_VAL >= 0 union
select distinct INUR_KEY,ILATT_CC as CC from INURLAYR where ILATT_VAL >= 0 union
select distinct INUR_KEY,ILLIM_CC as CC from INURLAYR where ILLIM_VAL >= 0 union
select distinct INUR_KEY,ILPRA_CC as CC from INURLAYR where ILPRA_VAL >= 0 union
select distinct INUR_KEY,ILPRL_CC as CC from INURLAYR where ILPRL_VAL >= 0 union
select distinct	INUR_KEY, ILRET_CC as CC from INURLAYR where ILRET_VAL >= 0	union
select distinct	INUR_KEY, ILAAT_CC as CC from INURLAYR where ILAAT_VAL >= 0	
--union select distinct INUR_KEY,ITLIM_CC as CC from INURTRIG where ITLIM_VAL >= 0

