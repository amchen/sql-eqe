if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MergeLocationBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MergeLocationBrowserInfo
end
go

create  procedure absp_MergeLocationBrowserInfo  @exposureKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will merge LocationBrowserInfo records from temporary tables.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.


*/
as
begin
	set nocount on;

	declare @sql varchar(max);
	declare @tmpTbl varchar(200);
	declare @tName varchar(120)

	--exec absp_Util_DisableIndex 'LocationBrowserInfo',1

	set @tmpTbl='LocationBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'[_]%'
	--Create Temp table to hold merged data--
	select * into #MergedData from LocationBrowserInfo where 1=2
	create index #MergedData_I1 on #MergedData(ExposureKey,AccountKey,StructureKey, SiteKey)


	declare c1 cursor fast_forward for select name from SYS.TABLES where name like @tmpTbl
	open c1
	fetch c1 into @tName
	while @@fetch_status=0
	begin
		set @sql='insert into #MergedData
			(ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,
			AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgrade,NumberOfStories,NumberOfBuildings, StructureTypeDisplayName,
			EQStructureTypeDisplayName,WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,
			WSOccupancyTypeDisplayName,FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment,
			PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid)
		select ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,
			AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgrade,NumberOfStories,NumberOfBuildings, StructureTypeDisplayName,
			EQStructureTypeDisplayName,WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,
			WSOccupancyTypeDisplayName,FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment,
			PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid
		from ' + @tName
		exec (@sql)
		exec('drop table ' + @tName)
		fetch c1 into @tName
	end
	close c1
	deallocate c1

	insert into LocationBrowserInfo
		(ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,
			AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgrade,NumberOfStories,NumberOfBuildings, StructureTypeDisplayName,
			EQStructureTypeDisplayName,WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,
			WSOccupancyTypeDisplayName,FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment,
			PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid)
		select ExposureKey,AccountKey,AccountNumber,SiteNumber,StructureKey, SiteKey,StructureNumber,StructureName,CountryDisplayName,GeocodeLevelDescription,
			AdminLevel1,AdminLevel2,Cresta,Crestavintage,Street,City,PostCode,Latitude, Longitude,YearBuilt,YearUpgrade,NumberOfStories,NumberOfBuildings, StructureTypeDisplayName,
			EQStructureTypeDisplayName,WSStructureTypeDisplayName,FLStructureTypeDisplayName,OccupancyTypeDisplayName,EQOccupancyTypeDisplayName,
			WSOccupancyTypeDisplayName,FLOccupancyTypeDisplayName,StructureModifierDisplayName,PipelineStartingSegment,PipelineEndingSegment,
			PipelineEndingLatitude ,PipelineEndingLongitude,AssetCode,Salary,Headcount,Shift1Weight,Shift2Weight,Shift3Weight,Shift4Weight,IsValid from #MergedData
			order by ExposureKey

	--exec absp_Util_DisableIndex 'LocationBrowserInfo',0
end



