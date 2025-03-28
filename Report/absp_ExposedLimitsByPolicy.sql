if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposedLimitsByPolicy') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposedLimitsByPolicy;
end
go

-- [Account], [Policy], [ModelRegion], [Peril], [TotalValue], [GrossLimit], [NetLimit]

create procedure absp_ExposedLimitsByPolicy
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

	create table #xLimitByPolicy (
		AccountNumber varchar(50),
		PolicyNumber varchar(50),
		ModelRegionID smallint,
		PerilID smallint,
		Value float(53),
		GrossLimit float(53),
		NetFacLimit float(53),
		FacLimit float(53)
	);

	set @sqlExec = 'INSERT into #xLimitByPolicy
		SELECT
			a.AccountNumber,
			y.PolicyNumber,
			e.ModelRegionID,
			e.PerilID,
			e.Value,
			e.GrossLimit,
			e.NetFacLimit,
			e.FacLimit
		FROM [@IDBname].dbo.ExposedLimitsByPolicy e WITH (NOLOCK)
			INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
			INNER JOIN #NODELIST n ON n.NODE_KEY=x.ParentKey AND n.NODE_TYPE=x.ParentType
			INNER JOIN Account a ON e.ExposureKey = a.ExposureKey
				AND e.AccountKey = a.AccountKey
			INNER JOIN Policy y ON e.ExposureKey = y.ExposureKey
				AND e.AccountKey = y.AccountKey
				AND e.PolicyKey = y.PolicyKey
		where e.ModelRegionID=0';

	set @sqlExec = replace(@sqlExec, '@IDBname', @IDBname);

	BEGIN

		execute(@sqlExec);

		CREATE NONCLUSTERED INDEX xLimitByPolicy_i1 ON #xLimitByPolicy  (ModelRegionID,PerilID);

		insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Account,Policy,Peril,TotalValue,GrossLimit,NetLimit,FacLimit)
			SELECT @NodeKey,@NodeType,54,
				'Account'=e.AccountNumber,
				'Policy'=e.PolicyNumber,
				'Peril'=p.PerilDisplayName,
				'TotalValue'=sum(e.Value),
				'GrossLimit'=sum(e.GrossLimit),
				'NetLimit'=sum(e.NetFacLimit),
				'FacLimit'=sum(e.FacLimit)
			FROM #xLimitByPolicy e WITH (NOLOCK)
				INNER JOIN PTL p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
			GROUP BY
				e.AccountNumber,
				e.PolicyNumber,
				p.PerilDisplayName;

		-- 0004140: On the Exposure reports tab, the top two reports - Exposed Limits by LOB and by Policy do not have data
		if (@@rowcount = 0) begin
			insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Account,Policy,Peril,TotalValue,GrossLimit,NetLimit,FacLimit)
				values (@NodeKey,@NodeType,54,'No records to display','','',NULL,NULL,NULL,NULL);
		end
	END

END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--execute absp_ExposedLimitsByPolicy @nodeType=7, @nodeKey=1
