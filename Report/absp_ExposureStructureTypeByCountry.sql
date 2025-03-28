if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposureStructureTypeByCountry') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureStructureTypeByCountry;
end
go

create procedure absp_ExposureStructureTypeByCountry @nodeType int, @nodeKey int
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
	select Cover_ID,Cover_Type into #CIL from CIL
	CREATE NONCLUSTERED INDEX #CIL_i1 ON #CIL  (Cover_ID);
	select Iso_3 as Country,CountryKey into #Country from Country
	CREATE NONCLUSTERED INDEX #Country_i1 ON #Country  (CountryKey);
	select distinct str_id,periltype,Country_ID,Comp_Descr into #StructureType from StructureType
	CREATE NONCLUSTERED INDEX #StructureType_i1 ON #StructureType  (str_id,periltype,Comp_Descr);
	select Peril_ID,PerilDisplayName into #PTL from PTL WHERE (Trans_ID IN (67))
	CREATE NONCLUSTERED INDEX #PTL_i1 ON #PTL  (Peril_ID);

	--narrow for exposurekeys of interest
	SELECT ExposureKey
	INTO #tmp1
	FROM ExposureReportInfo i
		INNER JOIN [#NODELIST] n ON n.NODE_KEY = i.ParentKey
			AND n.NODE_TYPE = i.ParentType
	WHERE STATUS='ACTIVE'

	BEGIN
		--extract value column for rollup and create index
		SELECT t.country, e.ExposureKey, e.CoverageID, e.Country_ID, e.CBPerilID, e.PerilType, e.StructureID, e.StructureKey, e.NumStructures, e.NumBuildings, e.Value,
			CASE WHEN c.Cover_Type = 'B' THEN e.Value ELSE 0 END AS 'BValue',
			CASE WHEN c.Cover_Type = 'C' THEN e.Value ELSE 0 END AS 'CValue',
			CASE WHEN c.Cover_Type = 'T' THEN e.Value ELSE 0 END AS 'BIValue'
		INTO #xExposureStructureTypeByCountry
		FROM ExposureReport e WITH (NOLOCK)
			INNER JOIN #CIL c ON e.CoverageID = c.Cover_ID
			INNER JOIN #Country t ON e.CountryKey = t.CountryKey
		WHERE e.ExposureKey in (select ExposureKey from #tmp1)
		AND e.IsValid=1;

		CREATE NONCLUSTERED INDEX #x1_i1 ON #xExposureStructureTypeByCountry (CBPerilID,StructureID,Country_ID,PerilType);

		--summing values particularly by exposurekey and structurekey (to prevent double counting); also creating index
		SELECT Country, Country_ID, CBPerilID, StructureID, PerilType, ExposureKey, StructureKey, NumStructures, NumBuildings,
		sum(BValue)  as BV,
		sum(CValue)  as CV,
		sum(BIValue) as BI
		INTO #x1
		FROM(SELECT Country, e.Country_ID, e.CBPerilID, e.StructureID, e.PerilType, e.ExposureKey, e.StructureKey, e.NumStructures, e.NumBuildings, BValue, CValue, BIValue
			FROM #xExposureStructureTypeByCountry AS e) as #tmp
		GROUP BY Country,Country_ID,CBPerilID,StructureID,PerilType,ExposureKey,StructureKey,NumStructures,NumBuildings;

		CREATE NONCLUSTERED INDEX #x2_i1 ON #x1  (Country_ID,CBPerilID,StructureID,PerilType,StructureKey);

		--Final rollup
		insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Country,Peril,StructureType,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
			SELECT @NodeKey,@NodeType,51,0
			,Country
			,'Peril'=p.PerilDisplayName
			,'StructureType'=Comp_Descr
			,'NumStructures'=sum(NumStructures)
			,'NumBuildings'=sum(NumBuildings)
			,'BuildingValue'=sum(BV)
			,'ContentsValue'=sum(CV)
			,'TotalPropertyValue'=sum(BV)+sum(CV)
			,'BIValue'=sum(BI)
			,'Total'=sum(BV)+sum(CV)+sum(BI)
			FROM #x1 e WITH (NOLOCK)
				INNER JOIN #PTL AS p ON e.CBPerilID = p.Peril_ID
				INNER JOIN #StructureType AS r ON e.StructureID = r.Str_ID
					AND e.Country_ID = r.Country_ID
					AND e.PerilType = r.PerilType
			GROUP BY Country,p.PerilDisplayName,Comp_Descr;

		if (@@rowcount = 0) begin
			insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Country,Peril,StructureType,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
				values (@NodeKey,@NodeType,51,0,NULL,'No records to display',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--exec absp_ExposureStructureTypeByCountry @nodeType=7, @nodeKey=1
