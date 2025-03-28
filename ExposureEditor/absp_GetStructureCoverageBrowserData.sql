if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetStructureCoverageBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetStructureCoverageBrowserData
end
 go

create procedure absp_GetStructureCoverageBrowserData @nodeKey int, @nodeType int, @financialModelType int,@pageNum int,@pageSize int=1000,@userKey int=1,@debug int=0					
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @startRowNum int;
	declare @endRowNum int;
	declare @rowCnt int;
	declare @attrib int;
	declare @pgNum int;
	declare @tableExists int;
	declare @InProgress int;	
	declare @fieldNames varchar(max);
	declare @errorStr varchar(100);
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1
	begin
		select T1.*,'' as AccountNumber,'' as SiteNumber,'' as StructureNumber,'' as SiteName,'' as StructureName,'' as CurrencyCode,'' as ErrorMessage,0 as PageNumber,0 as RowNum from StructureCoverage T1 where 1=0; 
		return;
	end
	
	set @errorStr='''Undetermined. Please view the Import Exception report for more details.'''
	set @tableName='FilteredStructureCoverage_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin
		select @rowCnt=TotalCount from FilteredStatReport where Category='Structure Coverages' and nodeKey=@nodeKey and NodeType=@nodeType

		--Calculate rowNum to be displayed from--
		set @pgNum=@rowCnt /@pageSize;
		if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
		if @pgNum<@pageNum set @pageNum=1


		set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
		set @endRowNum = @startRowNum + @pageSize 

		--For Invalid Records, display Error message--
		if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
		begin
			 --create temporary table to hold 100 rows
			 select * into #TmpStructCov from StructureCoverage where 1=2;
			 execute absp_DataDictGetFields @fieldNames output, 'StructureCoverage',0;
			 
			 set identity_insert #TmpStructCov on
			 set @sql = 'insert into #TmpStructCov (' + @fieldNames + ') select T1.* from StructureCoverage T1 inner join ' + @tableName + ' T2 
					on T1.StructureCoverageRowNum=T2.StructureCoverageRowNum' +
					'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			set @sql = @sql + ' order by RowNum'
			exec absp_MessageEx @sql
			exec(@sql)
			 set identity_insert #TmpStructCov off
			 
			 --Get the Error messages for the above records--
			 select distinct A.ExposureKey, SourceId,UserRowNumber,MessageText into #TmpErrorWarning from ImportErrorWarning A
				 inner join #TmpStructCov B on A.ExposureKey=B.ExposureKey and A.SourceID =B.InputSourceID and A.UserRowNumber =B.InputSourceRowNum
			 
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
			set @sql = 'select distinct T1.*,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,isnull(ErrorMessage,' + @errorStr + ') as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + 
				' as PageNumber,RowNum from  #TmpStructCov  T1 '+
				' inner join ' + @tableName + ' T2 on T1.StructureCoverageRowNum=T2.StructureCoverageRowNum '+
				' left outer join #TmpErrorMsg E on T1.ExposureKey=E.ExposureKey and T1.InputSourceID =E.SourceID and T1.InputSourceRowNum =E.UserRowNumber '
			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
		end
		else
		begin			
			set @sql = 'select distinct T1.*,AccountNumber,SiteNumber,StructureNumber,SiteName,StructureName,CurrencyCode,'''' as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + 
				' as PageNumber,RowNum from StructureCoverage T1 inner join ' + @tableName + ' T2 
				on T1.StructureCoverageRowNum=T2.StructureCoverageRowNum' +
				'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
		end
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'' as AccountNumber,'' as SiteNumber,'' as StructureNumber,'' as SiteName,'' as StructureName,'' as CurrencyCode,'' as ErrorMessage,0 as PageNumber,0 as RowNum from StructureCoverage T1 where 1=0; 
			
	end
end
