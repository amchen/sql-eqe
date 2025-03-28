if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetLocationBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetLocationBrowserInfo
end
go

create  procedure absp_GetLocationBrowserInfo @nodeKey int,
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
Purpose: The procedure will get the summary information from the LocationBrowserInfo table 
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
		declare @RowCntSql varchar(max);
		declare @startRowNum int;
		declare @endRowNum int;
		declare @tRows int;
		declare @debug int;
		declare @tmpTbl varchar(50)
		declare @tmpCntTbl varchar(50)
		declare @BrowserDataStatus varchar(50)
		declare @financialModelType smallint
		declare @schemaName varchar(200);
		
		exec absp_MessageEx  'Begin absp_GetLocationBrowserInfo'
		
		set @debug = 0;
			
		set @tRows= 20000;
		set @tmpTbl='TMP_LOC_SUMMARY' + dbo.trim(cast(@sessionId as varchar(50)))
		set @tmpCntTbl='TMP_LOC_SUMMARY_CNT' + dbo.trim(cast(@sessionId as varchar(50)))

		
		
		if @orderByClause='' set @orderByClause='AccountNumber, SiteNumber, StructureNumber'
		
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
			--execute absp_Util_CreateTableScript @sql output,'LocationBrowserInfo', @tmpTbl,'',0,0,0
			set @sql='select * into ' + @tmpTbl + ' from LocationBrowserInfo where 1=2'
			exec (@sql)
			exec('alter table ' +@tmpTbl + ' add  ReportsAvailable varchar(5)default ''false'', FinancialModelType smallint default 0')
			
			if @debug=1 exec absp_MessageEx  'Created temporary table'
			
			if @BrowserDataStatus='Available'
			begin

				--Get all exposure and accountKeys for PPort/Program--
				if @nodeType = 2 or @nodeType = 7 or @nodeType = 27
				begin
					--create temp table to hold the ExposureKeys--
					if OBJECT_ID('tempdb..#TMP_EXP','u') is not null drop table #TMP_EXP
					select ExposureMap.ExposureKey,FinancialModelType into #TMP_EXP from ExposureMap 
						inner join ExposureInfo on ExposureMap.ExposureKey=ExposureInfo.ExposureKey
						where ParentKey= @nodeKey and ParentType=@nodeType;
					create index #TMP_EXP_i1 on #TMP_EXP(ExposureKey)

					--Get Rows into temp table--		    
					set @sql = 'insert into ' + @tmpTbl + 
							' (ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,
							PostCode,Latitude, Longitude, YearBuilt, YearUpgrade, NumberOfStories, NumberOfBuildings,StructureTypeDisplayName, EQStructureTypeDisplayName,
							WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,WSOccupancyTypeDisplayName,
							FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment, PipelineEndingLatitude, PipelineEndingLongitude, AssetCode,
							Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,FinancialModelType,IsValid)
						    select top (' + dbo.trim(cast(@tRows as varchar)) + ') T1.ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,
							PostCode,Latitude, Longitude, YearBuilt, YearUpgrade, NumberOfStories, NumberOfBuildings,StructureTypeDisplayName, EQStructureTypeDisplayName,
							WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,WSOccupancyTypeDisplayName,
							FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment, PipelineEndingLatitude, PipelineEndingLongitude, AssetCode,
							Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,FinancialModelType,IsValid
						from LocationBrowserInfo T1 inner join #TMP_EXP T2  on T1.ExposureKey=T2.ExposureKey' 

					set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl +' from LocationBrowserInfo T1 inner join #TMP_EXP T2  on T1.ExposureKey=T2.ExposureKey'

				end
				else if @nodeType = 4 --NodeKey is AccountKey
				begin
					--Get FinancialModelType for the exposure--
					select @financialModelType = FinancialModelType from ExposureInfo where ExposureKey=@exposureKey
					--Get Rows into temp table
					set @sql = 'insert into ' + @tmpTbl + 
						' (ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,
							PostCode,Latitude, Longitude, YearBuilt, YearUpgrade, NumberOfStories, NumberOfBuildings,StructureTypeDisplayName, EQStructureTypeDisplayName,
							WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,WSOccupancyTypeDisplayName,
							FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment, PipelineEndingLatitude, PipelineEndingLongitude, AssetCode,
							Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,FinancialModelType,IsValid)
					    select top (' + dbo.trim(cast(@tRows as varchar)) + ') ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,
							PostCode,Latitude, Longitude, YearBuilt, YearUpgrade, NumberOfStories, NumberOfBuildings,StructureTypeDisplayName, EQStructureTypeDisplayName,
							WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,WSOccupancyTypeDisplayName,
							FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment, PipelineEndingLatitude, PipelineEndingLongitude, AssetCode,
							Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,' + cast (@financialModelType as varchar) + ', IsValid
						from LocationBrowserInfo where ExposureKey = ' + cast(@exposureKey as varchar) + 
						 ' and AccountKey =' + cast(@nodeKey	as varchar) 

					set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl + ' from LocationBrowserInfo where ExposureKey = ' + cast(@exposureKey as varchar) + ' and AccountKey =' + cast(@nodeKey as varchar)

				end
				else
					return --Incorrect nodeType	

				--Add where clause
				if @whereClause<>''
				begin
					set @sql = @sql + ' and ' + @whereClause
					set @RowCntSql = @RowCntSql + ' and ' + @whereClause
				end

				--Add order by clause
				if @orderByClause<>''
					set @sql = @sql + ' order by ' + @orderByClause
				if @debug=1 exec absp_MessageEx  @sql
				exec (@sql);
				if @debug=1 exec absp_MessageEx  'Populated temporary table'

				--Drop table to hold rowcount
				if exists(select 1 from sys.tables where name=@tmpCntTbl)
					exec('drop Table ' + @tmpCntTbl)

				--Populate TMP_LOC_SUMMARY_CNT
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
						on A.exposurekey=B.exposureKey and A.AccountKey=B.AccountKey and A.SiteKey=B.SiteKey
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
							on A.exposurekey=B.exposureKey and A.AccountKey=B.AccountKey and A.SiteKey=B.SiteKey
							inner join ' + @schemaName + '.AvailableReport C 
							on B.AnalysisRunKey=C.AnalysisRunKey 
							and Status=''Available'' and  ReportsAvailable= ''false'' '
						
						exec(@sql)
						fetch curSch into @schemaName
					end
					close curSch
					deallocate curSch
				end			

			end
		end
		--First resultset will contain the info to be displayed--
		set @sql='select ReportsAvailable,ExposureKey,AccountKey,SiteKey,StructureKey,AccountNumber,SiteNumber,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,
					PostCode,Latitude, Longitude, cast(YearBuilt as varchar(10)) as YearBuilt, cast(YearUpgrade as varchar(10)) as YearUpgrade, NumberOfStories, NumberOfBuildings,
					StructureTypeDisplayName, EQStructureTypeDisplayName,WSStructureTypeDisplayName,FLStructureTypeDisplayName,
					OccupancyTypeDisplayName,EQOccupancyTypeDisplayName ,WSOccupancyTypeDisplayName,FLOccupancyTypeDisplayName,
					StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment, PipelineEndingLatitude, 
					PipelineEndingLongitude, AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,FinancialModelType,IsValid
			from ' + @tmpTbl + ' where LocationBrowserInfoRowNum between ' + cast(@startRowNum as varchar) + ' and ' + cast(@endRowNum as varchar ) 
			+ ' order by LocationBrowserInfoRowNum ' +
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
		
		--Fourth Resultset will return the status of BrowserataGen--
		select @BrowserDataStatus
		if @debug=1 exec absp_MessageEx  'Returned fourth resultset'
		
		select COLUMN_NAME,DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tmpTbl
		if @debug=1 exec absp_MessageEx  'Returned fifth resultset'

	END TRY

	BEGIN CATCH
		declare @ProcName varchar(100);
		select @ProcName=object_name(@@procid);
		exec absp_Util_GetErrorInfo @ProcName;
		if exists(select 1 from sys.tables where name=@tmpTbl)  exec('drop Table ' + @tmpTbl)
		if exists(select 1 from sys.tables where name=@tmpCntTbl) exec('drop Table ' + @tmpCntTbl)
	END CATCH
	exec absp_MessageEx  'End absp_GetLocationBrowserInfo'
end