if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposureGeocodeLevelByRegion') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureGeocodeLevelByRegion;
end
go

create procedure absp_ExposureGeocodeLevelByRegion @nodeType int, @nodeKey int
as
BEGIN TRY

	set nocount on;

	--create temp table to populate in absp_PopulateChildList
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);

	--get all child nodes and populate #NODELIST
  	execute absp_PopulateChildList @nodeKey, @nodeType;

	--insert record for ourselves
	if (@nodeType = 2 or @nodeType = 7 or @nodeType = 27)
		insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey,@nodeType);

	--get rid of uninterested nodetypes
	delete from #NODELIST where NODE_TYPE not in (2,7,27);

	--create indexing for tables and columns of interest
	select Cover_ID,Cover_Type into #CIL from CIL;
	CREATE NONCLUSTERED INDEX #CIL_i1 ON #CIL  (Cover_ID);
	select Iso_3 as Country,CountryKey into #Country from Country;
	CREATE NONCLUSTERED INDEX #Country_i1 ON #Country (CountryKey);
	select RRgn_Key,Name into #RRegions from RRegions;
	CREATE NONCLUSTERED INDEX #RRegions_i1 ON #RRegions (RRgn_Key);
	select Peril_ID,PerilDisplayName into #PTL from PTL WHERE (Trans_ID IN (67));
	CREATE NONCLUSTERED INDEX #PTL_i1 ON #PTL  (Peril_ID);
	select GeocodeLevel,GeocodeLevelDescription into #GeocodeLevel from GeocodeLevel;
	CREATE NONCLUSTERED INDEX #GeocodeLevel_i1 ON #GeocodeLevel  (GeocodeLevel);


	--narrow for exposurekeys of interest
	SELECT ExposureKey
	INTO #tmp1
	FROM ExposureReportInfo i
		INNER JOIN [#NODELIST] n ON n.NODE_KEY = i.ParentKey
			AND n.NODE_TYPE = i.ParentType
	WHERE STATUS='ACTIVE';

	BEGIN
		--extract value column for rollup and create index
		SELECT GeocodeLevelDescription, t.country, r.Name as 'Region', e.ExposureKey, e.CBPerilID, e.StructureKey, e.NumStructures, e.NumBuildings, e.Value,
			CASE WHEN c.Cover_Type = 'B' THEN e.Value ELSE 0 END AS 'BValue',
			CASE WHEN c.Cover_Type = 'C' THEN e.Value ELSE 0 END AS 'CValue',
			CASE WHEN c.Cover_Type = 'T' THEN e.Value ELSE 0 END AS 'BIValue'
		INTO #xExposureGeocodeLevelByRegion
		FROM ExposureReport e WITH (NOLOCK)
			INNER JOIN #CIL c ON e.CoverageID = c.Cover_ID
			INNER JOIN #Country t ON e.CountryKey = t.CountryKey
			INNER JOIN #RRegions r ON e.RegionKey = r.RRgn_Key
			INNER JOIN #GeocodeLevel g ON e.GeocodeLevelID = g.GeocodeLevel
		WHERE e.ExposureKey in (select ExposureKey from #tmp1)
		AND e.IsValid=1;

		CREATE NONCLUSTERED INDEX #x1_i1 ON #xExposureGeocodeLevelByRegion (ExposureKey,StructureKey,CBPerilID);

		--summing values particularly by exposurekey and structurekey (to prevent double counting); also creating index
		SELECT GeocodeLevelDescription, Country, Region, CBPerilID, ExposureKey, StructureKey, NumStructures, NumBuildings,
		sum(BValue)  as BV,
		sum(CValue)  as CV,
		sum(BIValue) as BI
		INTO #x1
		FROM(SELECT GeocodeLevelDescription, Country, Region, e.CBPerilID, e.ExposureKey, e.StructureKey, e.NumStructures, e.NumBuildings, BValue, CValue, BIValue
			FROM #xExposureGeocodeLevelByRegion AS e) as #tmp
		GROUP BY GeocodeLevelDescription,Country,Region,CBPerilID,ExposureKey,StructureKey,NumStructures,NumBuildings;

		CREATE NONCLUSTERED INDEX #x2_i1 ON #x1  (CBPerilID);

		--Final rollup
		insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,GeocodeLevel,Country,Region,Peril,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
			SELECT @NodeKey,@NodeType,52,1
			,GeocodeLevelDescription as 'GeocodeLevel', Country, Region
			,'Peril'=p.PerilDisplayName
			,'NumStructures'=sum(NumStructures)
			,'NumBuildings'=sum(NumBuildings)
			,'BuildingValue'=sum(BV)
			,'ContentsValue'=sum(CV)
			,'TotalPropertyValue'=sum(BV)+sum(CV)
			,'BIValue'=sum(BI)
			,'Total'=sum(BV)+sum(CV)+sum(BI)
			FROM #x1 e WITH (NOLOCK)
				INNER JOIN #PTL AS p ON e.CBPerilID = p.Peril_ID
			GROUP BY GeocodeLevelDescription,Country,Region,p.PerilDisplayName;

		if (@@rowcount = 0) begin
			insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,GeocodeLevel,Country,Region,Peril,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
				values (@NodeKey,@NodeType,52,1,NULL,NULL,NULL,'No records to display',NULL,NULL,NULL,NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--absp_ExposureGeocodeLevelByRegion @nodeType=7, @nodeKey=1
