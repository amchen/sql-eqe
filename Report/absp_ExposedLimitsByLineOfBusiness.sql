if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_ExposedLimitsByLineOfBusiness') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposedLimitsByLineOfBusiness;
end
go

-- [Country], [LineOfBusiness], [ModelRegion], [Peril], [TotalValue], [GrossLimit], [NetLimit]

create procedure absp_ExposedLimitsByLineOfBusiness
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

	create table #xLimitsByLineOfBusiness (
		Name varchar(100),
		AccountNumber varchar(50),
		PolicyNumber varchar(50),
		ModelRegionID smallint,
		PerilID smallint,
		Value float(53),
		GrossLimit float(53),
		NetFacLimit float(53),
		FacLimit float(53)
	);

	set @sqlExec = 'INSERT into #xLimitsByLineOfBusiness
		SELECT
			cast(l.Name as varchar(100)),
			cast(a.AccountNumber as varchar(50)),
			cast(y.PolicyNumber as varchar(50)),
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
			INNER JOIN LineOfBusiness AS l ON y.LineOfBusinessID = l.LineOfBusinessID
		where e.ModelRegionID=0
		union
		SELECT
			''Unspecified'',
			cast(e.AccountKey as varchar(50)),
			''None'',
			e.ExposureKey,
			e.PerilID,
			max(e.Value),
			max(e.GrossLimit),
			max(e.NetFacLimit),
			max(e.FacLimit)
		FROM [@IDBname].dbo.ExposedLimitsByPolicy e WITH (NOLOCK)
			INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
			INNER JOIN #NODELIST n ON n.NODE_KEY=x.ParentKey AND n.NODE_TYPE=x.ParentType
		where e.ModelRegionID=0 group by e.AccountKey, e.ExposureKey, e.PerilID having count(*)=1';

	set @sqlExec = replace(@sqlExec, '@IDBname', @IDBname);

	BEGIN

		execute(@sqlExec);

		CREATE NONCLUSTERED INDEX xLimitsByLineOfBusiness_i1 ON #xLimitsByLineOfBusiness (AccountNumber,PolicyNumber);

		insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Country,LineOfBusiness,Peril,TotalValue,GrossLimit,NetLimit,FacLimit)
			SELECT @NodeKey,@NodeType,56,
				'All Countries',
				'LineOfBusiness'=e.Name,
				'Peril'=p.PerilDisplayName,
				'TotalValue'=sum(e.Value),
				'GrossLimit'=sum(e.GrossLimit),
				'NetLimit'=sum(e.NetFacLimit),
				'FacLimit'=sum(e.FacLimit)
			FROM #xLimitsByLineOfBusiness e WITH (NOLOCK)
				INNER JOIN PTL p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
			GROUP BY
				e.Name,
				p.PerilDisplayName;

		-- 0004140: On the Exposure reports tab, the top two reports - Exposed Limits by LOB and by Policy do not have data
		if (@@rowcount = 0) begin
			insert ExposedLimitsReport (NodeKey,NodeType,EngineCallID,Country,LineOfBusiness,Peril,TotalValue,GrossLimit,NetLimit)
				values (@NodeKey,@NodeType,56,'','','No records to display',NULL,NULL,NULL);
		end
	END

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go
--execute absp_ExposedLimitsByLineOfBusiness  @nodeType=7, @nodeKey=1
