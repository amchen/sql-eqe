if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateTranslationCacheViews') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateTranslationCacheViews
end
go

create procedure absp_CreateTranslationCacheViews @schemaName varchar(200), @exposureKey int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure creates lookup caches (views) which are used for substitution of useCodes with RQE System lookup codes.

Returns:        Returns nothing
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin
	set nocount on
	declare @sql varchar(8000);
	declare @debug int;
	
	set @debug=1;
	
	if not exists (select 1 from sys.schemas where name = @schemaName )
		return

	--Create PolicyStatusCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_PolicyStatusCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_PolicyStatusCache as ' +
		              	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where LookupTableName=''PolicyStatus'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where LookupTableName=''PolicyStatus'' ' +
					' and  UserLookupCode not in '+
						'(select  UserLookupCode  from usersubstitutionlist ' +
						' where LookupTableName=''PolicyStatus'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID,  Name as UserCode, PolicyStatusID as LookupID ,''3'' as LookupLevel from PolicyStatus z '+
					' where  Name not in '+
						' (select UserLookupCode  from systemsubstitutionlist y  where LookupTableName=''PolicyStatus'')' +
					' and  Name not in '	+
						' (select  UserLookupCode  from usersubstitutionlist ' +
	               				' where LookupTableName=''PolicyStatus'' and exposureKey= ' + cast(@exposureKey as varchar) +'))';
	        if @debug=1 print @sql;
   		execute (@sql);
	end

	--Create PerilCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_PerilCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_PerilCache as ' +
	             		' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +
		     		' union '+
		      			' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
		               			' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' ' +
		               		' and  UserLookupCode not in '+
		               		'(select UserLookupCode  from usersubstitutionlist ' +
		               			' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
		      	 	' union ' +
		      			' (select ''XXX'' as Country_ID, U_Peril_ID as UserCode, Peril_ID as LookupID ,''3'' as LookupLevel from PTL z  where Trans_ID in (66,67) '+
					' and  U_Peril_ID not in '+
					  ' ( select UserLookupCode  from systemsubstitutionlist y where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'')' +
					' and  U_Peril_ID not in '	+
					' ( select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))';
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMPerilCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMPerilCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMPerilCache as ' +
	             		' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +
		     		' union '+
		      			' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
		               			' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' ' +
		               		' and  UserLookupCode not in 
		               		  (select UserLookupCode  from usersubstitutionlist ' +
		               			' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
		      	 	' union ' +
		      			' (select ''XXX'' as Country_ID, U_Peril_ID as UserCode, Peril_ID as LookupID ,''3'' as LookupLevel from PTL z  where Trans_ID in (66,67) and Peril_ID in (1,15,140)'+
					' and  U_Peril_ID not in
					( select UserLookupCode  from systemsubstitutionlist y where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'')' +
					' and  U_Peril_ID not in 
					 ( select  UserLookupCode  from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))';
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create StructureCoveragePerilCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_StructureCoveragePerilCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_StructureCoveragePerilCache as ' +
	             		' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Structure Coverage Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +
		     		' union '+
		      			' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
		               			' where MappingFieldName  = ''Structure Coverage Peril'' and LookupTableName=''PTL'' ' +
		               		' and  UserLookupCode not in 
		               		(select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Structure Coverage Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
		      	 	' union ' +
		      			' (select ''XXX'' as Country_ID, U_Peril_ID as UserCode, Peril_ID as LookupID ,''3'' as LookupLevel from PTL z  where Trans_ID in (66,67) '+
					' and  U_Peril_ID not in 
					  ( select UserLookupCode  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Structure Coverage Peril'' and LookupTableName=''PTL'')' +
					' and  U_Peril_ID not in 
					(select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Structure Coverage Peril'' and LookupTableName=''PTL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))';
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create CoverageCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_CoverageCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_CoverageCache as ' +
		             	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
			       			' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' ' +
			       		 ' and  UserLookupCode not in 
			       		  (select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
			      		' (select ''XXX'' as Country_ID, U_Cover_ID as UserCode, Cover_ID as LookupID ,''3'' as LookupLevel from CIL z  where Trans_ID in (66,67) '+
					' and  U_Cover_ID not in 
					  (select UserLookupCode from systemsubstitutionlist y  where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'')' +
					' and  U_Cover_ID not in 
					 (select  UserLookupCode  from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))';
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMCoverageCache --
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMCoverageCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMCoverageCache  as ' +
		             	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
			       			' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' ' +
			       		 ' and  UserLookupCode not in 
			       		 ( select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
			      		' (select ''XXX'' as Country_ID, U_Cover_ID as UserCode, Cover_ID as LookupID ,''3'' as LookupLevel from CIL z  where Trans_ID in (69) '+
					' and  U_Cover_ID not in 
					 (select UserLookupCode  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'')' +
					' and  U_Cover_ID not in 
					 (select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMCoverageCacheFac --
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMCoverageCacheFac' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMCoverageCacheFac  as ' +
		             	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
			       			' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' ' +
			       		 ' and  UserLookupCode not in 
			       		 ( select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
			      		' (select ''XXX'' as Country_ID, U_Cover_ID as UserCode, Cover_ID as LookupID ,''3'' as LookupLevel from CIL z  where Trans_ID in (66, 69) '+
					' and  U_Cover_ID not in 
					 (select UserLookupCode  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'')' +
					' and  U_Cover_ID not in 
					 (select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create PolicyConditionTypeCache--

	
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_PolicyConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_PolicyConditionTypeCache as ' +
		             	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
			        		' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' ' +
			        	' and  UserLookupCode not in 
			        	 (select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
			    	' union ' +
			      		' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel ' +
			      		' from ConditionType z  where PolicyValid = ''Y'' and ConditionTypeID in (1,2,5,50,100) '+
					' and  ConditionTypeCode not in 
					 (select UserLookupCode from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'')' +
					' and  ConditionTypeCode not in 
					 ( select  UserLookupCode from usersubstitutionlist ' +
	               			' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMPolicyConditionTypeCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMPolicyConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMPolicyConditionTypeCache as ' +
		             	' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
			        		' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' ' +
			        	' and  UserLookupCode not in 
					 ( select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
			    	' union ' +
			      		' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel from ConditionType z  where PolicyValid = ''Y'' and ConditionTypeID in (2,31,32) '+
					' and  ConditionTypeCode not in 
					 ( select UserLookupCode from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'')' +
					' and  ConditionTypeCode not in 
					 ( select  UserLookupCode from usersubstitutionlist ' +
	               			' where MappingFieldName  = ''Policy Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end


	--Create EQStructureCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_EQStructCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_EQStructCache as ' +
			   ' select distinct Y.Country_ID, Y.UserCode,Y.LookupID,Y.LookupLevel, Trans_ID, RqeLookupCode from Esdl X inner join ( '+
		             	' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel, RqeLookupCode  from usersubstitutionlist '+
					' where LookupTableName=''Esdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ')' +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel, RqeLookupCode  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Esdl'' ' +
			        	' and not exists 
						 (select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Esdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, User_Eq_ID as UserCode, Str_Eq_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Esdl x where Trans_ID = 67 '+
						' and not exists 
						( select 1 from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Esdl''  
			        		and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.User_Eq_ID) ' +
			        	' and not exists 
						(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Esdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
						 and z.UserLookupCode=x.User_Eq_ID))'+
				' union '+
			      		' (select Country_ID, User_Eq_ID as UserCode, Str_Eq_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Esdl x  where trans_id in (67,68) ' +
					'  and not exists
						(select 1  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Esdl'' 
			        		and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
						and y.UserLookupCode=x.User_Eq_ID) ' +
			        	' and not exists 
						( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Esdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						 and z.UserLookupCode=x.User_Eq_ID))'+
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''ESDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				') Y on X.Str_Eq_ID=Y.LookupID where Not(Trans_ID =67 and Y.Country_ID in (''00'',''01'',''02'') and Y.LookupLevel = 3)'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create WindStructureCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_WSStructCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_WSStructCache as ' +
			    ' select distinct Y.Country_ID, Y.UserCode,Y.LookupID,Y.LookupLevel, Trans_ID, RqeLookupCode from Wsdl X inner join ( '+
		             	' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel, RqeLookupCode  from usersubstitutionlist '+
					' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ')' +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel, RqeLookupCode  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Wsdl'' ' +
			        	' and not exists 
							(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, User_Ws_ID as UserCode, Str_Ws_ID as LookupID,''3'' as LookupLevel, '''' RqeLookupCode from Wsdl x where Trans_ID = 67 '+
          				' and not exists 
							(select 1 from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.User_Ws_ID) ' +
					' and not exists 
						 (select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.User_Ws_ID))'+
 				' union '+
			      		' (select Country_ID, User_Ws_ID as UserCode, Str_Ws_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Wsdl x  where trans_id in (67,68) ' +
					'  and not exists
						 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
						 and y.UserLookupCode=x.User_Ws_ID) ' +
					' and not exists 
						  ( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
 						and z.UserLookupCode=x.User_Ws_ID))'+
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				') Y on X.Str_Ws_ID=Y.LookupID where Not(Trans_ID =67 and Y.Country_ID in (''00'',''01'',''02'') and Y.LookupLevel = 3)'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create GOMWSStructCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMWSStructCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMWSStructCache as ' +
			    ' select distinct Y.Country_ID, Y.UserCode,Y.LookupID,Y.LookupLevel, Trans_ID, RqeLookupCode from Wsdl X inner join ( '+
		             	' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel, RqeLookupCode  from usersubstitutionlist '+
					' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ')' +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel, RqeLookupCode  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Wsdl'' ' +
			        		' and not exists 
							(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''00'' as Country_ID, User_Ws_ID as UserCode, Str_Ws_ID as LookupID,''3'' as LookupLevel, '''' RqeLookupCode from Wsdl x where Trans_ID = 69 '+
          				' and not exists 
						  ( select 1 from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						and y.UserLookupCode=x.User_Ws_ID) ' +
					' and not exists 
						(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.User_Ws_ID))'+
 				' union '+
			      		' (select Country_ID, User_Ws_ID as UserCode, Str_Ws_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Wsdl x  where trans_id in (69) ' +
					'  and not exists
						 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
						 and y.UserLookupCode=x.User_Ws_ID) ' +
					' and not exists 
					  ( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
 						and z.UserLookupCode=x.User_Ws_ID))'+
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''WSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				') Y on X.Str_Ws_ID=Y.LookupID where Not(Trans_ID =67 and Y.Country_ID in (''00'',''01'',''02'') and Y.LookupLevel = 3)'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create FloodStructureCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_FLStructCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_FLStructCache as ' +
			    ' select distinct Y.Country_ID, Y.UserCode,Y.LookupID,Y.LookupLevel, Trans_ID, RqeLookupCode from Fsdl X inner join ( '+
		             	' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel, RqeLookupCode  from usersubstitutionlist '+
					' where LookupTableName=''Fsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ')' +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel, RqeLookupCode  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Fsdl'' ' +
			        	' and not exists 
			        	(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Fsdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and y.CountryBasedField = z.CountryBasedField and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, User_Fd_ID as UserCode, Str_Fd_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Fsdl x where Trans_ID = 67 '+
          				' and not exists 
          				(select 1 from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Fsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.User_Fd_ID) ' +
					' and not exists 
 					(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Fsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.User_Fd_ID))'+
 				' union '+
			      		' (select Country_ID, User_Fd_ID as UserCode, Str_Fd_ID as LookupID,''3'' as LookupLevel, '''' as RqeLookupCode from Fsdl x  where trans_id in (67,68) ' +
					'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Fsdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
						 and y.UserLookupCode=x.User_Fd_ID) ' +
					' and not exists 
 					( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Fsdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						 and z.UserLookupCode=x.User_Fd_ID))'	+
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from SystemSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''00'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''01'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				' union '+
				  '(select ''02'' AS Country_ID, UserLookupCode as UserCode, LookupID, ''-9'' as LookupLevel, RqeLookupCode from UserSubstitutionList where LookupTableName=''FSDL'' and CountryBasedField =''WorldWide'' ' + ')' +
				') Y on X.Str_Fd_ID=Y.LookupID where Not(Trans_ID =67 and Y.Country_ID in (''00'',''01'',''02'') and Y.LookupLevel = 3)'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create EQOccupancyCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_EQOccupancyCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_EQOccupancyCache as ' +
		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
					' where LookupTableName=''Eotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Eotdl'' ' +
			        	' and not exists 
			        	(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Eotdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, U_E_Oc_ID as UserCode, E_Occpy_ID as LookupID,''3'' as LookupLevel from Eotdl x where Trans_ID = 67 '+
          				' and not exists 
          				(select 1 from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Eotdl''  
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.U_E_Oc_ID) ' +
					' and not exists 
 					(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Eotdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.U_E_Oc_ID))'+
 				' union '+
			      		' (select Country_ID, U_E_Oc_ID as UserCode, E_Occpy_ID as LookupID,''3'' as LookupLevel from Eotdl x  where trans_id in (67,68) ' +
					'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
						' where LookupTableName=''Eotdl''  
						and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
						 and y.UserLookupCode=x.U_E_Oc_ID) ' +
					' and not exists 
 					( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Eotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						 and z.UserLookupCode=x.U_E_Oc_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create WindOccupancyCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_WSOccupancyCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_WSOccupancyCache as ' +
		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
					' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Wotdl'' ' +
			        	' and not exists 
			        	(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, U_W_Oc_ID as UserCode, W_Occpy_ID as LookupID,''3'' as LookupLevel from Wotdl x where Trans_ID = 67 '+
          				' and not exists 
          				(select 1 from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wotdl''  
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.U_W_Oc_ID) ' +
					' and not exists 
 					(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.U_W_Oc_ID))'+
				' union '+
			      		' (select Country_ID, U_W_Oc_ID as UserCode, W_Occpy_ID as LookupID,''3'' as LookupLevel from Wotdl x  where trans_id in (67,68) ' +
					'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wotdl''  
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
					    	and y.UserLookupCode=x.U_W_Oc_ID) ' +
					' and not exists 
 					( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						and z.UserLookupCode=x.U_W_Oc_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create GOMWSOccupancyCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMWSOccupancyCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMWSOccupancyCache as ' +
		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
					' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Wotdl'' ' +
			        	' and not exists 
			        	(select 1 from usersubstitutionlist z'+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +  
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, U_W_Oc_ID as UserCode, W_Occpy_ID as LookupID,''3'' as LookupLevel from Wotdl x where Trans_ID = 69 '+
          				' and not exists 
          				(select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wotdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
						 and y.UserLookupCode=x.U_W_Oc_ID) ' +
					' and not exists 
 					(select 1 from usersubstitutionlist z '+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar)  + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
						 and z.UserLookupCode=x.U_W_Oc_ID))'+
				' union '+
			      		' (select Country_ID, U_W_Oc_ID as UserCode, W_Occpy_ID as LookupID,''3'' as LookupLevel from Wotdl x  where trans_id in (69) ' +
					'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Wotdl''  
					 and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
					 and y.UserLookupCode=x.U_W_Oc_ID) ' +
					' and not exists 
 					( select 1 from usersubstitutionlist z'+
						' where LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						and z.UserLookupCode=x.U_W_Oc_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create FloodOccupancyCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_FLOccupancyCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_FLOccupancyCache as ' +
		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
					' where LookupTableName=''Fotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
			        		' where LookupTableName=''Fotdl'' ' +
			        	' and not exists 
			        	(select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Fotdl'' and exposureKey= ' + cast(@exposureKey as varchar)  +  
						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END
						 and y.UserLookupCode=z.UserLookupCode))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, U_F_Oc_ID as UserCode, F_Occpy_ID as LookupID,''3'' as LookupLevel from Fotdl x where Trans_ID = 67 '+
          				' and not exists 
          				(select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Fotdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
 						and y.UserLookupCode=x.U_F_Oc_ID) ' +
					' and not exists 
 					(select 1  from usersubstitutionlist z'+
						' where LookupTableName=''Fotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
						and z.UserLookupCode=x.U_F_Oc_ID))'+
				' union '+
			      	' (select Country_ID, U_F_Oc_ID as UserCode, F_Occpy_ID as LookupID,''3'' as LookupLevel from Fotdl x  where trans_id in (67,68) ' +
					'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
					    	' where LookupTableName=''Fotdl''  
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = x.Country_ID
					    	and y.UserLookupCode=x.U_F_Oc_ID) ' +
					' and not exists 
 					( select 1  from usersubstitutionlist z '+
						' where LookupTableName=''Fotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = x.Country_ID
						and z.UserLookupCode=x.U_F_Oc_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create StructureModifierCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_StructureModifierCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_StructureModifierCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where LookupTableName=''StructureModifier'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where LookupTableName=''StructureModifier'' ' +
					' and  UserLookupCode not in '+
					'(select UserLookupCode  from usersubstitutionlist ' +
						' where LookupTableName=''StructureModifier'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, Name as UserCode, StructureModifierID as LookupID ,''3'' as LookupLevel from StructureModifier z  '+
					' where  Name not in '+
					'(select UserLookupCode  from systemsubstitutionlist y  where LookupTableName=''StructureModifier'') ' +
					' and  Name not in '+
					'(select  UserLookupCode  from usersubstitutionlist ' +
	               				' where LookupTableName=''StructureModifier'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end


	--Create StructureCoverageCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_StructureCoverageCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_StructureCoverageCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Structure Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Structure Coverage'' and LookupTableName=''CIL'''  +
					' and  UserLookupCode not in '+
					'( select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Structure Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, U_Cover_ID as UserCode, Cover_ID as LookupID ,''3'' as LookupLevel from CIL z  where Trans_ID in (66,67) '+
					' and  U_Cover_ID not in '+
					'(select UserLookupCode from systemsubstitutionlist y where MappingFieldName  = ''Structure Coverage'' and LookupTableName=''CIL'')' +
					' and  U_Cover_ID not in '+
					'(select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Structure Coverage'' and LookupTableName=''CIL'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create SiteConditionTypeCache--
	
	/*
	kaz 11/4/2013
	kaz 12/4/2013 -- both Site and Policy need this fix (add 50 to the list)
	defect 0008031: RQE 14.1 - MAOL should be allowed for Policy and Site level (Table delivery defect)
	defect 0008032: Worker's Comp Import invalidating MAOL conditions (import side)
	
	Modify CreateTranslationCacheViews, PolicyConditionType area.  Currently hardwired    
		'and ConditionTypeID in (1,2,5,100)'
	Which means  Standard, TLO, CEA and Step.   Need to add 50.
	
		ConditionTypeID ConditionTypeCode   ConditionTypeName          
		1               Standard            Standard          
		2               TLO                 Total Loss Only          
		5               CEA                 California Earthquake Authority          
		31              OFFCSL              Offshore Combined Single Limit          
		32              OFFCS               Offshore Coverage Specific          
		50              MAOL                Maximum Any One Life          
		100             Step                Step	
		
	*/	
	
	
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_SiteConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_SiteConditionTypeCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' ' +
					' and  UserLookupCode not in '+
					'( select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel ' +
					' from ConditionType z where SiteValid = ''Y'' and ConditionTypeID in (1,2,5,50,100)   ' +
					' and  ConditionTypeCode not in '+
					'(select UserLookupCode from systemsubstitutionlist y  where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'')' +
					' and  ConditionTypeCode not in '+
					'(select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMSiteConditionTypeCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMSiteConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMSiteConditionTypeCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' ' +
					' and  UserLookupCode not in '+
					'(select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel from ConditionType z  where SiteValid = ''Y'' and ConditionTypeID in (2,31,32) '+
					' and  ConditionTypeCode not in '+
					'( select UserLookupCode  from systemsubstitutionlist y  where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'')' +
					' and  ConditionTypeCode not in '+
					'( select  UserLookupCode  from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Site Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create StructureConditionTypeCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_StructureConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_StructureConditionTypeCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Structure Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Structure Condition Type'' and LookupTableName=''ConditionType'' ' +
					' and  UserLookupCode not in '+
					'(select UserLookupCode from usersubstitutionlist ' +
						' where MappingFieldName  = ''Structure Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel from ConditionType z where StructureValid = ''Y'' and ConditionTypeID in (1,2,5,50,100)  '+
					' and  ConditionTypeCode not in '+
					'( select UserLookupCode from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Structure Condition Type'' and LookupTableName=''ConditionType'' )' +
					' and  ConditionTypeCode not in '+
					'(select  UserLookupCode from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Structure Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create StepTemplateCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_StepTemplateCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_StepTemplateCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where LookupTableName=''StepInfo'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where LookupTableName=''StepInfo'''  +
					' and  UserLookupCode not in '+
					'( select UserLookupCode  from usersubstitutionlist ' +
						' where LookupTableName=''StepInfo'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, StepConditionName as UserCode, StepTemplateID as LookupID ,''3'' as LookupLevel from StepInfo z   '+
					' where  StepConditionName not in '+ 
					'(select UserLookupCode  from systemsubstitutionlist y '+
						' where LookupTableName=''StepInfo'' )' +
					' and  StepConditionName not in '+
					'(select  UserLookupCode from usersubstitutionlist ' +
	               				' where LookupTableName=''StepInfo'' and exposureKey= ' + cast(@exposureKey as varchar) +'))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create GenericOccupancyCache --
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GenericOccupancyCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GenericOccupancyCache as ' +
		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
					' where MappingFieldName  = ''Occupancy Type'' and LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
			   	' union '+
			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
			        		' where MappingFieldName  = ''Occupancy Type'' and LookupTableName=''Wotdl'' ' +
			        	' and not exists 
  					( select 1  from usersubstitutionlist z '+
						' where MappingFieldName  = ''Occupancy Type'' and LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ' and y.UserLookupCode=z.UserLookupCode 
						and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END))'+
			    	' union ' +
			    		' (select ''XXX'' as Country_ID, U_W_Oc_ID as UserCode, W_Occpy_ID as LookupID,''3'' as LookupLevel from Wotdl x where Trans_ID = 67 '+
          				' and not exists 
 					( select 1  from systemsubstitutionlist y ' +
					    	' where MappingFieldName  = ''Occupancy Type'' and LookupTableName=''Wotdl'' 
					    	and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX''
 						and y.UserLookupCode=x.U_W_Oc_ID) ' +
					' and not exists 
 					( select 1  from usersubstitutionlist z '+
						' where MappingFieldName  = ''Occupancy Type'' and LookupTableName=''Wotdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''
 						and z.UserLookupCode=x.U_W_Oc_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
 	--Create GenericStructureCache--
 	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GenericStructureCache' and objectproperty(id,N'IsView') = 1)
 	begin
 		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GenericStructureCache as ' +
 		             	' select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist '+
 					' where MappingFieldName  = ''Structure Type'' and LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) +
 			   	' union '+
 			      		' (select case when CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE CountryBasedField END AS Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y ' +
 			        		' where MappingFieldName  = ''Structure Type'' and LookupTableName=''Wsdl'' ' +
 			        	' and not exists 
  					 (select 1  from usersubstitutionlist z '+
 						' where MappingFieldName  = ''Structure Type'' and LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + ' and y.UserLookupCode=z.UserLookupCode  ' + 
 						' and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END =case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END))'+
 			    	' union ' +
 			    		' (select ''XXX'' as Country_ID, User_Ws_ID as UserCode, Str_Ws_ID as LookupID,''3'' as LookupLevel from Wsdl x where Trans_ID = 67 '+
           				'  and not exists
           				 (select 1  from systemsubstitutionlist y ' +
 					    	' where MappingFieldName  = ''Structure Type'' and LookupTableName=''Wsdl''  and case when y.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE y.CountryBasedField END = ''XXX'' 
 					    	and y.UserLookupCode=x.User_Ws_ID) ' +
 					' and not exists 
 					(select 1 from usersubstitutionlist z'+
 						' where MappingFieldName  = ''Structure Type'' and LookupTableName=''Wsdl'' and exposureKey= ' + cast(@exposureKey as varchar) + 
 						' and case when z.CountryBasedField =''WorldWide'' THEN ''XXX'' ELSE z.CountryBasedField END = ''XXX''  
 						and z.UserLookupCode=x.User_Ws_ID))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end
	
	--Create CurrencySchemaCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_CurrencySchemaCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_CurrencySchemaCache as ' +
				' select ''XXX'' as Country_ID, code as UserCode, currsk_key as LookupID,''1'' as LookupLevel '+
				' from exchrate ' +
				' where currsk_key in (select currsk_key from cfldrinfo where db_Name=DB_NAME())'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMStructureConditionTypeCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMStructureConditionTypeCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMStructureConditionTypeCache as ' +
			        ' select  ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''1'' as LookupLevel  from usersubstitutionlist ' +
					' where MappingFieldName  = ''Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +
				' union '+
					' (select ''XXX'' as Country_ID, UserLookupCode as UserCode, LookupID,''2'' as LookupLevel  from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Condition Type'' and LookupTableName=''ConditionType'' ' +
						' and  UserLookupCode not in '+
						' (select UserLookupCode  from usersubstitutionlist ' +
						' where MappingFieldName  = ''Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +'))' +
				' union ' +
					' (select ''XXX'' as Country_ID, ConditionTypeCode as UserCode, ConditionTypeID as LookupID ,''3'' as LookupLevel from ConditionType z  where StructureValid = ''Y'' and ConditionTypeID in (2,31,32) '+
					' and  ConditionTypeCode not in '+
					'(select UserLookupCode from systemsubstitutionlist y '+
						' where MappingFieldName  = ''Condition Type'' and LookupTableName=''ConditionType'' ' +
					' and  ConditionTypeCode not in '+
					'( select UserLookupCode  from usersubstitutionlist ' +
	               				' where MappingFieldName  = ''Condition Type'' and LookupTableName=''ConditionType'' and exposureKey= ' + cast(@exposureKey as varchar) +')))'
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

	--Create GOMCountryCache--
	if not exists(select 1 from sysobjects where schema_name(uid)= @schemaName and name = 'absvw_GOMCountryCache' and objectproperty(id,N'IsView') = 1)
	begin
		set @sql = 'create view ' + @schemaName + '.' + 'absvw_GOMCountryCache as ' +
				' select Country_ID as Country_ID, Iso_3 + '' - '' + Country  as UserCode, cast(CountryKey as int) as LookupID,''1'' as LookupLevel '+
				' from Country ' +
				' where Country_ID in (''00'') and IsLicensed = ''Y'''
	        if @debug=1 print @sql;           				
		execute (@sql);
	end

end
