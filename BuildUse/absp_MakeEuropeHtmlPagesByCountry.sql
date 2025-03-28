if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeEuropeHtmlPagesByCountry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeEuropeHtmlPagesByCountry;
end
go

create procedure absp_MakeEuropeHtmlPagesByCountry
    @cntry_id        varchar(3)   = ' ' ,
    @directory       varchar(255) = 'c:\\tmp\\TestHTML'
as
begin try
--
--  cntry_id        is a specific 3-char country code to generate (ie. BEL)
--                  Default means do it for all countries in the country table
--  directory       is where you want to place the generated HTML files (ie. "c:\html")
--
	set nocount on;

	print 'Start absp_MakeEuropeHtmlPagesByCountry';

	declare @cid varchar(3);
	declare @path varchar(240);
	declare @suffix varchar(5);
	declare @filename varchar(255);
	declare @filename2 varchar(255);
	declare @TOCName varchar(255);
	declare @html varchar(max);
	declare @htmlHeader varchar(255);
	declare @htmlHeader2 varchar(255);
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
	declare @htmlIMG varchar(10);
	declare @htmlIMGN varchar(10);
	declare @crlf varchar(2);
	declare @i int;
	declare @displayName varchar(255)
	declare @zoneName varchar(255);
	declare @zoneName2 varchar(255);
	declare @subZoneName varchar(255);
	declare @zoneNameCom varchar(255);
	declare @name varchar(150);
	declare @startIndx int;
	declare @htmlTableLg varchar(100);
	declare @htmlTableLgN varchar(20);
	declare @cntry varchar(50);
	declare @countryId varchar(3);
	declare @processLocator int;
	declare @appendYear varchar(10);
	declare @replaceYear varchar(10);
	declare @imageCount int;
	declare @wccimport varchar(1);
	declare @gifName varchar(6);
	declare @mapName varchar(80);
	declare @oldmap varchar(1);
	declare @newmap varchar(1);
	declare @msgText varchar(2000)
	declare @htmlBR varchar(10);

	set @cid = dbo.trim(@cntry_id);

	if @cid = ' ' or @cid = 'XX'
		return;


	set @path = @directory + '\\';
	set @suffix = '.html';

	--create temp table
	if OBJECT_ID('tempdb..##TMP_CNTRY_HTML','u') is not null drop table ##TMP_CNTRY_HTML
	create table ##TMP_CNTRY_HTML (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS)

	set @crlf     = char(10)+char(13);
	set @htmlH2   = '<H2>';
	set @htmlH2N  = '</H2>';
	set @htmlH3   = '<H3>';
	set @htmlH3N  = '</H3>';
	set @htmlIMG  = '<img src="';
	set @htmlIMGN = '.gif">';
	--
	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=300>';
	set @htmlTableN = '</TABLE>';
	set @htmlTableLg = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=350>';
	set @htmlTableLgN = '</TABLE>';
	set @htmlBR = '<br>';

	set @TOCName = '_TOC.html';
	set @countryId = @cid;

	select @cntry=dbo.trim(CNTRY), @wccimport=dbo.trim(WCCIMPORT), @processLocator=dbo.trim(PROC_LOC), @zoneName=dbo.trim(ZONENAME),
		@subZoneName=dbo.trim(ZONENM10), @zoneNameCom=dbo.trim(ZONENMC),@zoneName2= dbo.trim(ZONENAME2)
		from #COUNTRYTMP where COUNTRY_ID = @cid;

	set @displayName = 'CRESTA Zone Maps in @cntry';
	set @displayName = replace(@displayName, '@cntry', @cntry);

	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + @displayName + '</TITLE>' + @crlf + '</HEAD>' + @crlf;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';

	set @html = @htmlHeader;
	set @html = @html + @htmlBody + @crlf;
	insert into ##TMP_CNTRY_HTML values(@html);

	-- add info and link to www.cresta.org
	set @html = @htmlH2 + @displayName + @htmlH2N;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html = @htmlH3 + 'For the maps corresponding to the LowRes and HighRes CRESTA Zones, go to:' + @htmlH3N;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html = @htmlH3 + '<a href=https://www.cresta.org/index.php/map-viewer>https://www.cresta.org/index.php/map-viewer</a>' + @htmlH3N;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html = @htmlBR + '1. Click on the countries button.';
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html = @htmlBR + '2. Go to the Legend and check either the CRESTA LowRes or HighRes check box.';
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html = @htmlBR + '3. Go to the country of interest by dragging the map and zooming in.' + @htmlBR;
	insert into ##TMP_CNTRY_HTML values(@html);

	-- add table for selecting all Supported Geocoding Levels
	set @html = '<H2 id="support-locators">Supported Geocoding Levels</H2>' + @crlf + @htmlTable;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';

	-- LowRes CRESTA Zones
	if @cid not in ('MCO','NEO')
	begin
		set @html = @htmlTR + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8_LowRes.html>LowRes CRESTA Zones</a></TD>' + @crlf;
		set @html = @html + @htmlTRN + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';

		set @msgText = 'Building LowRes CRESTA Zones for ' + @cntry;
		print @msgText;

		set @fileName = @path +  dbo.trim(@countryId) + '_8_LowRes';
		exec absp_MakeEuropeHtmlPagesForCountry  -8, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end

	-- HighRes CRESTA Zones
	if @cid not in ('IRL','MCO','NEO','ITA')
	begin
		set @html = @htmlTR + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8_HighRes.html>HighRes CRESTA Zones</a></TD>' + @crlf;
		set @html = @html + @htmlTRN + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';

		set @msgText = 'Building HighRes CRESTA Zones for ' + @cntry;
		print @msgText;

		set @fileName = @path +  dbo.trim(@countryId) + '_8_HighRes';
		exec absp_MakeEuropeHtmlPagesForCountry  -9, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end

	-- add city locator link
	if exists (select 1 from #COUNTRY_SUM where CITIES = 'X' and COUNTRY_ID = @cid)
	begin
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_7.html> Cities</a></TD>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';
		set @msgText=  'Building Cities for ' +  @cntry;
		print @msgText;

		set @fileName = @path +  dbo.trim(@countryId) + '_7';
		exec absp_MakeEuropeHtmlPagesForCountry 7, @cid, @cntry, 'Cities', @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end


	 -- add post code locator links

	 -- 2-digit
	 --Fixed SDG__00025498--
	 --Generate a single page '4-Digit Postal codes' for GBR--
	 if @cid = 'GBR'
	 begin
		if exists(select 1 from WCCCODES where COUNTRY_ID = 'GBR' and MAPI_STAT = 6)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_6.html>Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building Postal Code Locators for ' +  @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_6';
			exec absp_MakeEuropeHtmlPagesForCountry 6, @cid, @cntry, 'Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end
	end
	else
	begin
		-- 2-digit
		if exists (select 1 from #COUNTRY_SUM where POST2 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_62.html>2-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText='Building 2-digit Postal Codes for '+ @cntry;
			print @msgText;
			set @fileName = @path +  dbo.trim(@countryId) + '_62';
			exec absp_MakeEuropeHtmlPagesForCountry 62, @cid, @cntry, '2-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end

		-- 3-digit
		if exists (select 1 from #COUNTRY_SUM where POST3 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_63.html>3-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 3-digit Postal Codes for '+ @cntry;
			print @msgText;
			set @fileName = @path +  dbo.trim(@countryId) + '_63';
			exec absp_MakeEuropeHtmlPagesForCountry 63, @cid, @cntry, '3-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end

		-- 4-digit
		if exists (select 1 from #COUNTRY_SUM where POST4 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_64.html>4-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 4-digit Postal Codes for '+ @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_64';
			exec absp_MakeEuropeHtmlPagesForCountry 64, @cid, @cntry,'4-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end;

		-- 5-digit
		if exists (select 1 from #COUNTRY_SUM where POST5 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_65.html>5-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 5-digit Postal Code Locators for '+ @cntry;
			print @msgText;
			set @fileName = @path +  dbo.trim(@countryId) + '_65';
			exec absp_MakeEuropeHtmlPagesForCountry 65, @cid, @cntry,'5-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end;

		-- 6-digit
		if exists (select 1 from #COUNTRY_SUM where POST6 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_66.html>6-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 6-digit Postal Code Locators for '+ @cntry;
			print @msgText;
			set @fileName = @path +  dbo.trim(@countryId) + '_66';
			exec absp_MakeEuropeHtmlPagesForCountry 66, @cid, @cntry,'6-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		 end

	end --end Postal codes--

	-----------------------------
	-- Old CRESTA Zones
	-----------------------------
	if @cid in ('CZE','DNK','ESP','HUN','LUX','NOR','PRT','ROU','SWE','ITA')
	begin
		if (@cid = 'CZE') set @zoneName = '1999 CRESTA Zone';
		if (@cid = 'DNK') set @zoneName = '2007 CRESTA Zone';
		if (@cid = 'ESP') set @zoneName = '1999 CRESTA Zone';
		if (@cid = 'HUN') set @zoneName = '2007 CRESTA Zone';
		if (@cid = 'LUX') set @zoneName = '2006 CRESTA Zone';
		if (@cid = 'NOR') set @zoneName = '2007 CRESTA Zone';
		if (@cid = 'PRT') set @zoneName = '1999 CRESTA Zone';
		if (@cid = 'ROU') set @zoneName = '2007 CRESTA Zone';
		if (@cid = 'SWE') set @zoneName = '2007 CRESTA Zone';
		if (@cid = 'SWE') set @zoneName = '2004 CRESTA Zone';

		set @html = @html + @htmlTR  + @crlf;
		set @html = @html + '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_11.html>' + @zoneName + 's</a></TD>' + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';
		set @fileName = @path +  dbo.trim(@countryId) + '_11';
		exec absp_MakeEuropeHtmlPagesForCountry 11, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end

	set @html = @html + @htmlTableN;
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>Go to Table of Contents</a></H3>';
	set @html = @html + @crlf + @htmlEnd;

	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';
    set @filename = dbo.trim(@path) + dbo.trim(@countryId) + dbo.trim(@suffix);

	--Write to file
	exec absp_Util_UnloadData 'Q','select line from ##TMP_CNTRY_HTML order by line_no',@fileName;

	if OBJECT_ID('tempdb..##TMP_CNTRY_HTML','u') is not null drop table ##TMP_CNTRY_HTML;
	print '';
	print 'End absp_MakeEuropeHtmlPagesByCountry';
	print '======================================================';
	print '';
end try

begin catch
	exec absp_Util_DeleteFile @fileName
	if OBJECT_ID('tempdb..##TMP_CNTRY_HTML','u') is not null drop table ##TMP_CNTRY_HTML
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
