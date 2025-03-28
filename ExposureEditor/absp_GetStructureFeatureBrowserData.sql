if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetStructureFeatureBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetStructureFeatureBrowserData
end
 go

create procedure absp_GetStructureFeatureBrowserData @nodeKey int, @nodeType int, @financialModelType int, @pageNum int,@pageSize int=1000,@userKey int=1,@debug int=0					
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @startRowNum int;
	declare @endRowNum int;
	declare @rowCnt int;
	declare @attrib int;
	declare @pgNum float;
	declare @tableExists int;
	declare @viewExists int;
	declare @filteredTblView varchar(120);
	declare @InProgress int;
	declare @viewInvalidRecords int;
	declare @exposureKeyList varchar(max);
	declare @fieldNames varchar(max);
	declare @errorStr varchar(100);
	
	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
   	if @exposureKeyList='' return;
   	
	set @viewInvalidRecords=0;	
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1
	begin
		select T1.*,'' as FeatureType,'' as FeatureName,'' as FeatureDescription,'' as AccountNumber,'' as SiteNumber,'' as StructureNumber,'' as CountryCode,'' as ErrorMessage,0 as PageNumber,0 as RowNum from StructureFeature T1 where 1=0; 
		return;
	end
	
	if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
	begin
		set @viewInvalidRecords=1;
	end
	
	set @errorStr='''Undetermined. Please view the Import Exception report for more details.'''
	set @tableName='FilteredStructureFeature_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 
	
	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin
	
		--Create views
		if @viewInvalidRecords=0
		begin
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

			--EQ
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
				exec(@sql)
			end
		end

		select @rowCnt=TotalCount from FilteredStatReport where Category='Structure Features' and nodeKey=@nodeKey and NodeType=@nodeType

		--Calculate rowNum to be displayed from--
		set @pgNum=@rowCnt /@pageSize;
		if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
		if @pgNum<@pageNum set @pageNum=1

		set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
		set @endRowNum = @startRowNum  + @pageSize 
		if @viewInvalidRecords=0
		begin
			set @sql = 'select distinct T1.*, case when left(FeatureCode,1)=''W'' then ''Wind'' when left(FeatureCode,1)=''F'' then ''Flood''else ''Earthquake'' end as FeatureType,
				Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
				SiteNumber,StructureNumber,SiteName,StructureName,CountryCode as CountryCode,'''' as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + 
					' as PageNumber,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
					on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
					inner join FilteredTableViewForWnd W on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = W.Field_Name and W.Option_ID = T1.FeatureValue and T2.CountryCode=W.country_id
					where   RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)))+
					' and T1.ExposureKey ' + @exposureKeyList +
				 ' union '+
			'select distinct T1.*, case when left(FeatureCode,1)=''W'' then ''Wind'' when left(FeatureCode,1)=''F'' then ''Flood''else ''Earthquake'' end as FeatureType,
				Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
				SiteNumber,StructureNumber,SiteName,StructureName,CountryCode as CountryCode,'''' as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + 
					' as PageNumber,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
					on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
					inner join FilteredTableViewForEQ E on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = E.Field_Name and E.Option_ID = T1.FeatureValue  and T2.CountryCode=E.country_id
					where   RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) +
					' and T1.ExposureKey ' + @exposureKeyList +
			' union '+
			'select distinct T1.*, case when left(FeatureCode,1)=''W'' then ''Wind'' when left(FeatureCode,1)=''F'' then ''Flood''else ''Earthquake'' end as FeatureType,
				Fetur_Name as FeatureName,Short_Desc as FeatureDescription,AccountNumber,
				SiteNumber,StructureNumber,SiteName,StructureName,CountryCode as CountryCode,'''' as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + 
					' as PageNumber,RowNum from StructureFeature T1 inner join ' + @tableName + ' T2 
					on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum 
					inner join FilteredTableViewForFld F on RIGHT(T1.Featurecode, LEN(T1.Featurecode) - 2) = F.Field_Name and F.Option_ID = T1.FeatureValue  and T2.CountryCode=F.country_id
					where   RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) +
					' and T1.ExposureKey ' + @exposureKeyList;
			exec absp_MessageEx @sql
			exec(@sql)

		end
		else
		begin
			--For Invalid Records, display Error message--
			 --create temporary table to hold 100 rows
			 select * into #TmpStructF from StructureFeature where 1=2;
			 execute absp_DataDictGetFields @fieldNames output, 'StructureFeature',0;
			 
			 set identity_insert #TmpStructF on
			 set @sql = 'insert into #TmpStructF (' + @fieldNames + ') select T1.* from StructureFeature T1 inner join ' + @tableName + ' T2 
					on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum ' +
					'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)))+
					' and T1.ExposureKey ' + @exposureKeyList;
			set @sql = @sql + ' order by RowNum'
			exec absp_MessageEx @sql
			exec(@sql)
			set identity_insert #TmpStructF off
			 
			 --Get the Error messages for the above records--
			 select distinct A.ExposureKey, SourceId,UserRowNumber,MessageText into #TmpErrorWarning from ImportErrorWarning A
				 inner join #TmpStructF B on A.ExposureKey=B.ExposureKey and A.SourceID =B.InputSourceID and A.UserRowNumber =B.InputSourceRowNum
			 
			 --Concatenate rows--
			 select distinct
				ExposureKey,SourceID ,UserRowNumber,
				STUFF(
					(SELECT      '^' + A.MessageText 
						FROM      #TmpErrorWarning AS A
					WHERE      A.ExposureKey=B.ExposureKey and A.SourceID =B.SourceID and A.UserRowNumber =B.UserRowNumber
					FOR XML PATH('')), 1, 1, '') AS ErrorMessage
				into #TmpErrorMsg
				FROM  #TmpErrorWarning as B

			--Get the final query--		
			set @sql = 'select distinct T1.*, case when left(FeatureCode,1)=''W'' then ''Wind'' when left(FeatureCode,1)=''F'' then ''Flood'' else ''Earthquake'' end as FeatureType,
				'''' as FeatureName,'''' as FeatureDescription, AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CountryCode as CountryCode,
				isnull(ErrorMessage,' + @errorStr + ') as ErrorMessage,' +
				dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum from #TmpStructF T1 inner join ' + @tableName + ' T2 
				on T1.StructureFeatureRowNum=T2.StructureFeatureRowNum '+
				' left outer join #TmpErrorMsg E on T1.ExposureKey=E.ExposureKey and T1.InputSourceID =E.SourceID and T1.InputSourceRowNum =E.UserRowNumber '+
				' and T1.ExposureKey ' + @exposureKeyList;
			set @sql = @sql + ' order by RowNum'
			exec absp_MessageEx @sql
			exec(@sql)
		end
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'' as FeatureType,'' as FeatureName,'' as FeatureDescription,'' as AccountNumber,'' as SiteNumber,'' as StructureNumber,'' as CountryCode,'' as ErrorMessage,0 as PageNumber,0 as RowNum from StructureFeature T1 where 1=0; 
			
	end

end
