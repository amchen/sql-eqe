if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlPages') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlPages;
end
go

create procedure  absp_MakeWccHtmlPages
	@cntry_id        varchar(3)   = ' ' ,
	@directory       varchar(255) = 'c:\\tmp\\TestHTML'
as
begin
	--
	--  cntry_id        is a specific 3-char country code to generate (ie. BEL)
	--                  Default means do it for all countries in the country table
	--  directory       is where you want to place the generated HTML files (ie. "c:\html")
	--
	declare @path varchar(240);
	declare @suffix varchar(5);
	declare @filename varchar(255);
	declare @html varchar(max);
	declare @htmlHeader varchar(255);
	declare @htmlBody varchar(255);
	declare @htmlEnd varchar(255);
	declare @htmlH2 varchar(10);
	declare @htmlH2N varchar(10);
	declare @htmlH3 varchar(10);
	declare @htmlH3N varchar(10);
	declare @htmlTable varchar(100);
	declare @htmlTableN varchar(20);
	declare @htmlTR varchar(10);
	declare @htmlTRN varchar(10);
	declare @crlf varchar(2);
	declare @i int;
	declare @option varchar(80);
	declare @cntry varchar(80);
	declare @cid varchar(3);

	set nocount on;
	print 'Start absp_MakeWccHtmlPages';

	--  DECLARE  temporary table #LOCAPPNDTMP
	create table #LOCAPPNDTMP
	(COUNTRYKEY int, COUNTRY char(255) COLLATE SQL_Latin1_General_CP1_CI_AS,
	COUNTRY_ID char(3) COLLATE SQL_Latin1_General_CP1_CI_AS,
	LOCAPPRULE char(1) COLLATE SQL_Latin1_General_CP1_CI_AS,
	YEARSTRING char(10) COLLATE SQL_Latin1_General_CP1_CI_AS)

	--  DECLARE temporary table #GIFIMGTMP to drive how many gif files need to be displayed for a certain country
	--  e.g. ANT has 3 gif files need to be displayed ANT.gif, ANT_1.gif, ANT_2.gif
	create table #GIFIMGTMP
	(COUNTRY_ID char(3) COLLATE SQL_Latin1_General_CP1_CI_AS,
	GIF_NAME char(6) COLLATE SQL_Latin1_General_CP1_CI_AS,
	MAP_NAME char(80) COLLATE SQL_Latin1_General_CP1_CI_AS,
	OLDMAP char(1) COLLATE SQL_Latin1_General_CP1_CI_AS,
	NEWMAP char(1) COLLATE SQL_Latin1_General_CP1_CI_AS);

	--  declare local #COUNTRYTMP
	create table #COUNTRYTMP
	(COUNTRY_ID char(3) COLLATE SQL_Latin1_General_CP1_CI_AS,
	CNTRY char(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
	WCCIMPORT char(1) COLLATE SQL_Latin1_General_CP1_CI_AS,
	PROC_LOC int,
	ZONENAME char(80) COLLATE SQL_Latin1_General_CP1_CI_AS,
	ZONENM10 char(80) COLLATE SQL_Latin1_General_CP1_CI_AS,
	ZONENMC char(80) COLLATE SQL_Latin1_General_CP1_CI_AS,
	ZONENAME2 char(255) COLLATE SQL_Latin1_General_CP1_CI_AS) ;


	--  fill the temporary table once
	insert into #LOCAPPNDTMP SELECT LOCAPPND.COUNTRYKEY, COUNTRY,COUNTRY_ID,LOCAPPRULE,YEARSTRING FROM COUNTRY, LOCAPPND
	WHERE LOCAPPND.COUNTRYKEY = COUNTRY.COUNTRYKEY ORDER BY LOCAPPND.COUNTRYKEY, LOCAPPRULE, YEARSTRING;

	--  fill #COUNTRYTMP once
	insert into #COUNTRYTMP SELECT COUNTRY_ID,  dbo.trim(COUNTRY), WCCIMPORT, 0, ' ', ' ', ' ',' ' FROM COUNTRY where COUNTRYKEY > 4 and Country_ID <> 'JPN'

	update #COUNTRYTMP set PROC_LOC = 1 WHERE COUNTRY_ID in (SELECT DISTINCT COUNTRY_ID FROM #LOCAPPNDTMP);

	update #COUNTRYTMP  set #COUNTRYTMP.ZONENAME =  dbo.trim(subrgnlist)
		from #COUNTRYTMP
		inner join EXPREGNS on EXPREGNS.COUNTRY_ID = #COUNTRYTMP.COUNTRY_ID
		where  EXPREGNS.data_level = '1'

	-- for Reunion, EXPREGNS.SUBRGNLIST = 'Postal Code' while WCCCODES.LOC_TYPE = 'Zone Code'
	-- per RHK, use the one in WCCCODES
	-- update #COUNTRYTMP, WCCCODES set #COUNTRYTMP.ZONENAME =  trim(loc_type) where  WCCCODES.COUNTRY_ID = #COUNTRYTMP.COUNTRY_ID and #COUNTRYTMP.COUNTRY_ID = 'REU' and trim(loc_type) = 'Zone Code';

	update #COUNTRYTMP set #COUNTRYTMP.ZONENAME2 = #COUNTRYTMP.ZONENAME;

	update #COUNTRYTMP set #COUNTRYTMP.ZONENAME2 =  dbo.trim(zone_type) + ' (based on ' +  dbo.trim(zone_name) + ')'
		from #COUNTRYTMP
		inner join DATAVINT on DATAVINT.country_id = #COUNTRYTMP.COUNTRY_ID;

	update #COUNTRYTMP set #COUNTRYTMP.ZONENM10 = dbo.trim(WCCCODES.loc_type)
		from #COUNTRYTMP
		inner join WCCCODES on wcccodes.country_id = #COUNTRYTMP.country_id
		where wcccodes.mapi_stat = 10 and #COUNTRYTMP.wccimport <> 'D'
		and charindex('Quake',WCCCODES.loc_type) = 0;

	update #COUNTRYTMP set #COUNTRYTMP.ZONENMC = dbo.trim(WCCCODES.loc_type)
		from #COUNTRYTMP
		inner join WCCCODES on wcccodes.country_id = #COUNTRYTMP.country_id
		where wcccodes.loc_type = 'Commune Code'

	--  fill the GIF temporary table once
	insert into #GIFIMGTMP values('ANT','ANT_1', 'Netherlands Antilles (Aruba, Curacao, Bonaire)', 'Y','Y');
	insert into #GIFIMGTMP values('ANT','ANT_2', 'Netherlands Antilles (Saba, Sint Maarten, St. Eustatius)', 'N','N');

	insert into #GIFIMGTMP values('AUS','AUS', 'Australia', 'Y','Y');
	insert into #GIFIMGTMP values('AUS','AUS_1', 'Northeastern Australia', 'N','Y');
	insert into #GIFIMGTMP values('AUS','AUS_2', 'Southern Australia', 'N','Y');
	insert into #GIFIMGTMP values('AUS','AUS_1', 'Northeastern Australia', 'Y','N');
	insert into #GIFIMGTMP values('AUS','AUS_2', 'Southeastern Australia', 'Y','N');
	insert into #GIFIMGTMP values('AUS','AUS_3', 'Western Australia', 'Y','N');
/*
	insert into #GIFIMGTMP values('AUT','AUT','Austria','Y','Y');
	insert into #GIFIMGTMP values('AUT','AUT_1','Western Austria', 'N','N');
	insert into #GIFIMGTMP values('AUT','AUT_2','Central Austria', 'N','N');
	insert into #GIFIMGTMP values('AUT','AUT_3','Eastern Austria', 'N','N');
*/
	insert into #GIFIMGTMP values('BHR','BHR','Bahrain','Y','Y');
	insert into #GIFIMGTMP values('BHR','BHR_1','Northern Bahrain','N','N');
	insert into #GIFIMGTMP values('BHR','BHR_2', 'Southern Bahrain','N','N');

	insert into #GIFIMGTMP values('BRA','BRA','Brazil','Y','Y');
	insert into #GIFIMGTMP values('BRA','BRA_1','Northwestern Brazil','N','N');
	insert into #GIFIMGTMP values('BRA','BRA_2','Northeastern Brazil','N','N');
	insert into #GIFIMGTMP values('BRA','BRA_3','Southern Brazil','N','N');

	insert into #GIFIMGTMP values('CHN','CHN','China','Y','Y');
	insert into #GIFIMGTMP values('CHN','CHN_1','Western China','Y','Y');
	insert into #GIFIMGTMP values('CHN','CHN_2','Eastern China','Y','Y');
	insert into #GIFIMGTMP values('CHN','CHN_3','South Central China','N','Y');
/*
	insert into #GIFIMGTMP values('CZE','CZE','Czech Republic','Y','Y');
	insert into #GIFIMGTMP values('CZE','CZE_1','Northwestern Czech Republic','N','Y');
	insert into #GIFIMGTMP values('CZE','CZE_2','Southeastern Czech Republic','N','Y');

	insert into #GIFIMGTMP values('DEU','DEU','Germany','Y','Y');
	insert into #GIFIMGTMP values('DEU','DEU_1','Northwestern Germany','N','N');
	insert into #GIFIMGTMP values('DEU','DEU_2','Northeastern Germany','N','N');
	insert into #GIFIMGTMP values('DEU','DEU_3','Southwestern Germany','N','N');
	insert into #GIFIMGTMP values('DEU','DEU_4','Southeastern Germany','N','N');

	insert into #GIFIMGTMP values('ESP','ESP_1','Spain (except Canary Islands)','Y','Y');
	insert into #GIFIMGTMP values('ESP','ESP_2','Canary Islands','Y','Y');

	--insert into #GIFIMGTMP values('EST','EST','Estonia');

	insert into #GIFIMGTMP values('FIN','FIN','Finland','Y','Y');
	insert into #GIFIMGTMP values('FIN','FIN_1','Northern Finland','N','N');
	insert into #GIFIMGTMP values('FIN','FIN_2','Southern Finland','N','N');

	insert into #GIFIMGTMP values('FRA','FRA','France','Y','Y');
	insert into #GIFIMGTMP values('FRA','FRA_1','Northwestern France','N','N');
	insert into #GIFIMGTMP values('FRA','FRA_2','Northeastern France','N','N');
	insert into #GIFIMGTMP values('FRA','FRA_3','Paris and Surrounding Area Detailed Map','N','N');
	insert into #GIFIMGTMP values('FRA','FRA_4','Southwestern France','N','N');
	insert into #GIFIMGTMP values('FRA','FRA_5','Southeastern France','N','N');

	insert into #GIFIMGTMP values('GBR','GBR','United Kingdom','Y','Y');
	insert into #GIFIMGTMP values('GBR','GBR_1','Northern United Kingdom','N','N');
	insert into #GIFIMGTMP values('GBR','GBR_2','Central United Kingdom','N','N');
	insert into #GIFIMGTMP values('GBR','GBR_3','Southern United Kingdom','N','N');
*/
	insert into #GIFIMGTMP values('GRC','GRC','Greece','Y','Y');
	insert into #GIFIMGTMP values('GRC','GRC_1','Northern Greece','N','Y');
	insert into #GIFIMGTMP values('GRC','GRC_2','Southern Greece','N','Y');

	insert into #GIFIMGTMP values('IND','IND','India','Y','Y');

	insert into #GIFIMGTMP values('ITA','ITA','Italy','Y','Y');
	insert into #GIFIMGTMP values('ITA','ITA_1','Northern Italy','N','Y');
	insert into #GIFIMGTMP values('ITA','ITA_2','Southern Italy','N','Y');

	insert into #GIFIMGTMP values('JAM','JAM','Jamaica','Y','Y');
/*
	insert into #GIFIMGTMP values('LTU','LTU','Lithuania','Y','Y');
	insert into #GIFIMGTMP values('LTU','LTU_1','Northern Lithuania','N','N');
	insert into #GIFIMGTMP values('LTU','LTU_2','Southern Lithuania','N','N');

	--insert into #GIFIMGTMP values('LVA','LVA','Latvia');
*/
	insert into #GIFIMGTMP values('MEX','MEX_Q','Mexico - Earthquake CRESTA','Y','Y');
	insert into #GIFIMGTMP values('MEX','MEX_Q1','Northern Mexico - Earthquake CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_Q2','Southwestern Mexico - Earthquake CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_Q3','Southeastern Mexico - Earthquake CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_Q4','Mexico City - Earthquake CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_W','Mexico - Wind CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_W1','Northern Mexico - Wind CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_W2','Southwestern Mexico - Wind CRESTA','N','N');
	insert into #GIFIMGTMP values('MEX','MEX_W3','Southeastern Mexico - Wind CRESTA','N','N');
/*
	insert into #GIFIMGTMP values('NLD','NLD','Netherlands','Y','Y');
	insert into #GIFIMGTMP values('NLD','NLD_1','Northern Netherlands','N','N');
	insert into #GIFIMGTMP values('NLD','NLD_2','Southern Netherlands','N','N');

	insert into #GIFIMGTMP values('NOR','NOR','Norway','Y','Y');
	insert into #GIFIMGTMP values('NOR','NOR_1','Norway (Northern Portion)','N','Y');
	insert into #GIFIMGTMP values('NOR','NOR_2','Norway (Southern Portion)','N','Y');
*/
	insert into #GIFIMGTMP values('PER','PER','Peru','Y','Y');
	insert into #GIFIMGTMP values('PER','PER_1','Lima and Detailed Surrounding Areas','N','N');

	insert into #GIFIMGTMP values('PHL','PHL','Philippines','Y','Y');
	insert into #GIFIMGTMP values('PHL','PHL_1','Manilla and Detailed Surrounding Areas','N','N');
/*
	insert into #GIFIMGTMP values('POL','POL','Poland','Y','Y');
	insert into #GIFIMGTMP values('POL','POL_1','Northern Poland','N','N');
	insert into #GIFIMGTMP values('POL','POL_2','Southern Poland','N','N');
*/
	insert into #GIFIMGTMP values('PRI','PRI','Puerto Rico','Y','Y');
/*
	insert into #GIFIMGTMP values('PRT','PRT','Portugal','Y','Y');
	insert into #GIFIMGTMP values('PRT','PRT_1','Portugal','N','Y');
*/
	insert into #GIFIMGTMP values('SGP','SGP','Singapore','Y','Y');
	insert into #GIFIMGTMP values('SGP','SGP_1','Singapore City Center Detailed Map','N','N');
/*
	insert into #GIFIMGTMP values('SWE','SWE','Sweden','Y','Y');
	insert into #GIFIMGTMP values('SWE','SWE_1','Northern Sweden','N','N');
	insert into #GIFIMGTMP values('SWE','SWE_2','Southern Sweden','N','N');
*/
	insert into #GIFIMGTMP values('THA','THA','Thailand','Y','Y');
	insert into #GIFIMGTMP values('THA','THA_1','Northern Thailand','N','N');
	insert into #GIFIMGTMP values('THA','THA_2','Central Thailand','N','N');
	insert into #GIFIMGTMP values('THA','THA_3','Southern Thailand','N','N');

	insert into #GIFIMGTMP values('TUR','TUR','Turkey','Y','Y');

	insert into #GIFIMGTMP values('VEN','VEN','Venezuela','Y','Y');
	insert into #GIFIMGTMP values('VEN','VEN_1','Northern Venezuela Detailed Areas','N','N');

	set @path = @directory + '\\';
	set @suffix = '.html';

	set @crlf     = char(10)+char(13);
	set @htmlH2   = '<H2>';
	set @htmlH2N  = '</H2>';
	set @htmlH3   = '<H3>';
	set @htmlH3N  = '</H3>';

	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=95%>';
	set @htmlTableN = '</TABLE>';

	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>Select Locator Type</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</TABLE></BODY></HTML>';

	------------------------------------------------------------------------------------------
	-- ACHEN  27 June 2003
	-- Generate HTML locator files for other than United States, Canada, Japan, or Puerto Rico
	------------------------------------------------------------------------------------------
	if (@cntry_id = ' ')
	begin
		declare curs2 cursor for
			select COUNTRY_ID, dbo.trim(COUNTRY)
			from COUNTRY
			where COUNTRYKEY > 4 and IsLicensed = 'Y' and Country_Id <> 'JPN'
		open curs2
		fetch curs2 into @cid,@cntry
		while @@fetch_status=0
		begin
			-- Is this country in Europe?
			if (1 = dbo.absp_Util_IsEuropeLocation(@cid))
				exec absp_MakeEuropeHtmlPagesByCountry @cid, @directory;
			else
				exec absp_MakeWccHtmlPagesByCountry @cid, @directory;

			fetch curs2 into @cid,@cntry;
		end;
		close curs2
		deallocate curs2
	end
	else
	begin
		---------------------------------------------------------------------------------------
		-- Build Zone Locator for specific country
		---------------------------------------------------------------------------------------
		if @cntry_id='JPN' or @cntry_id = '02'
		begin
			print 'Locators no longer supported for Japan';
			return;
		end
		exec absp_MakeWccHtmlPagesByCountry @cntry_id, @directory;
	end
end
