if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposureRejectedByCountry') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureRejectedByCountry;
end
go

create procedure absp_ExposureRejectedByCountry @nodeType int, @nodeKey int
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
	select GeocodeLevel,GeocodeLevelDescription into #GeocodeLevel from GeocodeLevel where GeocodeLevel < 0;
	CREATE NONCLUSTERED INDEX #GeocodeLevel_i1 ON #GeocodeLevel (GeocodeLevel);
	select Iso_3 as Country,CountryKey into #Country from Country;
	CREATE NONCLUSTERED INDEX #Country_i1 ON #Country (CountryKey);

	--narrow for exposurekeys of interest
	SELECT ExposureKey
	INTO #tmp1
	FROM ExposureReportInfo i
		INNER JOIN [#NODELIST] n ON n.NODE_KEY = i.ParentKey
			AND n.NODE_TYPE = i.ParentType
	WHERE STATUS='ACTIVE'

	BEGIN
		--extract value column for rollup and create index
		SELECT t.Country, s.ExposureKey, s.StructureKey, 1 as NumStructures, s.NumBuildings, sc.Value, g.GeocodeLevelDescription
		INTO #xExposureRejected
		FROM Structure s
			INNER JOIN StructureCoverage sc on s.ExposureKey=sc.ExposureKey and s.AccountKey=sc.AccountKey and s.StructureKey=sc.StructureKey and s.SiteKey=sc.SiteKey
			INNER JOIN #GeocodeLevel g ON s.GeocodeLevelID = g.GeocodeLevel
			INNER JOIN #Country t ON s.CountryKey = t.CountryKey
		WHERE s.ExposureKey in (select ExposureKey from #tmp1)
			and s.GeocodeLevelID < 0;

		CREATE NONCLUSTERED INDEX #xExposureRejected_i1 ON #xExposureRejected (Country);

		--Final rollup
		insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Country,NumStructures,NumBuildings,Total,GeocodeLevel)
			SELECT @NodeKey,@NodeType,57,0
			,Country
			,'NumStructures'=sum(NumStructures)
			,'NumBuildings'=sum(NumBuildings)
			,'Total'=sum(Value)
			,GeocodeLevelDescription
			FROM #xExposureRejected
			GROUP BY Country,GeocodeLevelDescription
			ORDER BY Country;

		if (@@rowcount = 0) begin
			insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Country,NumStructures,NumBuildings,Total,GeocodeLevel)
				values (@NodeKey,@NodeType,57,0,'No records to display',NULL,NULL,NULL,NULL);
		end
	END
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--exec absp_ExposureRejectedByCountry @nodeType=2, @nodeKey=1
--select * from ExposureSummaryReport where EngineCallID=57 and IsRegion=0

