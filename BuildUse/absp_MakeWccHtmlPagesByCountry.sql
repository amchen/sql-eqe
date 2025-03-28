if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlPagesByCountry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlPagesByCountry;
end
go

create procedure absp_MakeWccHtmlPagesByCountry
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

	print 'Start absp_MakeWccHtmlPagesByCountry';

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

	------------------------------------------------------------------------------------------
	-- ACHEN  27 June 2003
	-- Generate HTML locator files for other than United States, Canada, Japan, or Puerto Rico
	------------------------------------------------------------------------------------------

	set @TOCName = '_TOC.html';

	if @cid = '02'
		set @countryId = 'JPN';
	else
		set @countryId = @cid;

	select @cntry=dbo.trim(CNTRY), @wccimport=dbo.trim(WCCIMPORT), @processLocator=dbo.trim(PROC_LOC), @zoneName=dbo.trim(ZONENAME),
		@subZoneName=dbo.trim(ZONENM10), @zoneNameCom=dbo.trim(ZONENMC),@zoneName2= dbo.trim(ZONENAME2)
		from #COUNTRYTMP where COUNTRY_ID = @cid;

    if @zoneName = 'Zone Code' --or @zoneName='ICA Zone'
		set @displayName='CRESTA Zone';
	else if @zoneName ='Sub-Zone Code'
		set @displayName='CRESTA Sub Zone';
	else
		set @displayName=@zoneName;

	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + dbo.trim(@cntry) + ' - Country Map and Locators</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';

	set @html = @htmlHeader;
	set @html = @html + @htmlBody;
	set @html = @html + @htmlH2;

	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';

	--  adding year to the title of the (new) map if the locators of the country need to be processed
	if @processLocator > 0
	begin
		select @appendYear =dbo.trim(YEARSTRING)  from #LOCAPPNDTMP where COUNTRY_ID=@cid and LOCAPPRULE = 'A';

		select @replaceYear=dbo.trim(YEARSTRING)  from #LOCAPPNDTMP where COUNTRY_ID=@cid and LOCAPPRULE = 'R';

		-- add new maps
		set @imageCount = 0;
		declare curs0 cursor for
			SELECT dbo.trim(GIF_NAME), dbo.trim(MAP_NAME), NEWMAP from #GIFIMGTMP
			WHERE COUNTRY_ID=@cid;
		open curs0
		fetch curs0 into @gifName,@mapName,@newmap;
		while @@fetch_status=0
		begin
			if @imageCount > 0
				set @html = @html + @htmlH2;

			if @newmap = 'Y'
			begin
				if @cntry_id ='AUS' and @zoneName='ICA Zone'
					set @html = @html + @mapName + ' - ' + substring(@appendYear,2, len(@appendYear)) + ' CRESTA Zones';
				else
					set @html = @html + @mapName + ' - ' + substring(@appendYear,2, len(@appendYear)) + ' ' + @displayName + 's';

				set @html = @html + @htmlH2N + @crlf;
				set @html = @html + @htmlIMG ;
				set @html = @html + @countryId + '_' + substring(@appendYear,2, len(@appendYear)) + right(@gifName, len(@gifName) - len(@countryId)) +@htmlIMGN  + @crlf;
				insert into ##TMP_CNTRY_HTML values(@html);

				set @html='';
			end
			set @imageCount = @imageCount + 1;
			fetch curs0 into @gifName,@mapName,@newmap;
		end
		close curs0;
		deallocate curs0;

		-- add old maps
		set @html = @html + @htmlH2;
		set @imageCount = 0;

		declare curs02 cursor for
			SELECT dbo.trim(GIF_NAME), dbo.trim(MAP_NAME), OLDMAP
				from #GIFIMGTMP
				WHERE COUNTRY_ID=@cid;
		open curs02;
		fetch curs02 into @gifName,@mapName,@oldmap;
		while @@fetch_status=0
		begin
			if @imageCount > 0
				set @html = @html + @htmlH2;

			if @oldmap = 'Y'
			begin
				set @html = @html + @mapName + ' - ' + substring(@replaceYear,2,len(@replaceYear)) + ' ' + @displayName + 's';
				set @html = @html + @htmlH2N + @crlf;
				set @html = @html + @htmlIMG ;
				set @html = @html + @countryId + '_' + substring(@replaceYear,2,len(@replaceYear)) + right(@gifName, len(@gifName) - len(@countryId)) +@htmlIMGN  + @crlf;
				insert into ##TMP_CNTRY_HTML values(@html);
				set @html='';
			end
			set @imageCount = @imageCount + 1;
			fetch curs02 into @gifName,@mapName,@oldmap;
		end
		close curs02;
		deallocate curs02;
	end
	else
	begin
		-- A country may have more than one gif files to display, we need to loop through the temporary #GIFIMGTMP table
		-- to add titles and gif files to the html page
		--  e.g. ANT has 3 gif files need to be displayed ANT.gif, ANT_1.gif, ANT_2.gif
		if (select count(COUNTRY_ID) from #GIFIMGTMP where COUNTRY_ID=@cid) > 0
		begin
			set @imageCount = 0;
			declare curs03 cursor for
				SELECT dbo.trim(GIF_NAME), dbo.trim(MAP_NAME) from #GIFIMGTMP
				WHERE COUNTRY_ID=@cid;
			open curs03;
			fetch curs03 into @gifName,@mapName;
			while @@fetch_status=0
			begin
				if @imageCount > 0
					set @html = @html + @htmlH2;

				set @html = @html + @mapName + ' - ' + @displayName + 's';
				set @html = @html + @htmlH2N + @crlf;
				set @html = @html + @htmlIMG ;
				set @html = @html + @gifName + @htmlIMGN  + @crlf;
				set @imageCount = @imageCount +1;
				insert into ##TMP_CNTRY_HTML values(@html);
				set @html='';
				fetch curs03 into @gifName,@mapName;
			end
			close curs03
			deallocate curs03;
		end
		else
		begin
			set @html = @html + @cntry +  ' - ' + @displayName + 's';
			set @html = @html + @htmlH2N + @crlf;
			set @html = @html + @htmlIMG ;
			set @html = @html + @countryId + @htmlIMGN  + @crlf ;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
		end

	end

	-- add table for selecting all Supported Geocoding Levels
	set @html = @html + '<H2 id="support-locators">Supported Geocoding Levels</H2>' + @crlf;
	set @html = @html + @htmlTable  + @crlf;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';

	-- add CRESTA or Zone Code Link (Mapi_stat = 8)

	set @html = @html + @htmlTR  + @crlf;

	if @processLocator > 0
	begin
		if @cntry_id ='AUS' and @zoneName='ICA Zone'
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8.html>CRESTA Zones</a></TD>'  + @crlf;
		else
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8.html>' +@displayName  +'s</a></TD>'  + @crlf;

		set @html = @html + @htmlTRN  + @crlf;
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8_Deprecated.html>Deprecated ' + substring(@replaceYear,2,len(@replaceYear)) + ' ' +@displayName  +'s</a></TD>'  + @crlf;
	end
	else
	begin
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8.html>' + @displayName  +'s</a></TD>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
	    set @html = @html + @htmlTR  + @crlf;
	end

 	set @html = @html + @htmlTRN + @crlf;
	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';

	set @msgText=   'Building CRESTA/Zone Locators for ' +  @cntry;
	print @msgText;

	set @fileName = @path +  dbo.trim(@countryId) + '_8';
	exec absp_MakeWccHtmlPagesForCountry  8, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;

	if @processLocator > 0
		set @fileName = @path +  dbo.trim(@countryId) + '_8_Deprecated';

	exec absp_MakeWccHtmlPagesForCountry  8, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;

	--Create a new Admin Level 2 page for all of the items in WCCCODEs that have Mapi_Stat = 8 and where the locator contains a * and the length of the characters following the * is greater than 1.
	if exists(Select  Locator,  substring(Locator,5,99) from WccCodes where Country_Id=@countryId and Locator Like '%*%' and len(rtrim(Locator)) > 5)
	begin
		set @html = @html + @htmlTRN  + @crlf;
	    set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_8_AdminLevel2.html>Admin Level 2'  +'</a></TD>'  + @crlf;
		set @fileName = @path +  dbo.trim(@countryId) + '_8_AdminLevel2';

		exec absp_MakeWccHtmlPagesForCountry  8, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end

	-- add sub-cresta Zones links (mapi_stat =10)
	if exists (select top 1 country_id from WCCCODES where MAPI_STAT = 10 and country_id = @cid)
	begin
		set @msgText=   'Building CRESTA Sub-Zone Locators for ' +  @cntry;
		print @msgText;

		set @html = @html + @htmlTR  + @crlf;

		-- need two links for LOCAPPND country
		if @cid<>'JAM'
		begin
			if @processLocator > 0
			begin
				set @msgText='';
				if exists (select top 1 country_id from WCCCODES where MAPI_STAT = 10 and country_id = @cid and crestaVintage='')
				begin
					set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_10' + '.html>' + substring(@replaceYear,2,len(@replaceYear)) + ' ' + @subZoneName + 's</a></TD>'  + @crlf;
					set @msgText='SubZone Exists';
				end
				if exists (select top 1 country_id from WCCCODES where MAPI_STAT = 10 and country_id = @cid and crestaVintage<>'')
				begin
					if @msgText='SubZone Exists'
					begin
						set @html = @html + @htmlTRN  + @crlf;
						set @html = @html + @htmlTR  + @crlf;
					end
	  				set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_10_Deprecated.html>Deprecated ' + substring(@replaceYear,2,len(@replaceYear)) + ' ' +@subZoneName  +'s</a></TD>'  + @crlf;
	  			end
			end
			else
				set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_10.html> ' + @subZoneName + 's</a></TD>'  + @crlf;
		end

 		set @html = @html + @htmlTRN  + @crlf;
 		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';

 		set @fileName = @path +  dbo.trim(@countryId) + '_10';
 		set @zoneName = @subZoneName;
		exec absp_MakeWccHtmlPagesForCountry 10, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;

		if @processLocator > 0
			set @fileName = @path +  dbo.trim(@countryId) + '_10_Deprecated';
		exec absp_MakeWccHtmlPagesForCountry  10, @cid, @cntry, @zoneName, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
	end

	-- add commune code link - set fake mapiStat = 88
	if exists (select 1 from #COUNTRY_SUM where COMMUNE = 'X' and COUNTRY_ID = @cid)
	begin
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_88.html> ' + @zoneNameCom + 's</a></TD>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		set @msgText='Building Commune Codes for '+ @cntry;
		print @msgText;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';

		set @fileName = @path +  dbo.trim(@countryId) + '_88';
		exec absp_MakeWccHtmlPagesForCountry  88, @cid, @cntry, @zoneNameCom, @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
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
		exec absp_MakeWccHtmlPagesForCountry 7, @cid, @cntry, 'Cities', @zoneName2, @processLocator, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;
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
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_6.html> Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building Postal Code Locators for ' +  @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_6';
			exec absp_MakeWccHtmlPagesForCountry 6, @cid, @cntry, 'Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end
	end
	else
	begin
		-- 2-digit
		if exists (select 1 from #COUNTRY_SUM where POST2 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_62.html> 2-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText='Building 2-digit Postal Codes for '+ @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_62';
			exec absp_MakeWccHtmlPagesForCountry 62, @cid, @cntry, '2-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end

		-- 3-digit
		if exists (select 1 from #COUNTRY_SUM where POST3 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_63.html>  3-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 3-digit Postal Codes for '+ @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_63';
			exec absp_MakeWccHtmlPagesForCountry 63, @cid, @cntry, '3-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end

		-- 4-digit
		if exists (select 1 from #COUNTRY_SUM where POST4 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_64.html>  4-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html);
			set @html='';
			set @msgText= 'Building 4-digit Postal Codes for '+ @cntry;
			print @msgText;

			set @fileName = @path +  dbo.trim(@countryId) + '_64';
			exec absp_MakeWccHtmlPagesForCountry 64, @cid, @cntry,'4-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end;

		-- 5-digit
		if exists (select 1 from #COUNTRY_SUM where POST5 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_65.html>  5-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html)
			set @html=''
			set @msgText= 'Building 5-digit Postal Code Locators for '+ @cntry
			print @msgText
			set @fileName = @path +  dbo.trim(@countryId) + '_65';
			exec absp_MakeWccHtmlPagesForCountry 65, @cid, @cntry,'5-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
		end;

		-- 6-digit
		if exists (select 1 from #COUNTRY_SUM where POST6 = 'X' and COUNTRY_ID = @cid)
		begin
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_66.html>  6-Digit Postal Codes</a></TD>'  + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			insert into ##TMP_CNTRY_HTML values(@html)
			set @html=''
			set @msgText= 'Building 6-digit Postal Code Locators for '+ @cntry
			print @msgText

			set @fileName = @path +  dbo.trim(@countryId) + '_66';
			exec absp_MakeWccHtmlPagesForCountry 66, @cid, @cntry,'6-Digit Postal Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;

		 end
	end --end Postal codes--

	--Districts--
	if exists (select 1 from #COUNTRY_SUM where DISTRICT = 'X' and COUNTRY_ID = @cid)
	begin
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_11.html>  Districts</a></TD>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';
		set @msgText= 'Building Districts for '+ @cntry;
		print @msgText;

		set @fileName = @path +  dbo.trim(@countryId) + '_11';
		exec absp_MakeWccHtmlPagesForCountry 11, @cid, @cntry,'Districts', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
	end

	--Municipality Code--
	if exists (select 1 from #COUNTRY_SUM where MUNICIPAL_CODE = 'X' and COUNTRY_ID = @cid)
	begin
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html +  '<TD WIDTH="100%"><a href=' + dbo.trim(@countryId) + '_77.html>  Municipality Codes</a></TD>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		insert into ##TMP_CNTRY_HTML values(@html);
		set @html='';
		set @msgText= 'Building Municipality Codes for '+ @cntry;
		print @msgText;

		set @fileName = @path +  dbo.trim(@countryId) + '_77';
		exec absp_MakeWccHtmlPagesForCountry  77, @cid, @cntry,'Municipality Codes', @zoneName2, @processLocator, @wccImport,@appendYear, @replaceYear, @fileName, @TOCName;
	end

	set @html = @html + @htmlTableN;
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';
	set @html = @html + @crlf + @htmlEnd;

	insert into ##TMP_CNTRY_HTML values(@html);
	set @html='';
    set @filename = dbo.trim(@path) + dbo.trim(@countryId) + dbo.trim(@suffix);

	--Write to file
	exec absp_Util_UnloadData 'Q','select line from ##TMP_CNTRY_HTML order by line_no',@fileName;

	if OBJECT_ID('tempdb..##TMP_CNTRY_HTML','u') is not null drop table ##TMP_CNTRY_HTML;
	print '';
	print 'End absp_MakeWccHtmlPagesByCountry';
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
