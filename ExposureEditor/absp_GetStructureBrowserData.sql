if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetStructureBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetStructureBrowserData
end
 go

create procedure absp_GetStructureBrowserData @nodeKey int, @nodeType int, @financialModelType int, @pageNum int,@pageSize int=1000,@exposureKey int =-1,@accountKey int =-1,@userKey int=1,@debug int=0					
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
	
	select *,space(50) as AccountNumber,space(50) as SiteNumber,0 as ReportsAvailable,space(5999) as ErrorMessage,0 as PageNumber,0 as RowNum  
		into #FinalFilterRecords from Structure where 1=0	

	if @InProgress=1
	begin
		select * from #FinalFilterRecords; 
		return;
	end		
	
	set @startRowNum=0;
	set @errorStr='''Undetermined. Please view the Import Exception report for more details.'''
	
	set @tableName='FilteredStructure_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 
	
	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin	
		if @exposureKey<>-1 --For relational view
		begin
			set @sql = 'select top(1) @startRowNum=RowNum from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec absp_MessageEx @sql			
			exec sp_executesql @sql,N'@startRowNum int out' ,@startRowNum out

			set @sql = 'select @rowCnt=count(*) from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec sp_executesql @sql,N'@rowCnt int out' ,@rowCnt out
		end
		else
		begin
			select @rowCnt=TotalCount from FilteredStatReport where category='Structures' and nodeKey=@nodeKey and NodeType=@nodeType
		end	
		
		--Calculate rowNum to be displayed from--
		if @rowCnt>=@pageSize
		begin
			set @pgNum=@rowCnt /@pageSize;
			if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
			if @pgNum<@pageNum set @pageNum=1
		end	
		set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
		set @endRowNum = @startRowNum + @pageSize 

		execute absp_DataDictGetFields @fieldNames output, 'Structure',0;
		--For Invalid Records, display Error message--
		if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
		begin
			 --create temporary table to hold 100 rows
			 select * into #TmpStruct from Structure where 1=2;	 	 
			 
			 set identity_insert #TmpStruct on
			 set @sql = 'insert into #TmpStruct(' + @fieldNames + ') select T1.* from Structure T1 inner join ' + @tableName + ' T2 
					on T1.StructureRowNum=T2.StructureRowNum '+
					'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			if @exposureKey<>-1
				set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)));
	
			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql

			exec(@sql)
			set identity_insert #TmpStruct off
			 
			 --Get the Error messages for the above records--
			 select distinct A.ExposureKey, SourceId,UserRowNumber,MessageText into #TmpErrorWarning from ImportErrorWarning A 
					inner join #TmpStruct B on A.ExposureKey=B.ExposureKey and A.SourceID =B.InputSourceID and A.UserRowNumber =B.InputSourceRowNum
			 
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
			
			----Get the final query--
			set identity_insert #FinalFilterRecords on
			set @sql = 'insert into  #FinalFilterRecords (' + @fieldNames + ',AccountNumber,SiteNumber,ReportsAvailable,ErrorMessage,PageNumber,RowNum)
			select distinct T1.* ,AccountNumber,SiteNumber, 0 as ReportsAvailable,	isnull(ErrorMessage,' + @errorStr + ') as ErrorMessage,' +
			dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum 
			from #TmpStruct T1 inner join ' + @tableName + ' T2 on T1.StructureRowNum=T2.StructureRowNum '+
			' left outer join #TmpErrorMsg E on T1.ExposureKey=E.ExposureKey and T1.InputSourceID =E.SourceID and T1.InputSourceRowNum =E.UserRowNumber '
			set @sql = @sql + ' order by RowNum'	
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
			set identity_insert #FinalFilterRecords off
		end
		else
		begin	
			set identity_insert #FinalFilterRecords on
			set @sql = 'insert into  #FinalFilterRecords (' + @fieldNames + ',AccountNumber,SiteNumber,ReportsAvailable,ErrorMessage,PageNumber,RowNum)
				select distinct T1.* ,AccountNumber,SiteNumber, 0 as ReportsAvailable,'''' as ErrorMessage,' +
				dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum  from Structure T1 inner join ' + @tableName + ' T2 
				on T1.StructureRowNum=T2.StructureRowNum '+
				'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			if @exposureKey<>-1
				set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)));
			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
			set identity_insert #FinalFilterRecords off
		end
	end
	exec absp_UpdateReportsAvailableColumn @nodeKey,@nodeType,'Structure'
	update #FinalFilterRecords set NumBuildings=0 where NumBuildingsStatus='U'
	select * from #FinalFilterRecords;
	
end
