if exists(select * from SYSOBJECTS where ID = object_id(N'absp_QA_ValidateSubstitutionList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_ValidateSubstitutionList
end
go

create procedure absp_QA_ValidateSubstitutionList @mappingFieldName  varchar(20), @countryBasedField  varchar(10) =''
as

begin
	set nocount on
	declare @lookupCode varchar (20)
	declare @RQELookupCode varchar (50)
	declare @lookupID int	
	declare @sql varchar(max)
	
	--Create table to hold the mismatches--
	create table #Tmp_SubstitutionList (MappingFieldName  varchar(50),
										CountryBasedField varchar(20),
										UserLookupCode varchar(20),
										RQELookupCode varchar(50),
										LookupID int,
										TableName varchar(5),
										ErrorMsg varchar(1000) default '')
	
	
	if @mappingFieldName <> 'Occupancy Type' and @MappingFieldName<>'Structure Type' return
	
	--Insert rows in temporary table based on SystemSubstitutionList--
	if @countryBasedField ='WorldWide'
		declare c1 cursor for 
			select UserLookupCode,RQELookupCode,LookupID,CountryBasedField from systemsubstitutionlist 
				where MappingFieldName=@mappingFieldName and CountryBasedField=@countryBasedField
				 group by UserLookupCode,RQELookupCode,LookupID,CountryBasedField
	else if @countryBasedField =''
		declare c1 cursor for 
			select UserLookupCode,RQELookupCode,LookupID,CountryBasedField from systemsubstitutionlist 
				where MappingFieldName=@mappingFieldName 
				 group by UserLookupCode,RQELookupCode,LookupID,CountryBasedField
	else  
		declare c1 cursor for 
			select UserLookupCode,RQELookupCode,LookupID,CountryBasedField from systemsubstitutionlist 
				where MappingFieldName=@mappingFieldName and CountryBasedField=@countryBasedField
				group by UserLookupCode,RQELookupCode,LookupID,CountryBasedField
		
				 
	open c1
	fetch c1 into @lookupCode,@RQELookupCode,@lookupID,@countryBasedField
	while @@fetch_status=0
	begin
		--For each UserLookupCode, add all the entries that should exist--
		if @mappingFieldName ='Occupancy Type'
			insert into  #Tmp_SubstitutionList(MappingFieldName,CountryBasedField,UserLookupCode,RQELookupCode,LookupID,TableName)
				select 'Earthquake Occupancy Type',@countryBasedField,@lookupCode,@RQELookupCode,@lookupID,'EOTDL'
				union
				select 'Flood Occupancy Type',@countryBasedField,@lookupCode,@RQELookupCode,@lookupID,'FOTDL'
				union
				select 'Wind Occupancy Type',@countryBasedField,@lookupCode,@RQELookupCode,@lookupID,'WOTDL'
		else
			insert into  #Tmp_SubstitutionList(MappingFieldName,CountryBasedField,UserLookupCode,RQELookupCode,LookupID,TableName)
				select 'Earthquake Structure Type',@countryBasedField,@lookupCode,@RQELookupCode,@lookupID,'ESDL'
				union
				select 'Flood Structure Type',@countryBasedField,@lookupCode,@RQELookupCode,@lookupID,'FSDL'
				union
				select 'Wind Structure Type',@countryBasedField, @lookupCode,@RQELookupCode,@lookupID,'WSDL'
		fetch c1 into @lookupCode,@RQELookupCode,@lookupID,@countryBasedField
	end
	close c1
	deallocate c1

	--Delete rows from temporary table which exists in systemsubstitutionlist--
	delete from #Tmp_SubstitutionList
		from #Tmp_SubstitutionList A inner join systemsubstitutionlist B
		on A.UserLookupCode=B.UserLookupCode and A.RQELookupCode=B.RQELookupCode and A.LookupID=B.LookupID
		and A.MappingFieldName=B.MappingFieldName and A.CountryBasedField=B.CountryBasedField 
	
	--Set error message for each row--
	update #Tmp_SubstitutionList set ErrorMsg =
		'Missing entry for StructureType='''+MappingFieldName+''', CountryBasedField='''+CountryBasedField+''', UserLookupCode='''+
			UserLookupCode+''', RQELookupCode='''+RQELookupCode +''', LookupID=' + dbo.trim(cast(LookupID as varchar))+', TableName='''+TableName+''''
			
	--Return mismatches--
	select * from #Tmp_SubstitutionList order by UserLookupCode
										
end
