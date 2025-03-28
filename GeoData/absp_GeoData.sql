IF exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_GeoData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GeoData;
end
go

create procedure absp_GeoData @country char(3), @mapiStatType int,  @codeValue varchar(256) = ''
as
begin
	declare @viewName		varchar(50);
	declare @orderByClause  varchar(128);
	declare @sql			nvarchar(256);
	declare @inWCCCODES		int;

	-- determine if the Country exists in GEO_DATA or just WCCCODES
	select @inWCCCODES = 0;
	if (exists(select 1 from WCCCODES where COUNTRY_ID = @country) and not exists(select 1 from GEODATA where COUNTRY_ID = @country))
	begin
		select @inWCCCODES = 1;
	end


	-- Locator type Special mapiStatType 100
	if @mapiStatType = 100
	begin
		-- determine if the locator exists in GEO_DATA or just WCCCODES
		-- 0010539: Not able to import Italy sub-cresta using Locator (we have ITA records in GeoData and WccCodes)
		if (exists(select 1 from GEODATA where COUNTRY_ID = @country and @country <> 'ITA'))
		begin
			select @viewName = 'absvw_Geodata';
		end
		else
		begin
			select @viewName =
				case
					when	@country = 'JPN' then 'absvw_GeodataJpnLocator'
					else	'absvw_GeodataFromWccCodesLocator'
				end
		end

		set @orderByClause = 'MAPI_STAT, LOCATOR';
	end

	-- Locator for USA, State = 'PR': LocatorPri = type Special mapiStatType 99
	if @mapiStatType = 99
	begin
		select @viewName = 'absvw_GeodataUsaPrLocator'
		set @orderByClause = 'MAPI_STAT, LOCATOR'
	end


	-- CellId type Special mapiStatType 101
	if @mapiStatType = 101
	begin
		select @viewName = 'absvw_GeodataFromWccCodesCellId'

		set @orderByClause = 'MAPI_STAT, LOCATOR'
	end

	-- PostCode specials for Canada
	-- PostcodeFSA = 63,           // 3-char FSA
	-- PostcodeFSAZero = 60,       // from FSAZERO for Canada
	if @mapiStatType = 63
	begin
		select @viewName = 'absvw_GeodataCanPC_FSA'
	end
	if @mapiStatType = 60
	begin
		select @viewName = 'absvw_GeodataCanPC_FSAZERO'
	end

		--PostCode (Gulf of Mexico)
	if @mapiStatType = -6
	begin
		select @viewName =
			case
				when	@country = 'USA' then 'absvw_GeodataUsaPC_GOM'
				else	'absvw_Geodata'
			end
		set @orderByClause = 'CODE_VALUE, IS_ALIAS' -- ZIP_CODE
	end

	--PostCode
	else if @mapiStatType = 6
	begin
		select @viewName =
			case
				when	@country = 'USA' then 'absvw_GeodataUsaPC'
				when	@country = 'CAN' then 'absvw_GeodataCanPC'
				when	@country = 'JPN' then 'absvw_GeodataJpnPC'
				when	@inWCCCODES = 1  then 'absvw_GeodataFromWccCodesPC'
				else	'absvw_Geodata'
			end
		set @orderByClause = 'CODE_VALUE, IS_ALIAS' -- ZIP_CODE
	end
	--City
	else if @mapiStatType = 7
	begin
		select @viewName =
			case
				when	@country = 'USA' then 'absvw_GeodataUsaCity'
				when	@country = 'CAN' then 'absvw_GeodataCanCity'
				when	@country = 'JPN' then 'absvw_GeodataJpnCity'
				when	@inWCCCODES = 1  then 'absvw_GeodataFromWccCodesCity'
				else	'absvw_Geodata'
			end

		if @viewName <> 'absvw_Geodata'
			set @orderByClause = 'THEM_ZIP, IS_ALIAS' -- ZIP_CODE

	end
	--County\Cresta
	else if @mapiStatType = 8
	begin
			-- determine if the Cresta exists in GEO_DATA or just WCCCODES
		if (exists(select 1 from GEODATA where COUNTRY_ID = @country) or @country = 'USA' or @country = 'CAN' or @country = 'JPN')
		begin
			select @viewName =
			case
				when	@country = 'USA' then 'absvw_GeodataUsaCnty'
				when	@country = 'CAN' then 'absvw_GeodataCanCnty'
				when	@country = 'JPN' then 'absvw_GeodataJpnCnty'
				else	'absvw_Geodata'
			end			end
		else
		begin

			select @viewName = 'absvw_GeodataFromWccCodesCresta'

		end


		if @viewName <> 'absvw_Geodata'
			set @orderByClause = 'THEM_ZIP, IS_ALIAS' -- ZIP_CODE
	end

		--SubCresta
	if @mapiStatType = 10
	begin
		select @viewName = 'absvw_GeodataFromWccCodesSubCresta'
	end


	--Country, not available for USA and CAN
	else if @mapiStatType = -8 or @mapiStatType = 17
	begin
		--check if this country is in GeoData
		if exists (select 1 from Geodata where Country_Id = @country and MAPI_STAT = -8)
		begin
			set @viewName = 'absvw_GeodataCountry'
		end
		else
		begin
			--fall back to WccCodes
			-- JPN has a special country locator that has more detail
			select @viewName =
			CASE when @country = 'JPN' then 'absvw_GeodataJpnLocator'
			else	'absvw_GeodataFromWccCodesCntry'
			end

		end
	end


	-- if viewname contains 'wcccodes' and country is 'JPN' then must filter on '02' instead of 'jpn'.
	-- Similarly, if country is 'USA' then filter on '00' instead of 'USA'.
	if (select CHARINDEX('WccCodes',@viewname, 0)) > 0  and @country = 'JPN'
	begin
		set @country = '02'
	end


	-- non-locator
	if (@mapiStatType <> 100) and (@viewName  = 'absvw_Geodata' OR @viewName  = 'absvw_GeodataCountry')
	begin

		set @sql =	'select * from ' + @viewName  +
					' where country_id = '''  + @country  +
					''' and mapi_stat = ' + LTRIM(RTRIM(str(@mapiStatType)))

		if LEN(@codeValue) > 0
		begin
			set @sql = @sql + ' and CODE_VALUE  = ' + '''' + @codeValue + ''''
		end

	end
	else if len(@viewName) > 0
	begin
		set @sql = 'select * from ' + @viewName	+ ' where country_id = '''  + @country  + ''''

		if @mapiStatType = 101 and @codeValue <> ''
		begin
			set @sql = @sql + ' and CELL_ID  = ' + '''' + @codeValue + ''''
		end
		else
		begin
			if LEN(@codeValue) > 0
			begin
				set @sql = @sql + ' and CODE_VALUE  = ' + '''' + @codeValue + ''''
			end
		end
	end


	if len(@sql) > 0
	begin
		--add the order by clause if set
		if(LEN(@orderByClause) > 0)
		begin
			set @sql = @sql + ' order by ' + @orderByClause
		end

		print 'GeoData Fetch Query:' + @sql
		exec sp_executesql @sql
	end
end