if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposureImportCurrencyByCountry') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureImportCurrencyByCountry;
end
go

create procedure absp_ExposureImportCurrencyByCountry @nodeType int, @nodeKey int
as
BEGIN TRY

	set nocount on;

	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
	-- get all child nodes
  	execute absp_PopulateChildList @nodeKey , @nodeType;

	if (@nodeType = 2 or @nodeType = 7 or @nodeType = 27)
		insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey,@nodeType);

	delete from #NODELIST where NODE_TYPE not in (2,7,27);

	--create indexing for tables and columns of interest
	select Iso_3 as Country,CountryKey into #Country from Country
	CREATE NONCLUSTERED INDEX #Country_i1 ON #Country  (CountryKey);
	select Peril_ID,PerilDisplayName into #PTL from PTL WHERE (Trans_ID IN (67))
	CREATE NONCLUSTERED INDEX #PTL_i1 ON #PTL  (Peril_ID);

	--narrow for exposurekeys of interest
	SELECT ExposureKey
	INTO #tmp1
	FROM ExposureReportInfo i
		INNER JOIN [#NODELIST] n ON n.NODE_KEY = i.ParentKey
			AND n.NODE_TYPE = i.ParentType
	WHERE STATUS='ACTIVE';

	BEGIN
		--extract value column for rollup and create index
		SELECT coalesce(t.Country, e.CountryCode) as Country, e.CurrencyCode, e.CBPerilID, e.ExposureKey, e.StructureKey, e.NumStructures, e.NumBuildings,
			  CASE WHEN e.IsValid=1 THEN e.NativeValue ELSE 0 END AS 'IsValid',
			  CASE WHEN e.IsValid=0 THEN e.NativeValue ELSE 0 END AS 'NotValid'
		INTO #xExposureImportCurrencyByCountry
		FROM ExposureReport e WITH (NOLOCK)
			LEFT OUTER JOIN #Country t ON e.CountryKey = t.CountryKey
		WHERE e.ExposureKey in (select ExposureKey from #tmp1);

		CREATE NONCLUSTERED INDEX #x1_i1 ON #xExposureImportCurrencyByCountry (CBPerilID);

		SELECT
		 CBPerilID
		,Country
		,CurrencyCode
		,ExposureKey
		,StructureKey
		,NumStructures
		,NumBuildings
		,sum(IsValid) as 'IsValue'
		,sum(NotValid) as 'NotValue'
		INTO #x1
		FROM #xExposureImportCurrencyByCountry WITH (NOLOCK)
		GROUP BY CBPerilID
		,Country
		,CurrencyCode
		,ExposureKey
		,StructureKey
		,NumStructures
		,NumBuildings;

		CREATE NONCLUSTERED INDEX #x2_i1 ON #x1 (CBPerilID);

		--final rollup
		insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Peril,Country,CurrencyCode,NumStructures,NumBuildings,Validated,NotValidated,Total)
			SELECT @NodeKey,@NodeType,53,0
			,'Peril'=p.PerilDisplayName
			,Country
			,CurrencyCode
			,'NumStructures'=sum(NumStructures)
			,'NumBuildings'=sum(NumBuildings)
			,'Validated'=sum(IsValue)
			,'NotValidated'=sum(NotValue)
			,'Total'=sum(IsValue)+sum(NotValue)
			FROM #x1 e WITH (NOLOCK)
			INNER JOIN #PTL p ON e.CBPerilID = p.Peril_ID
			group by
			 p.PerilDisplayName
			,Country
			,CurrencyCode;

		if (@@rowcount = 0) begin
			insert ExposureSummaryReport (NodeKey,NodeType,EngineCallID,IsRegion,Peril,Country,CurrencyCode,NumStructures,NumBuildings,Validated,NotValidated,Total)
				values (@NodeKey,@NodeType,53,0,'No records to display',NULL,NULL,NULL,NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--absp_ExposureImportCurrencyByCountry @nodeType=7, @nodeKey=1
