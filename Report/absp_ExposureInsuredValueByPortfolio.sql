if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposureInsuredValueByPortfolio') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ExposureInsuredValueByPortfolio;
end
go

-- [LongName], [Peril], [NumStructures], [BuildingValue], [ContentsValue], [TotalPropertyValue], [BIValue], [Total]

create procedure absp_ExposureInsuredValueByPortfolio @nodeType int, @nodeKey int
as
BEGIN TRY

	set nocount on;

	declare @retLongName varchar(max);
	declare @nKey int;
	declare @nType int;
	declare @pKey int;
	declare @pType int;

	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
	create table #NODELST2 (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT, LongName varchar(120));

	-- get all child nodes
  	execute absp_PopulateChildList @nodeKey, @nodeType;
	-- clean up non-Exposure nodes
	delete from #NODELIST where NODE_TYPE not in(2,7,27);
	-- set the parent info for Primary only
	update #NODELIST set PARENT_KEY=NODE_KEY, PARENT_TYPE=2 where NODE_TYPE=2;

	-- Fill in parent LongName
	declare curs1 cursor fast_forward for
		select NODE_KEY, NODE_TYPE, PARENT_KEY, PARENT_TYPE from #NODELIST

	open curs1
	fetch next from curs1 into @nKey, @nType, @pKey, @pType
	while @@fetch_status = 0
	begin
		-- Aport only
		if (@nodeType=1)
			exec absp_Util_GetNodeNameByKey @retLongName output, @pKey, @pType;
		else
			exec absp_Util_GetNodeNameByKey @retLongName output, @nKey, @nType;

		insert into #NODELST2 values ( @nKey, @nType, @pKey, @pType, @retLongName);
		fetch next from curs1 into @nKey, @nType, @pKey, @pType
	end
	close curs1
	deallocate curs1

	--create indexing for tables and columns of interest
	select Cover_ID,Cover_Type into #CIL from CIL
	CREATE NONCLUSTERED INDEX #CIL_i1 ON #CIL  (Cover_ID);
	select Peril_ID,PerilDisplayName into #PTL from PTL WHERE (Trans_ID IN (67))
	CREATE NONCLUSTERED INDEX #PTL_i1 ON #PTL  (Peril_ID);

	--narrow for exposurekeys of interest
	SELECT ExposureKey, LongName
	INTO #tmp1
	FROM ExposureReportInfo i
		INNER JOIN [#NODELST2] n ON n.NODE_KEY = i.ParentKey
			AND n.NODE_TYPE = i.ParentType
	WHERE STATUS='ACTIVE';

	BEGIN
		--extract value column for rollup and create index
		SELECT e.ExposureKey, e.CBPerilID, e.StructureKey, e.NumStructures, e.NumBuildings, e.Value,
			CASE WHEN c.Cover_Type = 'B' THEN e.Value ELSE 0 END AS 'BValue',
			CASE WHEN c.Cover_Type = 'C' THEN e.Value ELSE 0 END AS 'CValue',
			CASE WHEN c.Cover_Type = 'T' THEN e.Value ELSE 0 END AS 'BIValue'
		INTO #xExposureInsuredValueByPortfolio
		FROM ExposureReport e WITH (NOLOCK)
			INNER JOIN #CIL c ON e.CoverageID = c.Cover_ID
		WHERE e.ExposureKey in (select ExposureKey from #tmp1)
		AND e.IsValid=1;

		CREATE NONCLUSTERED INDEX #x1_i1 ON #xExposureInsuredValueByPortfolio (ExposureKey,StructureKey,CBPerilID);

		--summing values particularly by exposurekey and structurekey (to prevent double counting); also creating index
		SELECT CBPerilID, ExposureKey, StructureKey, NumStructures, NumBuildings,
			sum(BValue)  as BV,
			sum(CValue)  as CV,
			sum(BIValue) as BI
			INTO #x1
			FROM(SELECT e.CBPerilID, e.ExposureKey, e.StructureKey, e.NumStructures, e.NumBuildings, BValue, CValue, BIValue
				FROM #xExposureInsuredValueByPortfolio AS e) as #tmp
			GROUP BY CBPerilID,ExposureKey,StructureKey,NumStructures,NumBuildings;

		CREATE NONCLUSTERED INDEX #x2_i1 ON #x1 (CBPerilID);

		--Final rollup
		insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,LongName,Peril,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
			SELECT @NodeKey,@NodeType,50,2
			,t.LongName
			,'Peril'=p.PerilDisplayName
			,'NumStructures'=sum(NumStructures)
			,'NumBuildings'=sum(NumBuildings)
			,'BuildingValue'=sum(BV)
			,'ContentsValue'=sum(CV)
			,'TotalPropertyValue'=sum(BV)+sum(CV)
			,'BIValue'=sum(BI)
			,'Total'=sum(BV)+sum(CV)+sum(BI)
			FROM #x1 e WITH (NOLOCK)
				INNER JOIN #PTL p ON e.CBPerilID = p.Peril_ID
				INNER JOIN #tmp1 t ON e.exposurekey=t.ExposureKey
			GROUP BY t.LongName,p.PerilDisplayName;

		if (@@rowcount = 0) begin
			insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,LongName,Peril,NumStructures,NumBuildings,BuildingValue,ContentsValue,TotalPropertyValue,BIValue,Total)
				values (@NodeKey,@NodeType,50,2,'No records to display',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--absp_ExposureInsuredValueByPortfolio @nodeType=7, @nodeKey=1
