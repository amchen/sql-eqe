if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeCountrySummaryHtmlPages') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeCountrySummaryHtmlPages
end
go

create procedure absp_MakeCountrySummaryHtmlPages
    @directory       varchar(255) = 'c:\\tmp\\TestHTML',
    @create_COUNTRY_SUM int = 1

as
begin try

	set nocount on
	print 'Start absp_MakeCountrySummaryHtmlPages'

	declare @fileName  varchar(255);
	declare @title varchar(100);
	declare @html varchar(max);
	declare @crlf varchar(2);
	declare @htmlHeader varchar(255);
	declare @htmlHeader2 varchar(255);
	declare @htmlBody varchar(255);
	declare @htmlEnd varchar(255);
	declare @htmlH2 varchar(10);
	declare @htmlH2End varchar(10);
	declare @htmlH3 varchar(10);
	declare @htmlH3End varchar(10);
	declare @htmlTable varchar(100);
	declare @htmlTableEnd varchar(20);
	declare @htmlTR varchar(10);
	declare @htmlTREnd varchar(10);
	declare @href varchar(1000);
	declare @cid varchar(3);
	declare @country varchar(50)
	declare @cresta_zone  varchar(1000)
	declare @zone_code  varchar(1000)
	declare @multi_year  varchar(1000)
	declare @cities  varchar(1000)
	declare @adminLevel2  varchar(1000)
	declare @post2  varchar(1000)
	declare @post3  varchar(1000)
	declare @post4  varchar(1000)
	declare @post5  varchar(1000)
	declare @post6  varchar(1000)
	declare @municipal_code  varchar(1000)
	declare @district  varchar(1000)
	declare @commune  varchar(1000)
	declare @latLong_OK  varchar(1000)
	declare @str  varchar(8000)
	declare @str2  varchar(8000)

	--running in stand alone mode (Default)
	if @create_COUNTRY_SUM > 0
	begin
		if OBJECT_ID('tempdb..#COUNTRY_SUM','u') is not null drop table #COUNTRY_SUM ;
		create table #COUNTRY_SUM (
			COUNTRYKEY  int,
			COUNTRY_ID  varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS,
			COUNTRY  varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
			CRESTA_ZONE  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			ZONE_CODE  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			COMMUNE  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			MULTI_YEAR  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			CITIES  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			ADMIN_LEVEL_2 varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			POST2  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			POST3  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			POST4  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			POST5  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			POST6  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			MUNICIPAL_CODE varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			DISTRICT varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			LATLONG_OK  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS,
			WCCIMPORT  varchar(10) default '&nbsp' COLLATE SQL_Latin1_General_CP1_CI_AS
		);

	end;

	-- Fill temporary Zone table from RRGNLIST
	if OBJECT_ID('tempdb..#ZTABLE','u') is not null drop table #ZTABLE ;
	create table #ZTABLE (COUNTRY_ID  varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS, ZONE_TYPE  varchar (30) COLLATE SQL_Latin1_General_CP1_CI_AS);

	declare curs2 cursor for
		select distinct COUNTRY_ID from RRGNLIST where Country_ID not in ('JPN','NEO');
	open curs2;
	fetch curs2 into @cid;
	while @@fetch_status=0
	begin
		if exists(select 1 from RRGNLIST where COUNTRY_ID = @cid and name like '%CRESTA Zone%')
			insert into #ZTABLE values (@cid, 'CRESTA Zone');

		if exists(select 1 from RRGNLIST where COUNTRY_ID = @cid and name like '%Zone Code%')
			insert into #ZTABLE values (@cid, 'Zone Code');

		if exists(select 1 from RRGNLIST where COUNTRY_ID = @cid and name like '%ICA Zone%')
			insert into #ZTABLE values (@cid, 'Zone Code');

		if not exists(select 1 from RRGNLIST where COUNTRY_ID = @cid and name like '%Zone%')
			insert into #ZTABLE values (@cid, 'Zone Code');		-- Per rhk, make the Other (COUNTRY_ID REU) be a Zone Code.

		fetch curs2 into @cid;
	end
	close curs2;
	deallocate curs2;

	-- Fill the temporary table from COUNTRY
	insert into #COUNTRY_SUM (COUNTRYKEY, COUNTRY_ID, COUNTRY, LATLONG_OK, WCCIMPORT)
		select country.countrykey, country.country_id ,
		dbo.trim(country.country),
		case LATLONG_OK when 'Y' then 'X'
		else case country.country_id when 'JPN' then 'X' else '&nbsp' end end,
		country.WCCIMPORT
	from COUNTRY
	where COUNTRYKEY  > 4  and IsLicensed = 'Y' and Country_ID not in ('JPN')
	order by Country;

	-- Update the temporary table with "X" or nothing for the columns

	-- first the DATAVINT fields Zone or CRESTA

	update #COUNTRY_SUM
		set CRESTA_ZONE = 'X', ZONE_CODE = '&nbsp'
		from DATAVINT
		where DATAVINT.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
		and dbo.trim(ZONE_TYPE) = 'CRESTA Zone';


	update #COUNTRY_SUM
		set CRESTA_ZONE = '&nbsp', ZONE_CODE = 'X'
		from DATAVINT
		where DATAVINT.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
		and dbo.trim(ZONE_TYPE) = 'Zone Code' and DATAVINT.Country_ID <> 'NEO';

	 --Countries not in DATAVINT are in #ZTABLE
	update #COUNTRY_SUM
		set CRESTA_ZONE = 'X', ZONE_CODE = '&nbsp'
		from  #ZTABLE
		where #COUNTRY_SUM.COUNTRY_ID = #ZTABLE.COUNTRY_ID
		  and CRESTA_ZONE = '&nbsp' and ZONE_CODE = '&nbsp'
		  and #ZTABLE.ZONE_TYPE = 'CRESTA Zone';


	update #COUNTRY_SUM
		set CRESTA_ZONE = '&nbsp', ZONE_CODE = 'X'
		from #ZTABLE
		where #COUNTRY_SUM.COUNTRY_ID = #ZTABLE.COUNTRY_ID
		  and CRESTA_ZONE = '&nbsp' and ZONE_CODE = '&nbsp'
		  and #ZTABLE.ZONE_TYPE = 'Zone Code';


	-- second, LOCAPPND for multi-year
	 update #COUNTRY_SUM set MULTI_YEAR = 'X'
	 from #COUNTRY_SUM inner join LOCAPPND
	 on LOCAPPND.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY;

	-- GeoData for cities and post codes by length
	 update #COUNTRY_SUM set CITIES = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	 and MAPI_STAT = 7;


	update #COUNTRY_SUM set POST2 = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	 and #COUNTRY_SUM.COUNTRY_ID not in ('GBR','NEO')
	 and GEO_STAT in (202, 402);

	 --  take care case of post codes with mapi_stat =8
	update #COUNTRY_SUM set POST3 = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	 and #COUNTRY_SUM.COUNTRY_ID <> 'GBR' and GEO_STAT = 203;

	update #COUNTRY_SUM set POST4 = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	 and #COUNTRY_SUM.COUNTRY_ID <> 'GBR' and GEO_STAT = 204;

	-- skip IRL in-house created 5-digit PC
	update #COUNTRY_SUM set POST5 = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	  and GEODATA.COUNTRY_ID  not in ('GBR', 'IRL') and GEO_STAT = 205;

	update #COUNTRY_SUM set POST6 = 'X'
	 from #COUNTRY_SUM inner join GEODATA
	 on GEODATA.COUNTRYKEY = #COUNTRY_SUM.COUNTRYKEY
	 and #COUNTRY_SUM.COUNTRY_ID <> 'GBR' and GEO_STAT = 206;

	-- WCCCODES for commune codes by loc_type  not in GEODATA
	update #COUNTRY_SUM set COMMUNE = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	 and WCCCODES.LOC_TYPE = 'Commune Code'
	 where WCCIMPORT <> 'D';

--	-- special treatment, since JPN (01) is not in DATAVINT, we need to set its locator type here in WCCCODES
	--update #COUNTRY_SUM set CRESTA_ZONE = 'X'
	-- from #COUNTRY_SUM inner join WCCCODES
	 --on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	-- and WCCCODES.COUNTRY_ID ='02' and WCCCODES.LOC_TYPE = 'CRESTA Zone'
	-- and #COUNTRY_SUM.COUNTRY_ID = '02';

	-- WCCCODES for cities and post codes by length not in GEODATA
	update #COUNTRY_SUM set CITIES = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and MAPI_STAT = 7;

	update #COUNTRY_SUM set ADMIN_LEVEL_2='X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and MAPI_STAT = 8
	and charindex('*',locator)>0 and len(substring(locator,charindex('*',locator),len(locator)-charindex('*',locator)+1))>2;

	--Fixed SDG__00025498--
	--Generate a single page '4-Digit Postal codes' for GBR--
	update #COUNTRY_SUM set POST4 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and WCCCODES.COUNTRY_ID = 'GBR' and MAPI_STAT = 6;

	--For countries other than GBR--
	update #COUNTRY_SUM set POST2 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and #COUNTRY_SUM.COUNTRY_ID<>'GBR'
	 and mapi_stat = 6 and len(locator) - 4 = 2
	 and WCCIMPORT <> 'D';

	update #COUNTRY_SUM set POST3 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and LOC_TYPE <> 'Commune Code' and mapi_stat = 6 and right(dbo.trim(locator),2) = 'PC' and len(locator) - 6 = 3
	 and WCCIMPORT <> 'D';

	 update #COUNTRY_SUM set POST4 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and LOC_TYPE <> 'Commune Code' and mapi_stat = 6 and len(locator) - 4 = 4
	 and WCCIMPORT <> 'D';

	update #COUNTRY_SUM set POST5 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	and LOC_TYPE <> 'Commune Code' and mapi_stat = 6 and right(dbo.trim(locator),2) <> 'PC' and len(locator) - 4 = 5
	 and WCCIMPORT <> 'D';

	 update #COUNTRY_SUM set POST6 = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	 and LOC_TYPE <> 'Commune Code' and mapi_stat = 6 and len(locator) - 4 = 6
	 and WCCIMPORT <> 'D';

	 update #COUNTRY_SUM set MUNICIPAL_CODE = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	 and LOC_TYPE = 'Municipality Code' and mapi_stat = 7
	 and WCCIMPORT <> 'D';

	update #COUNTRY_SUM set DISTRICT = 'X'
	 from #COUNTRY_SUM inner join WCCCODES
	 on WCCCODES.COUNTRY_ID = #COUNTRY_SUM.COUNTRY_ID
	 and MAPI_STAT = 11
	 and WCCIMPORT <> 'D';

	set @fileName = @directory + '\\CountrySummary.html';

	-- the page header
	set @crlf  = char(10) + char(13);

	--create temp table
	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML;
	create table ##TMP_HTML (line_no int identity not null,line varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS);

	set @title = 'Summary of Geocoding Levels  by Country';
	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + @title + '</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';
	set @htmlH2   = '<H2>';
	set @htmlH2End  = '</H2>';
	set @htmlH3   = '<H3>';
	set @htmlH3End  = '</H3>';
	set @htmlTR = '<TR>';
	set @htmlTREnd = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=950>';
	set @htmlTableEnd = '</TABLE>';

	set @html = @htmlHeader + @htmlBody + @htmlH2 + @title + @htmlH2End;
	set @html = @html + @htmlTable  + @crlf ;
	insert into ##TMP_HTML values(@html)

	set @html = '<TD width=15%><p align=center style=''text-align:center''><b>Country</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>RQE<BR>Supported<BR>CRESTA&nbsp;Zones</b></p></TD>' + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>RQE<BR>Supported<BR>Zone&nbsp;Codes</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Deprecated<BR>CRESTA&nbsp;Zones<BR>Requiring<BR>Cresta&nbsp;Vintage<BR>Year&nbsp;Definition</b></p></TD></b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Cities</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Admin<BR>Level&nbsp;2</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>2-Digit Post&nbsp;Code</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>3-Digit Post&nbsp;Code</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>4-Digit Post&nbsp;Code</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>5-Digit Post&nbsp;Code</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>6-Digit Post&nbsp;Code</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Municipality Codes</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Districts</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>Other</b></p></TD>'  + @crlf;
	set @html = @html + '<TD width=10%><p align=center style=''text-align:center''><b>User Supplied Latitude/ Longitude</b></p></TD>'  + @crlf;

	set @html = @html + @htmlTREnd  + @crlf;
	insert into ##TMP_HTML values(@html);

	declare curs1 cursor for
		select dbo.trim(COUNTRY),dbo.trim(COUNTRY_ID),CRESTA_ZONE,ZONE_CODE,MULTI_YEAR,CITIES,ADMIN_LEVEL_2,POST2,POST3,POST4,POST5,POST6,MUNICIPAL_CODE ,DISTRICT,COMMUNE,LATLONG_OK
			from #COUNTRY_SUM;
		open curs1;
		fetch curs1 into @country,@cid,@cresta_zone,@zone_code,@multi_year,@cities,@adminLevel2,@post2,@post3,@post4,@post5,@post6,@municipal_code,@district,@commune,@latLong_OK;
		while @@fetch_status=0
		begin

			if @cid='02'
				set @href= '<a href=JPN.html#support-locators>X</a>';
			else
				set @href='<a href=' + dbo.trim(@cid) + '.html#support-locators>X</a>';

			if @cresta_zone = 'X' set @cresta_zone=@href;
			if @zone_code = 'X'  set @zone_code=@href;
			if @multi_year = 'X'  set @multi_year=@href;
			if @cities = 'X' set @cities=@href;
			if @adminLevel2 = 'X' set @adminLevel2=@href;
			if @post2 = 'X' set @post2=@href;
			if @post3 = 'X' set @post3=@href;
			if @post4 = 'X' set @post4=@href;
			if @post5 = 'X' set @post5=@href;
			if @post6 = 'X' set @post6=@href;
			if @municipal_code = 'X' set @municipal_code=@href;
			if @district = 'X' set @district=@href;
			if @commune = 'X' set @commune=@href;

			set @html = @htmlTR  + @crlf;

			set @html = @html +  '<TD width=10%><P align=center style=''text-align:center''>' + @country		+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @cresta_zone	+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @zone_code		+ '</P></TD>' + @crlf;


			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @multi_year		+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @cities			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @adminLevel2			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @post2			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @post3			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @post4			+ '</P></TD>' + @crlf;

			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @post5			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @post6			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @municipal_code	+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @district     	+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @commune			+ '</P></TD>' + @crlf;
			set @html = @html +  '<TD width=5%><P align=center style=''text-align:center''>' + @latLong_OK		+ '</P></TD>' + @crlf;

			set @html = @html + @htmlTREnd  + @crlf;
			insert into ##TMP_HTML values(@html)

			fetch curs1 into @country,@cid,@cresta_zone,@zone_code,@multi_year,@cities,@adminLevel2,@post2,@post3,@post4,@post5,@post6,@municipal_code,@district,@commune,@latLong_OK;
		end
		close curs1
		deallocate curs1
		set @html =  @htmlTableEnd+@htmlEnd;
		insert into ##TMP_HTML values(@html);

 	--Write to file
	exec absp_Util_UnloadData 'Q','select line from ##TMP_HTML order by line_no',@fileName;

	select * from #COUNTRY_SUM;
	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML;
end try

begin catch
	exec absp_Util_DeleteFile @fileName;
	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML;
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
