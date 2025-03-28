IF EXISTS (SELECT 1
       FROM   sysobjects
       WHERE  id = object_id('dbo.absp_GetLookupDescription'))
    DROP FUNCTION dbo.absp_GetLookupDescription
GO

create function dbo.absp_GetLookupDescription (
    @tableName  varchar(100),
    @lookupID int,
    @countryKey int=0
)
returns varchar(100)
as
begin
    declare @rtnDescription varchar(100)
    declare @CountryID varchar(3)
    set @rtnDescription='EMPTY'
    set @CountryID = '00' -- default to USA if all else fails

	if (@countryKey>0) begin
			select @CountryID=Country_ID from Country where CountryKey=@countryKey end;

	if (@tableName='CIL') begin
			select @rtnDescription=U_Cov_Name from CIL where Cover_ID=@LookupID end;

	--if (@tableName='Cobl') begin
			--select @rtnDescription=U_Cob_Name from Cobl where COB_ID=@LookupID end;

	--if (@tableName='D0308') begin
			--select @rtnDescription=U_Type_Nam from D0308 where P_TYPE_ID=@LookupID end;

	--if (@tableName='D0410') begin
			--select @rtnDescription=Trans_Nam from D0410 where TRANS_ID=@LookupID end;

	--if (@tableName='DTL') begin
			--select @rtnDescription=Deduct_Nam from DTL where DEDUCT_ID=@LookupID end;

	if (@tableName='EOTDL') begin--Country
			select @rtnDescription=E_Occ_Desc from EOTDL where E_OCCPY_ID=@LookupID
				and country_id=@CountryID end;

	if (@tableName='ESDL') begin--Country
			select @rtnDescription=Comp_Descr from ESDL where STR_EQ_ID=@LookupID
				and country_id=@CountryID end;

	if (@tableName='FOTDL') begin--Country
			select @rtnDescription=F_Occ_Desc from FOTDL where F_OCCPY_ID=@LookupID
				and country_id=@CountryID end;

	if (@tableName='FSDL') begin--Country
			select @rtnDescription=Comp_Descr from FSDL where STR_FD_ID=@LookupID
				and country_id=@CountryID end;

	--if (@tableName='LOBL') begin
			--select @rtnDescription=U_Lob_Name from LOBL where LOB_ID=@LookupID end;

	--if (@tableName='LTL') begin
			--select @rtnDescription=Limit_Name from LTL where LIMIT_ID=@LookupID end;

	--if (@tableName='PATSL') begin
			--select @rtnDescription=U_Stat_Nam from PATSL where PT_STAT_ID=@LookupID end;

	if (@tableName='PTL') begin
			select @rtnDescription=PerilDisplayName from PTL where Peril_ID=@LookupID end;

	--if (@tableName='RBIL') begin
			--select @rtnDescription=Broker_Nam from RBIL where BROKER_ID=@LookupID end;

	--if (@tableName='RIL') begin
			--select @rtnDescription=Reinsr_Nam from RIL where REINSR_ID=@LookupID end;

	if (@tableName='RLOBL') begin--Country
			select @rtnDescription=Lob_Name from RLOBL where R_LOB_ID=@LookupID
				and country_id=@CountryID end;

	--if (@tableName='TORL') begin
			--select @rtnDescription=Occ_Or_Rsk from TORL where R_TYPE_ID=@LookupID end;

	if (@tableName='WOTDL') begin--Country
			select @rtnDescription=W_Occ_Desc from WOTDL where W_OCCPY_ID=@LookupID
				and country_id=@CountryID end;

	if (@tableName='WSDL') begin--Country
			select @rtnDescription=Comp_Descr from [WSDL] where STR_WS_ID=@LookupID
				and country_id=@CountryID end;

	if (@tableName='ConditionType') begin
			select @rtnDescription=[Description] from ConditionType where ConditionTypeID=@LookupID end;

	if (@tableName='StructureModifier') begin
			select @rtnDescription=Name from StructureModifier where StructureModifierID=@LookupID end;

	if (@tableName='StepInfo') begin
			select @rtnDescription=[Description] from StepInfo where StepTemplateID=@LookupID end;

	if (@tableName='PolicyStatus') begin
			select @rtnDescription=Name from PolicyStatus where PolicyStatusID=@LookupID end;

	--handle a table not found.
	if (@rtnDescription='EMPTY') begin
			set @rtnDescription='No description found in Table:'+@tableName+', ID:'+cast(@lookupID as varchar(10))+', CountryKey:'+cast(@countryKey as varchar(10)) end;

    return @rtnDescription
end
go
--declare @rtnDescrip varchar(300);EXECUTE @rtnDescrip = absp_GetLookupDescription 'CIL', 1, 0; print 'Description: '+@rtnDescrip
--declare @rtnDescrip varchar(300);EXECUTE @rtnDescrip = absp_GetLookupDescription 'FSDL1', 11007, 23; print 'Description: '+@rtnDescrip