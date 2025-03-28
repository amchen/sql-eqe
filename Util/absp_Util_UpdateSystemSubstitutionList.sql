if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_UpdateSystemSubstitutionList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_UpdateSystemSubstitutionList
end
go

create procedure absp_Util_UpdateSystemSubstitutionList  
as
begin
	set nocount on
	
	update SystemSubstitutionList set RQELookupDesc  =
	case 
 		when LookupTableName = 'CIL' then (select  U_COV_Name from CIL T2 where SystemSubstitutionList.LookupID=T2.Cover_ID)
 		when LookupTableName = 'EOTDL' then (select top(1) E_Occ_Desc from EOTDL T2 where SystemSubstitutionList.LookupID=T2.E_Occpy_ID 
 							and ((CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
 							or (CountryBasedField='WorldWide')) and trans_id in (67,68) )
  		when LookupTableName = 'FOTDL' then (select top(1) F_Occ_Desc from FOTDL T2 where SystemSubstitutionList.LookupID=T2.F_Occpy_ID 
  							and ( (CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
  							or (CountryBasedField='WorldWide')) and trans_id in (67,68) )
 		when LookupTableName = 'WOTDL' then (select  top(1) W_Occ_Desc from WOTDL T2 where SystemSubstitutionList.LookupID=T2.W_Occpy_ID 
 							and  ((CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
 							or (CountryBasedField='WorldWide')) and trans_id in (67,68) )
 		when LookupTableName = 'PTL' then (select  Peril_Name from PTL T2 where SystemSubstitutionList.LookupID=T2.Peril_ID and Trans_ID in (66,67))
    		when LookupTableName = 'ESDL' then (select top(1) Comp_Descr from ESDL T2 where SystemSubstitutionList.LookupID=T2.Str_Eq_ID 
    							and ((CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
    							or (CountryBasedField='WorldWide')) and trans_id in (67,68) )
  		when LookupTableName = 'FSDL' then (select top(1) Comp_Descr from FSDL T2 where SystemSubstitutionList.LookupID=T2.Str_Fd_ID 
  							and  ((CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
  							or (CountryBasedField='WorldWide')) and trans_id in (67,68))
   		when LookupTableName = 'WSDL' then (select top(1) Comp_Descr from WSDL T2 where SystemSubstitutionList.LookupID=T2.Str_Ws_ID 
   							and ((CountryBasedField<>'WorldWide' and SystemSubstitutionList.CountryBasedField=T2.Country_ID) 
   							or (CountryBasedField='WorldWide')) and trans_id in (67,68))
 		when LookupTableName = 'StructureModifier' then (select  Name from StructureModifier T2 where SystemSubstitutionList.LookupID=T2.StructureModifierID)
  		when LookupTableName = 'PolicyStatus' then (select top(1) Name from PolicyStatus T2 where SystemSubstitutionList.LookupID=T2.PolicyStatusID)
   		when LookupTableName = 'ConditionType' then (select top(1) ConditionTypeName from ConditionType T2 where SystemSubstitutionList.LookupID=T2.ConditionTypeID)
            	when LookupTableName = 'StepInfo' then (select  Description from StepInfo T2 where SystemSubstitutionList.LookupID=T2.StepTemplateId)
         end
end 
	