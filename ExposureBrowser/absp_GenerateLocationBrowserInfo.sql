if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateLocationBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateLocationBrowserInfo
end
go

create  procedure absp_GenerateLocationBrowserInfo  @exposureKey int, @chunkSize int,@chunkNo int=0,  @startRowNum int  
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will add all Location summary records in the 
 		LocationBrowserInfo table  based on the given exposureKey.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.
##PD  @chunkSize  ^^ The chunk size
##PD  @chunkNo  ^^ The chunk number
##PD  @startRowNum  ^^ The start row number


*/
as
begin
	set nocount on;
	
	declare @sql varchar(max);
	declare @tmpTbl varchar(200);
	declare @indexName varchar(200);
	declare @tmpTbl2 varchar(200);
	declare @BrowserDataGenerated varchar(1);
		 		
	--Return if Browser data has already been generated--
	select @BrowserDataGenerated= IsBrowserDataGenerated  from exposureinfo where ExposureKey =@exposureKey
	if @BrowserDataGenerated='Y' return

	if @chunkNo=0 set @chunkNo= @startRowNum
	
	set @tmpTbl='LocationBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) + '_'+ dbo.trim(cast(@chunkNo as varchar(50)))
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl + ''') drop table ' + @tmpTbl
	exec (@sql)
	
	set @tmpTbl2='TMPTBL_LOC_' + dbo.trim(cast(@exposureKey as varchar(50))) + '_'+ dbo.trim(cast(@chunkNo as varchar(50)))
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
	exec (@sql)
			
		
	--Get rows to be inserted in a temp table--
	set @sql='select distinct A.ExposureKey,A.AccountKey,AccountNumber,SiteNumber,A.StructureKey, A.SiteKey,StructureNumber,
		StructureName,CountryCode, GeocodeLevelID,space(150) as GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,StreetAddress,City ,
		PostCode,Latitude,Longitude,YearBuilt,YearUpgraded,NumStories,NumBuildings, StructureTypeID,space(75) as StructureTypeDisplayName,
		EQStructureTypeID,space(75) as EQStructureTypeDisplayName,WSStructureTypeID,space(75) as WSStructureTypeDisplayName,
		FLStructureTypeID,space(75) as FLStructureTypeDisplayName,OccupancyTypeID ,space(75) as OccupancyTypeDisplayName,
		EQOccupancyTypeId,space(75) as EQOccupancyTypeDisplayName,WSOccupancyTypeID,space(75) as WSOccupancyTypeDisplayName,
		FLOccupancyTypeID,space(75) as FLOccupancyTypeDisplayName,StructureModifierID,space(50) as StructureModifierDisplayName,  
		BoemBlock as PipelineStartingSegment,PipelineEndingBlock as PipelineEndingSegment,PipelineEndingLatitude ,PipelineEndingLongitude,
		AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,A.IsValid 	
	into ' + @tmpTbl2 +
	' from Structure A 
	inner join Site B on A.ExposureKey=B.ExposureKey and A.AccountKey=B.AccountKey and A.SiteKey=B.SiteKey	
	inner join Account C on B.ExposureKey= C.ExposureKey and B.AccountKey=C.AccountKey
	where A.ExposureKey = ' + cast(@exposureKey as varchar(20)) +
	' and StructureRowNum between ' + cast(@startRowNum as varchar(20)) + ' and ' + cast(@startRowNum + @chunkSize -1 as varchar(20)) + ' OPTION(RECOMPILE)'
	exec (@sql)
		
	--Do not update lookups for invalid rows
	--Insert them in temptable	
	set @sql='select ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,B.Iso_3 as CountryDisplayName,
		case when GeocodeLevelID <1 then  ''Not Geocoded'' else cast(GeocodeLevelID as varchar(150)) end as GeocodeLevelDescription,
		AdminLevel1,AdminLevel2,Cresta,	Crestavintage,StreetAddress as Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgraded as YearUpgrade,NumStories as NumberOfStories,NumBuildings as NumberOfBuildings,cast(StructureTypeID as varchar(50)) as StructureTypeDisplayName,
		cast(EQStructureTypeID as varchar(75)) as EQStructureTypeDisplayName,cast(WSStructureTypeID as varchar(75)) as WSStructureTypeDisplayName ,
		cast(FLStructureTypeID as varchar(75)) as FLStructureTypeDisplayName,cast(OccupancyTypeID as varchar(75)) OccupancyTypeDisplayName,
		cast(EQOccupancyTypeID as varchar(75)) EQOccupancyTypeDisplayName,cast(WSOccupancyTypeID as varchar(75)) WSOccupancyTypeDisplayName,
		cast(FLOccupancyTypeID as varchar(75)) FLOccupancyTypeDisplayName,cast(StructureModifierID as varchar(75)) as StructureModifierDisplayName ,
		PipelineStartingSegment,PipelineEndingSegment,PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid
	into ' + @tmpTbl +
	' from ' + @tmpTbl2 + ' A inner join Country B on B.Country_id=A.CountryCode where A.IsValid=0'	
	exec (@sql)
		
	--Delete invalid rows from temp table--
	exec ('delete from ' + @tmpTbl2 + ' where IsValid=0')
				
	set @indexName=dbo.trim(@tmpTbl) +'_I1'
	set @sql='create index ' + @indexName + ' on ' + @tmpTbl + '(ExposureKey,AccountKey,StructureKey, SiteKey)'
	exec (@sql)
			
	--Insert them in LocationBrowserInfo updating lookups for valid rows
	set @sql='insert into ' + @tmpTbl +
		' select ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,D.Iso_3 as CountryDisplayName,
		M.GeocodeLevelDescription as GeocodeLevelDescription,AdminLevel1,AdminLevel2,Cresta,Crestavintage,StreetAddress as Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgraded as YearUpgrade,NumStories as NumberOfStories,
		NumBuildings as NumberOfBuildings, 
		case when B.StructureTypeID =0 then ''Peril-dependent'' else E.Comp_Descr end  as StructureTypeDisplayName,
		F.Comp_Descr as EQStructureTypeDisplayName,G.Comp_Descr as WSStructureTypeDisplayName,H.Comp_Descr as FLStructureTypeDisplayName,
		case when B.OccupancyTypeID =0 then ''Peril-dependent'' else I.W_Occ_Desc end,
		J.E_Occ_Desc as EQOccupancyTypeDisplayName,K.W_Occ_Desc as WSOccupancyTypeDisplayName,
		L.F_Occ_Desc as FLOccupancyTypeDisplayName,C.Name as StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment,
		PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid
		from ' + @tmpTbl2 + ' B 
		inner join StructureModifier C on  B.StructureModifierID=C.StructureModifierID
		inner join Country D on D.Country_id=B.CountryCode
		inner join Wsdl E on B.StructureTypeID=E.Str_Ws_ID and B.CountryCode=E.Country_ID and E.Trans_ID=67
		inner join Esdl F on isnull(B.EqStructureTypeID,0)=F.Str_Eq_ID and B.CountryCode=F.Country_ID
		inner join Wsdl G on isnull(B.WsStructureTypeID,0)=G.Str_Ws_ID and B.CountryCode=G.Country_ID
		inner join Fsdl H on isnull(B.FlStructureTypeID,0)=H.Str_Fd_ID and B.CountryCode=H.Country_ID
		inner join Wotdl I on B.OccupancyTypeID=I.W_Occpy_ID and B.CountryCode=I.Country_ID and I.Trans_ID=67
		inner join Eotdl J on isnull(B.EqOccupancyTypeID,0)=J.E_Occpy_ID and B.CountryCode=J.Country_ID
		inner join Wotdl K on isnull(B.WsOccupancyTypeID,0)=K.W_Occpy_ID and B.CountryCode=K.Country_ID
		inner join Fotdl L on isnull(B.FlOccupancyTypeID,0)=L.F_Occpy_ID and B.CountryCode=L.Country_ID 
		inner join GeocodeLevel M on B.GeocodeLevelID=M.GeocodeLevel'
	exec (@sql)		

	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
	exec (@sql)
	
	
end



   		
