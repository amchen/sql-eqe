if exists (select * from sys.objects where object_id = object_id(N'dbo.absp_getUserSubstitutionForImport') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	drop function dbo.absp_getUserSubstitutionForImport;
end
go

create function dbo.absp_getUserSubstitutionForImport
(
	@ExposureKey int
)
returns @UserSubTemp table
(
	MappingFieldName		varchar(50),
	CountryBasedField		varchar(20),
	UserLookupCode			varchar(120),
	RQELookupCode			varchar(50),
	Description				varchar(100),
	NumCount				integer,
	SubstitutionTypeName	varchar(120)
)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This function correct rqelookupcode getting lookupid from substituonused table and respective lookuptable.
Example:    select * from dbo.absp_getUserSubstitutionForImport(1)
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ExposureKey  ^^  Exposure key.
*/

begin

	declare @sql varchar(max)
	declare @lookupTableName varchar(100)
	declare @lookupCodeName varchar(100)
	declare @lookupIdColName Varchar(100)
	
	Declare @TempSubTable Table (LookupID int ,CountryBasedField varchar(3),LookupTableName varchar(100), MappingFieldName varchar(100), UserLookupCode varchar(100),NumCount int,SubstitutionTypeName varchar(10), LookupUserCodeColName varchar(100), LookupFieldName varchar(120))

	insert into @TempSubTable
	select S.LookupID,U.CountryBasedField ,U.LookupTableName,U.MappingFieldName,U.UserLookupCode,S.NumCount,T.SubstitutionTypeName, d.LookupUserCodeColName, d.LookupFieldName
	
	from UserSubstitutionList U
	inner join SubstitutionUsed S
	on U.CacheTypeDefID=S.CacheTypeDefID and U.ExposureKey=S.ExposureKey
	inner join Country C
	on S.CountryKey=C.CountryKey and U.CountryBasedField =C.Country_ID 
	inner join SubstitutionTypeDef T
	on T.SubstitutionTypeDefID=S.SubstitutionTypeDefID
	inner join CacheTypeDef d
	on d.CacheTypeDefID= U.CacheTypeDefID
	where U.ExposureKey=@exposureKey and T.SubstitutionTypeDefID = 1

	declare  curs1 cursor for 
		select distinct LookupFieldName, LookupUserCodeColName, LookupTableName from @TempSubTable
	open curs1
	fetch next from curs1 into @lookupIdColName, @lookupCodeName, @lookupTableName
	while @@FETCH_STATUS  = 0
	begin

		if (@lookupTableName='CIL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , U_Cover_ID as RqeLookCode, U_Cov_Name as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join CIL L on L.Cover_ID = T.LookupId and T.LookupTableName = 'CIL' end;
		
		else if (@lookupTableName='EOTDL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , U_E_Oc_ID as RqeLookCode, E_Occ_Desc as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join EOTDL L on L.E_Occpy_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'EOTDL' end;
		
		else if (@lookupTableName='ESDL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , User_Eq_ID as RqeLookCode, Comp_Descr as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join ESDL L on L.Str_Eq_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'ESDL' end;

		else if (@lookupTableName='FOTDL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , U_F_Oc_ID as RqeLookCode, F_Occ_Desc as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join FOTDL L on L.F_Occpy_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'FOTDL' end;

		else if (@lookupTableName='FSDL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , User_Fd_ID as RqeLookCode, Comp_Descr as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join FSDL L on L.Str_Fd_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'FSDL' end;

		else if (@lookupTableName='WOTDL') begin
			insert into @UserSubTemp select MappingFieldName,CountryBasedField, UserLookupCode , U_W_Oc_ID as RqeLookCode, W_Occ_Desc as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join WOTDL L on L.W_Occpy_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'WOTDL' end;

		else if (@lookupTableName='WSDL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , User_Ws_ID as RqeLookCode, Comp_Descr as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join WSDL L on L.Str_Ws_ID = T.LookupId and T.CountryBasedField=L.Country_ID and T.LookupTableName = 'WSDL' end;	
			
		else if (@lookupTableName='PTL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , U_Peril_ID as RqeLookCode, PerilDisplayName as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join PTL L on L.Peril_ID = T.LookupId and T.LookupTableName = 'PTL' end;

		else if (@lookupTableName='RLOBL') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , User_Code as RqeLookCode, Lob_Name as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join RLOBL L on L.R_LOB_ID = T.LookupId and T.LookupTableName = 'RLOBL' end;

		else if (@lookupTableName='ConditionType') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , ConditionTypeCode as RqeLookCode, [Description] as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join ConditionType L on L.ConditionTypeID = T.LookupId and T.LookupTableName = 'ConditionType' end;

		else if (@lookupTableName='StructureModifier') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , Name as RqeLookCode, Name as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join StructureModifier L on L.StructureModifierId = T.LookupId and T.LookupTableName = 'StructureModifier' end;

		else if (@lookupTableName='StepInfo') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , StepConditionName as RqeLookCode, StepConditionName as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join StepInfo L on L.StepTemplateID = T.LookupId and T.LookupTableName = 'StepInfo' end;

		else if (@lookupTableName='PolicyStatus') begin
			insert into @UserSubTemp select top 20000 MappingFieldName,CountryBasedField, UserLookupCode , Name as RqeLookCode, Name as Description ,T.NumCount, SubstitutionTypeName from @TempSubTable T
			inner join PolicyStatus L on L.PolicyStatusID = T.LookupId and T.LookupTableName = 'PolicyStatus' end;
		
	fetch next from curs1 into @lookupIdColName, @lookupCodeName, @lookupTableName
	end
	close curs1
	deallocate curs1

	return;

end