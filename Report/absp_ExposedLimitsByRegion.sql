if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposedLimitsByRegion') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposedLimitsByRegion;
end
go

-- [Country], [Region], [ModelRegion], [Peril], [TotalValue], [GrossLimit], [NetLimit]

create procedure absp_ExposedLimitsByRegion
	@nodeType int,
	@nodeKey int,
	@JobKey integer = 0

as
BEGIN TRY

	set nocount on;
	declare @IDBname varchar(128);
	declare @sqlExec varchar(max);

	select top (1) @IDBname = rtrim(TempIDBName) from commondb..BatchJob where BatchJobKey = @JobKey;
	set @IDBname = ISNULL(@IDBname, '');
	if (@IDBname = '') set @IDBname = DB_NAME() + '_IR';

	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
	-- get all child nodes
  	execute absp_PopulateChildList @nodeKey, @nodeType;

	if (@nodeType = 2 or @nodeType = 7 or @nodeType = 27)
		insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey,@nodeType);

	delete from #NODELIST where NODE_TYPE not in (2,7,27);

	create table #xLimitsByRegion (
		Country varchar(3),
		Name varchar(100),
		ModelRegionID smallint,
		PerilID smallint,
		Value float(53),
		Limit float(53),
		NetLimit float(53),
		FacLimit float(53)
	);

	set @sqlExec = 'INSERT into #xLimitsByRegion
		SELECT
			c.Iso_3 as Country,
			r.Name,
			e.ModelRegionID,
			e.PerilID,
			e.Value,
			e.Limit,
			e.NetLimit,
			e.FacLimit
		FROM [@IDBname].dbo.ExposedLimitsByRegion AS e WITH (NOLOCK)
			INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
			INNER JOIN #NODELIST n ON n.NODE_KEY=x.ParentKey AND n.NODE_TYPE=x.ParentType
			INNER JOIN RRgnList AS r ON e.RegionKey = r.RRgn_Key
			INNER JOIN Country AS c ON r.Country_ID = c.Country_ID
		where e.PolicyKey=0 and e.ModelRegionID=0';

	set @sqlExec = replace(@sqlExec, '@IDBname', @IDBname);

	BEGIN

		execute(@sqlExec);

		CREATE NONCLUSTERED INDEX xLimitsByRegion_i1 ON #xLimitsByRegion  (ModelRegionID,PerilID);

		insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Country,Region,Peril,TotalValue,GrossLimit,NetLimit,FacLimit)
			SELECT @NodeKey,@NodeType,55,
				e.Country,
				'Region'=e.Name,
				'Peril'=p.PerilDisplayName,
				'TotalValue'=sum(e.Value),
				'GrossLimit'=sum(e.Limit),
				'NetLimit'=sum(e.NetLimit),
				'FacLimit'=sum(e.FacLimit)
			FROM #xLimitsByRegion AS e WITH (NOLOCK)
				INNER JOIN PTL AS p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
			GROUP BY
				e.Country,
				e.Name,
				p.PerilDisplayName;

		-- 0004140: On the Exposure reports tab, the top two reports - Exposed Limits by LOB and by Policy do not have data
		if (@@rowcount = 0) begin
			insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Country,Region,Peril,TotalValue,GrossLimit,NetLimit,FacLimit)
				values (@NodeKey,@NodeType,55,'','','No records to display',NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--execute absp_ExposedLimitsByRegion @nodeType=7, @nodeKey=1
