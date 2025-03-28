if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetSiteDetails') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetSiteDetails
end
 go

create procedure absp_GetSiteDetails @exposureKey int, @accountKey int,@nodeKey int, @nodeType int, @financialModelType int,@pageNum int,@pageSize int=1000,@userKey int=1,@debug int=0											
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @attrib int;
	declare @tableExists int;
	declare @startRowNum int;
	declare @endRowNum int;
	declare @rowCnt int;
	declare @filteredTblView varchar(50);
	declare @viewexists int;
	set @startRowNum=0;
	declare @InProgress int;	
	declare @Pgnum int;
	declare @fieldNames varchar(max);
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1 return;

	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	
	--Return Structure--
	select *,space(50) as AccountNumber,space(50) as SiteNumber,0 as ReportsAvailable,0 as PageNumber,0 as RowNum  	into #FinalFilterRecords from Structure where 1=0	

	set @tableName='FilteredStructure_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))

	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin
	
			set @sql = 'select top(1) @startRowNum=RowNum from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec absp_MessageEx @sql			
			exec sp_executesql @sql,N'@startRowNum int out' ,@startRowNum out

			set @sql = 'select @rowCnt=count(*) from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec sp_executesql @sql,N'@rowCnt int out' ,@rowCnt out
		
			if @rowCnt>=@pageSize
			begin
				set @pgNum=@rowCnt /@pageSize;
			if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
			if @pgNum<@pageNum set @pageNum=1
			end
			
			 set @startRowNum=@startRowNum +((@pageNum - 1) * @pageSize);
			 set @endRowNum = @startRowNum + @pageSize;
	
		--Get structure and Site Keys	 
		create table #Keys (StructureKey int,SiteKey int,CountryCode varchar(3)  COLLATE SQL_Latin1_General_CP1_CI_AS);
		 		set @sql = 'insert into #Keys select T1.StructureKey,T1.SiteKey,T1.CountryCode from Structure T1 inner join ' + @tableName + ' T2 
				on T1.StructureRowNum=T2.StructureRowNum '+
				'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)));
		set @sql = @sql + ' order by RowNum'
		if @debug=1 exec absp_MessageEx @sql
		exec(@sql)

		execute absp_DataDictGetFields @fieldNames output, 'Structure',0;
		set identity_insert #FinalFilterRecords on
		set @sql = 'insert into  #FinalFilterRecords (' + @fieldNames + ',AccountNumber,SiteNumber,ReportsAvailable,PageNumber,RowNum)
				select  T1.* ,AccountNumber,SiteNumber, case when Status=''Available'' then 1 else 0 end as ReportsAvailable,' +
				dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum  from Structure T1 inner join ' + @tableName + ' T2 
				on T1.StructureRowNum=T2.StructureRowNum '+
				' left outer join AnalysisRunInfo T3 on T2.exposurekey=T3.exposureKey and T2.AccountKey=T3.AccountKey and T2.SiteKey=T3.SiteKey ' +
				' left outer join AvailableReport T4 on  T3.AnalysisRunKey= T4.AnalysisRunKey ' + 
				'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)));
		if @debug=1 exec absp_MessageEx @sql
		exec(@sql)
		set identity_insert #FinalFilterRecords off
		
		update #FinalFilterRecords set NumBuildings=0 where NumBuildingsStatus='U'
		select * from #FinalFilterRecords;
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'','',0,0,0 from Structure T1 where 1=0; 		
	end

	--Return Site Rein--
	set @tableName='FilteredSiteReinsurance_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))

	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin

		set @sql = 'select  T1.*,AccountNumber,SiteNumber,R.Name as ReinsurerName,T.Name  as TreatyTagName,RowNum from Reinsurance T1 inner join ' + @tableName + ' T2 
				on T1.ReinsuranceRowNum=T2.ReinsuranceRowNum 
				inner join Reinsurer R on T1.ReinsurerID=R.ReinsurerID 
				inner join TreatyTag T on T1.TreatyTagID=T.TreatyTagID  
				inner join #Keys K on  T1.SiteKey=K.SiteKey
				 where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T2.AccountKey =' + cast(@accountKey as varchar(30));
		--set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*, '','','','',0 from Reinsurance T1 where 1=0; 		
	end

	--Return Site Condition--
	set @tableName='FilteredSiteCondition_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin

		set @sql = 'select  T1.*,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,RowNum from SiteCondition T1 inner join ' + @tableName + ' T2 
			on T1.SiteConditionRowNum=T2.SiteConditionRowNum 
			inner join #Keys K on T1.StructureKey=0 and T1.SiteKey=K.SiteKey
			where T1.ExposureKey=' + 
			cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30));
		--set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*, '','','','','','',0 from SiteCondition T1 where 1=0; 		
	end		

	--Reurn Structure Condition--
	set @tableName='FilteredStructureCondition_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin
		set @sql = 'select  T1.*,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,RowNum from SiteCondition T1 inner join ' + @tableName + ' T2 
				on T1.SiteConditionRowNum=T2.SiteConditionRowNum 
				inner join #Keys K on T1.StructureKey=K.StructureKey and T1.SiteKey=K.SiteKey
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30));

		--set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*, '','','','','','',0 from SiteCondition T1 where 1=0; 		
	end

	--Return Structure Feature--
	--Create views--
	--Wind--
	set @viewExists=0;
	set @filteredTblView='FilteredTableViewForWnd'
	set @sql='select @viewExists= 1 from SYSOBJECTS where ID = object_id(N''' + @filteredTblView + ''') and objectproperty(id,N''IsView'') = 1 ' 
	exec sp_executesql @sql ,N'@viewExists int out',@viewexists out;
	if @viewexists = 0
	begin
		set @sql =  'create view '+ @filteredTblView + ' as 
		select A.country_id,A.option_Id, A.Field_Name,B.Fetur_Name,A.Short_Desc from wssdlook A inner join WstGrpLk B
		on A.country_id=B.country_id and A.Field_Name=B.Wssd_Field and A.Old_New=B.Old_New and A.Old_New=''N'''
		exec(@sql)
	end
	--EQ--
	set @viewExists=0;
	set @filteredTblView='FilteredTableViewForEQ'
	set @sql='select @viewExists= 1 from SYSOBJECTS where ID = object_id(N''' + @filteredTblView + ''') and objectproperty(id,N''IsView'') = 1 ' 
	exec sp_executesql @sql ,N'@viewExists int out',@viewexists out;
	if @viewexists = 0
	begin
		set @sql =  'create  view '+ @filteredTblView + ' as 
			select A.country_id,A.option_Id, A.Field_Name,B.Fetur_Name,A.Short_Desc from Essdlook A inner join EstGrpLk B
		    on A.country_id=B.country_id and A.Field_Name=B.Essd_Field and A.Old_New=B.Old_New and A.Old_New=''N'''
		exec(@sql)
	end
	--Flood--
	set @viewExists=0;
	set @filteredTblView='FilteredTableViewForFld'
	set @sql='select @viewExists= 1 from SYSOBJECTS where ID = object_id(N''' + @filteredTblView + ''') and objectproperty(id,N''IsView'') = 1 ' 
	exec sp_executesql @sql ,N'@viewExists int out',@viewexists out;
	if @viewexists = 0
	begin
		set @sql =  'create  view '+ @filteredTblView + ' as 
			select A.country_id,A.option_Id, A.Field_Name,B.Fetur_Name,A.Short_Desc from FssdLook A inner join FstGrpLk B
			on A.country_id=B.country_id and A.Field_Name=B.Fssd_Field and A.Old_New=B.Old_New and A.Old_New=''N'''
		exec (@sql)
	end

	set @tableName='FilteredStructureFeature_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin
		set @sql = 'select  T1.*, case when left(FeatureCode,1)=''W'' then ''WIND''  when left(FeatureCode,1)=''F'' then ''Flood'' else ''EARTHQUAKE'' end as FeatureType,
			Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
			SiteNumber,StructureNumber,SiteName,StructureName,T2.CountryCode,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
				on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
				inner join #Keys K on T1.StructureKey=K.StructureKey and T1.SiteKey=K.SiteKey
				inner join FilteredTableViewForWnd W on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = W.Field_Name and W.Option_ID = T1.FeatureValue   and K.CountryCode=W.Country_ID 
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30)) +
				
			 ' union '+
			'select  T1.*, case when left(FeatureCode,1)=''W'' then ''WIND''  when left(FeatureCode,1)=''F'' then ''Flood'' else ''EARTHQUAKE'' end as FeatureType,
			Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
			SiteNumber,StructureNumber,SiteName,StructureName,T2.CountryCode,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
				on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
				inner join #Keys K on T1.StructureKey=K.StructureKey and T1.SiteKey=K.SiteKey
				inner join FilteredTableViewForEQ E on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = E.Field_Name and E.Option_ID = T1.FeatureValue  and K.CountryCode=E.Country_ID
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30))+
				
			 ' union '+
			'select  T1.*, case when left(FeatureCode,1)=''W'' then ''WIND''  when left(FeatureCode,1)=''F'' then ''Flood'' else ''EARTHQUAKE'' end as FeatureType,
			Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
			SiteNumber,StructureNumber,SiteName,StructureName,T2.CountryCode,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
				on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
				inner join #Keys K on T1.StructureKey=K.StructureKey and T1.SiteKey=K.SiteKey
				inner join FilteredTableViewForFld F on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = F.Field_Name and F.Option_ID = T1.FeatureValue  and K.CountryCode=F.Country_ID
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30));

		--set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'','','','','','','',0 from StructureFeature T1 where 1=0; 		
	end


	--Return Structure coverage--
	set @tableName='FilteredStructureCoverage_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin

		set @sql = 'select T1.*,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,RowNum from StructureCoverage T1 inner join ' + @tableName + ' T2 
				on T1.StructureCoverageRowNum=T2.StructureCoverageRowNum 
				inner join #Keys K on T1.StructureKey=K.StructureKey and T1.SiteKey=K.SiteKey
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30));

		--set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'','','','','','',0 from StructureCoverage T1 where 1=0; 		
	end

	--Return PolicyFilter--
	set @tableName='FilteredPolicyFilter_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))

	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	if @attrib=0 and @tableExists=1
	begin
		set @sql = 'select  T1.PolicyFilterRowNum,T1.ExposureKey,T1.AccountKey,T1.PolicyConditionNameKey,T1.StructureKey, ConditionName as PolicyConditionName,AccountNumber,
				StructureNumber,StructureName,SiteNumber,RowNum from ' + @tableName + ' T1  inner join  PolicyConditionName T2
				on T1.PolicyConditionNameKey=T2.PolicyConditionNameKey and T1.ExposureKey=T2.ExposureKey and T1.AccountKey=T2.AccountKey  
				inner join #Keys K on T1.StructureKey=K.StructureKey  
				and T1.ExposureKey=' + cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30)) ;
		--set @sql = @sql + ' order by RowNum'			
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select 0,0,0,0,0,'','','','',0 from PolicyFilter T1 where 1=0; 		
	end


end

