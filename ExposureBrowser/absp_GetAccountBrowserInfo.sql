if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetAccountBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetAccountBrowserInfo
end
go

create  procedure absp_GetAccountBrowserInfo @nodeKey int,
					     @nodeType int, 
					     @exposureKey int =-1, 
					     @accountKey int=-1,
					     @sessionID int,
					     @whereClause varchar(8000)='',
					     @orderByClause varchar(8000)='',
					     @pageNum int=1, 
					     @pageSize int=500,
					     @createTempTable int=1
					     
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose: The procedure will get account information from the AccountBrowserInfo table 
for the given Pport/Program or Exposure.The resultset will be limited by the page size.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey  ^^ The node for which the account summary information is to be fetched.
##PD  @nodeType  ^^ The node type for which the account summary information is to be fetched.
##PD  @exposureKey  ^^ The exposureKey for which the account summary information is to be fetched.
##PD  @accountKey  ^^ The account for which the account summary information is to be fetched.
##PD  @whereClause  ^^ The where clause
##PD  @orderByClause  ^^ The order by clause
##PD  @pageNum  ^^ The page that is to be returned.
##PD  @pageSize  ^^ The size of the page.

*/
as
begin
	BEGIN TRY
		
		set nocount on;
		declare @sql varchar(max);
		declare @startRowNum int;
		declare @endRowNum int;
		declare @tRows int;
		declare @RowCntSql varchar(max);
		declare @debug int;
		declare @tmpTbl varchar(50)
		declare @tmpCntTbl varchar(50)
		declare @BrowserDataStatus varchar(50)
		declare @schemaName varchar(200);
		
		exec absp_MessageEx  'Begin absp_GetAccountBrowserInfo'
		
		set @debug = 0;
		set @tRows= 20000;
		set @tmpTbl='TMP_ACC_SUMMARY' + dbo.trim(cast(@sessionId as varchar(50)))
		set @tmpCntTbl='TMP_ACC_SUMMARY_CNT' + dbo.trim(cast(@sessionId as varchar(50)))
		
	
		set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
		set @endRowNum = @pageNum * @pageSize 
	
		--Create temporary table only when required--
		if @createTempTable=1
		begin
			--Create temp table--
			if exists(select 1 from sys.tables where name=@tmpTbl)
				exec('drop Table ' + @tmpTbl)
		end
	 	
	 	--Get the status of BrowserataGen--
		if @nodeType=4
			exec absp_CheckExposureBrowserInfoStatus @BrowserDataStatus out, -1,-1,@exposureKey
		else
			exec absp_CheckExposureBrowserInfoStatus @BrowserDataStatus out, @nodeKey,@nodeType
			
	 	--Create and populate table if table does not exist--
	 	if not exists(select 1 from sys.tables where name=@tmpTbl)
	 	begin
			--execute absp_Util_CreateTableScript @sql output,'AccountBrowserInfo', @tmpTbl,'',0,0,0
			set @sql='select * into ' + @tmpTbl + ' from AccountBrowserInfo where 1=2'
			exec (@sql)
		
			exec('alter table ' + @tmpTbl + ' add  ReportsAvailable varchar(5) default ''false''')
			
			if @debug=1 exec absp_MessageEx  'Created temporary table'
	
			if @BrowserDataStatus='Available'
			begin
				--Get all exposure Keys for PPort/Program--
				if @nodeType = 2 or @nodeType = 7 or @nodeType = 27
				begin
					--create temp table to hold the ExposureKeys--faster than geninlist--
					if OBJECT_ID('tempdb..#TMP_EXP','u') is not null drop table #TMP_EXP
					select ExposureKey into #TMP_EXP from ExposureMap where ParentKey= @nodeKey and ParentType=@nodeType;
					create index #TMP_EXP_i1 on #TMP_EXP(ExposureKey)

					--Get Rows into temp table--
					set @sql='insert into ' + @tmpTbl + 
						' (ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies,NumberOfLocations,Producer,Company,Division ,Branch,UserData1, UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid)
					select top (' + dbo.trim(cast(@tRows as varchar)) + ') T1.ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies,NumberOfLocations,Producer,Company,Division ,Branch,UserData1, UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid
						from AccountBrowserInfo T1 inner join #TMP_EXP T2  on T1.ExposureKey=T2.ExposureKey'

					set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl + ' from AccountBrowserInfo T1 inner join #TMP_EXP T2  on T1.ExposureKey=T2.ExposureKey'


				end
				else if @nodeType = 4 --NodeKey is AccountKey
				begin
					--Get Rows into temp table--
					set @sql = 'insert into ' +@tmpTbl + 
						' (ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies,NumberOfLocations,Producer,Company,Division ,Branch,UserData1, UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid)
					    select top (' + dbo.trim(cast(@tRows as varchar)) + ') ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies,NumberOfLocations,Producer,Company,Division ,Branch,UserData1, UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid
					from AccountBrowserInfo where ExposureKey = ' + cast(@exposureKey as varchar) + ' and AccountKey = ' + cast(@nodeKey as varchar)

					set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl + ' from AccountBrowserInfo where ExposureKey = ' + cast(@exposureKey as varchar) + ' and AccountKey =' + cast(@nodeKey as varchar)

				end
				else
					return --Incorrect nodeType

				--Add where clause--
				if @whereClause<>''
				begin
					set @sql = @sql + ' and ' + @whereClause
					set @RowCntSql = @RowCntSql + ' and ' + @whereClause
				end

				--Add order by clause--
				if @orderByClause<>''
					set @sql = @sql + ' order by ' + @orderByClause

				if @debug=1 exec absp_MessageEx  @sql
				exec (@sql);
				if @debug=1 exec absp_MessageEx  'Populated temporary table'

				--Drop table to hold rowcount
				if exists(select 1 from sys.tables where name=@tmpCntTbl)
					exec('drop Table ' + @tmpCntTbl)

				--Populate TMP_ACC_SUMMARY_CNT
				if @debug=1 exec absp_MessageEx  @RowCntSql
				exec(@RowCntSql);
				
				--Check if snapshot exists--
				select schemaName into #SchemaName from snapshotinfo t1 
				inner join  snapshotmap t2
				on t1.SnapShotKey=t2.SnapshotKey 
				and t2.nodeKey=@nodeKey and t2.NodeType=@nodeType
				
				if not exists(select 1 from #SchemaName)
				begin
					--Update ReportAvailable column
					set @sql='update '+@tmpTbl +
						' set ReportsAvailable= ''true''  from ' + @tmpTbl + ' A  inner join AnalysisRunInfo B 
						on A.exposurekey=B.exposureKey and A.AccountKey=B.AccountKey and B.SiteKey=0
						inner join AvailableReport C 
						on B.AnalysisRunKey=C.AnalysisRunKey 
						and Status=''Available'''
					exec(@sql)
				end 
				else
				begin
					declare curSch cursor for select schemaName from #schemaName
					open curSch
					fetch curSch into @schemaName
					while @@fetch_status=0
					begin
						--Update ReportAvailable column
						set @sql='update '+@tmpTbl +
							' set ReportsAvailable= ''true''  from ' + @tmpTbl + ' A  inner join ' + @schemaName + '.AnalysisRunInfo B 
							on A.exposurekey=B.exposureKey and A.AccountKey=B.AccountKey and B.SiteKey=0
							inner join ' + @schemaName + '.AvailableReport C 
							on B.AnalysisRunKey=C.AnalysisRunKey 
							and Status=''Available'' and  ReportsAvailable= ''false'' '
						if @debug=1 print @sql
						exec(@sql)
						fetch curSch into @schemaName
					end
					close curSch
					deallocate curSch
				end

			end
		end	
		
		--First resultset will contain the info to be displayed--
		set @sql='select ReportsAvailable,ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies, NumberOfLocations,Producer,Company,Division,
			Branch,UserData1,UserData2,UserData3,PriceOfGas,PriceOfOil,case when FinancialModelType=1 then ''Offshore'' else ''Standard'' end as FinancialModelType,IsValid 
			from ' + @tmpTbl + '  where AccountBrowserInfoRowNum between ' + cast(@startRowNum as varchar) + ' and ' + cast(@endRowNum as varchar) 
			+ ' order by AccountBrowserInfoRowNum ' +
			+ ' OPTION(RECOMPILE)' 
		exec(@sql)
		
		if @debug=1 exec absp_MessageEx  'Returned first resultset'
		
		--Second recordset will return the record count--
		if @BrowserDataStatus='Available'
			exec('select CNT from ' + @tmpCntTbl)
		else
			select 0
		if @debug=1 exec absp_MessageEx  'Returned second resultset'
	
		--Third resultset will returnthe no. of rows returned--
		exec('select count(*) as TotalDisplayRow from ' + @tmpTbl)
		if @debug=1 exec absp_MessageEx  'Returned third resultset'
		
		
		select @BrowserDataStatus
		if @debug=1 exec absp_MessageEx  'Returned fourth resultset'
		
		select COLUMN_NAME,DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME =  @tmpTbl
		if @debug=1 exec absp_MessageEx  'Returned fifth resultset'

	END TRY

	BEGIN CATCH
		declare @ProcName varchar(100);
		select @ProcName=object_name(@@procid);
		exec absp_Util_GetErrorInfo @ProcName;
		--Drop temp tables--
		if exists(select 1 from sys.tables where name=@tmpTbl) exec('drop Table ' + @tmpTbl)
		if exists(select 1 from sys.tables where name=@tmpCntTbl) exec('drop Table ' + @tmpCntTbl)
	END CATCH
	
	exec absp_MessageEx  'End absp_GetAccountBrowserInfo'
end