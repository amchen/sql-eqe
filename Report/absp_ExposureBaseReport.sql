if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ExposureBaseReport') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureBaseReport;
end
go

create procedure absp_ExposureBaseReport
	@expoReportKey int,
	@expoKey int,
	@NodeKey int,
	@NodeType int,
	@JobKey integer = 0
as
BEGIN TRY

	declare @minRowNum int;
	declare @curRowNum int;
	declare @maxRowNum int;
	declare @chunkSize int;
	declare @theRowCount int;
	declare @theJobCount int;
	declare @dbName varchar(120);
	declare @IDBname varchar(128);
	declare @wsPeril table (PerilID int);
	declare @eqPeril table (PerilID int);
	declare @fdPeril table (PerilID int);
	declare @sqlTemp varchar(max);
	declare @sqlExec varchar(max);
	declare @wsStr varchar(500);
	declare @eqStr varchar(500);
	declare @fdStr varchar(500);

	-- init
	select @dbName = DB_NAME();
	select @minRowNum = ISNULL(min(StructureRowNum), 0) from Structure where ExposureKey=@expoKey;
	select @maxRowNum = ISNULL(max(StructureRowNum), 0) from Structure where ExposureKey=@expoKey;

	select top (1) @IDBname = rtrim(TempIDBName) from commondb..BatchJob where BatchJobKey = @JobKey;
	set @IDBname = ISNULL(@IDBname, '');
	if (@IDBname = '') set @IDBname = DB_NAME() + '_IR';

	-- adjust chunkSize if other Reports are running
	select @theJobCount=count(*) from commondb..BatchJob where JobTypeID=22 and Status='R' and DBName=@dbName;
	if (@theJobCount > 1)
		set @chunkSize = 200000;	-- 200K
	else
		set @chunkSize = 1000000;	-- 1M

	set @curRowNum = @minRowNum;

/*
	insert @wsPeril (PerilID) select PerilID from CombinedPerilMap where CbPerilID in (13,110);
	insert @eqPeril (PerilID) select PerilID from CombinedPerilMap where CbPerilID=120;
	insert @fdPeril (PerilID) select PerilID from CombinedPerilMap where CbPerilID=5;
*/
	-- setup peril tables
	exec absp_Util_GenInList @wsStr output, 'select PerilID from CombinedPerilMap where CbPerilID in (13,110)';
	exec absp_Util_GenInList @eqStr output, 'select PerilID from CombinedPerilMap where CbPerilID=120';
	exec absp_Util_GenInList @fdStr output, 'select PerilID from CombinedPerilMap where CbPerilID=5';

	set @sqlTemp = 'INSERT ExposureReport SELECT @expoReportKey,@expoKey,@NodeKey,@NodeType,ev.AccountKey,ev.SiteKey,ev.StructureKey,ev.CoverageID,ev.CountryKey,ev.RegionKey,ev.CBPerilID,
					''PerilType''=CASE WHEN CBPerilID @wsStr THEN ''WS''
									   WHEN CBPerilID @eqStr THEN ''EQ''
									   WHEN CBPerilID @fdStr THEN ''FD''
									   ELSE ''0'' END,
					ev.Value,ev.NativeValue,''NumStructures''=1,Structure.NumBuildings,Structure.GeocodeLevelID,ev.CurrencyCode,''LineOfBusinessID''=0,''CoverageQuality''=50,
					''StructureID''=CASE WHEN CBPerilID @wsStr THEN WSStructureTypeID
										 WHEN CBPerilID @eqStr THEN EQStructureTypeID
										 WHEN CBPerilID @fdStr THEN FLStructureTypeID
										 ELSE ''0'' END,
					Country.Country_ID,Structure.CountryCode,ev.IsValid
				FROM Structure WITH (NOLOCK) INNER JOIN [@IDBname].dbo.ExposureValue ev WITH (NOLOCK) ON
					Structure.ExposureKey=ev.ExposureKey AND Structure.AccountKey=ev.AccountKey AND
					Structure.SiteKey=ev.SiteKey AND Structure.StructureKey=ev.StructureKey
					LEFT OUTER JOIN Country ON
					ev.CountryKey=Country.CountryKey
				WHERE (ev.ExposureKey=@expoKey)
				  AND Structure.StructureRowNum between @curRowNum and (@curRowNum + @chunkSize)';

	set @sqlTemp = replace(@sqlTemp,'@expoReportKey',cast(@expoReportKey as varchar));
	set @sqlTemp = replace(@sqlTemp,'@expoKey',cast(@expoKey as varchar));
	set @sqlTemp = replace(@sqlTemp,'@NodeKey',cast(@NodeKey as varchar));
	set @sqlTemp = replace(@sqlTemp,'@NodeType',cast(@NodeType as varchar));
	set @sqlTemp = replace(@sqlTemp,'@wsStr',@wsStr);
	set @sqlTemp = replace(@sqlTemp,'@eqStr',@eqStr);
	set @sqlTemp = replace(@sqlTemp,'@fdStr',@fdStr);
	set @sqlTemp = replace(@sqlTemp,'@IDBname',@IDBname);

	while (1=1)
	begin
		begin tran;
/*
			INSERT ExposureReport
				SELECT @expoReportKey,@expoKey,@NodeKey,@NodeType,
						ExposureValue.AccountKey,ExposureValue.SiteKey,ExposureValue.StructureKey,ExposureValue.CoverageID,
						ExposureValue.CountryKey,ExposureValue.RegionKey,ExposureValue.CBPerilID,
						'PerilType'=CASE WHEN CBPerilID IN (select PerilID from @wsPeril) THEN 'WS'
										 WHEN CBPerilID IN (select PerilID from @eqPeril) THEN 'EQ'
										 WHEN CBPerilID IN (select PerilID from @fdPeril) THEN 'FD'
										 ELSE '0' END,
						ExposureValue.Value,ExposureValue.NativeValue,'NumStructures'=1,Structure.NumBuildings,
						Structure.GeocodeLevelID,ExposureValue.CurrencyCode,LineOfBusiness=0,'CoverageQuality'=50,
						'StructureID'=CASE WHEN CBPerilID IN (select PerilID from @wsPeril) THEN WSStructureTypeID
										   WHEN CBPerilID IN (select PerilID from @eqPeril) THEN EQStructureTypeID
										   WHEN CBPerilID IN (select PerilID from @fdPeril) THEN FLStructureTypeID
										   ELSE '0' END,
						Country.Country_ID,Structure.CountryCode,ExposureValue.IsValid
				FROM Structure WITH (NOLOCK) INNER JOIN ExposureValue WITH (NOLOCK) ON
					Structure.ExposureKey=ExposureValue.ExposureKey AND Structure.AccountKey=ExposureValue.AccountKey AND
					Structure.SiteKey=ExposureValue.SiteKey AND	Structure.StructureKey=ExposureValue.StructureKey
					LEFT OUTER JOIN Country ON
					ExposureValue.CountryKey=Country.CountryKey
				WHERE (ExposureValue.ExposureKey=@expoKey)
				  AND Structure.StructureRowNum between @curRowNum and (@curRowNum + @chunkSize);
*/
			set @sqlExec = replace(@sqlTemp,'@curRowNum',cast(@curRowNum as varchar));
			set @sqlExec = replace(@sqlExec,'@chunkSize',cast(@chunkSize as varchar));
			execute(@sqlExec);
			set @theRowCount = @@rowcount;
		commit tran;

		-- check range
		if ((@curRowNum + @chunkSize + 1) >= @maxRowNum)
			break;
		else
			begin
				if (@theRowCount > 0)
					WAITFOR DELAY '00:00:05';

				-- adjust chunkSize if other Reports are running
				select @theJobCount=count(*) from BatchJob where JobTypeID=22 and Status='R' and DBName=@dbName;
				if (@theJobCount > 1)
					set @chunkSize = 200000;	-- 200K
				else
					set @chunkSize = 1000000;	-- 1M

				-- reposition rowNum
				set @curRowNum = @curRowNum + @chunkSize + 1;
			end
	end;

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
