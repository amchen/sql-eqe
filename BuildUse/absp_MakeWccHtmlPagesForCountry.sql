if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlPagesForCountry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlPagesForCountry
end
go

create procedure absp_MakeWccHtmlPagesForCountry
    @mapistat       int = 0,
    @CID       char(3),
    @CNTRY          varchar(50),
    @zoneName       varchar(255),
    @zoneName2      varchar(255),
    @processLocator int,
    @wccImport      varchar(1),
    @appendYear     varchar(10),
    @replaceYear    varchar(10),
    @fileName       varchar(255),
    @TOCName        varchar(255)
as
begin-- try
--
--  CID        	    is a specific 3-char country code to generate (ie. BEL)
--                  Default means do it for all countries in the country table
--  directory       is where you want to place the generated HTML files (ie. "c:\html")
--
	set nocount on;

	print 'Start absp_MakeWccHtmlPagesForCountry';
	print @processLocator;
	print @wccimport;
	print @mapiStat;

	declare @cntry_id varchar(3);
	declare @path varchar(240);
	declare @suffix varchar(5);
	declare @html varchar(max);
	declare @outhtml varchar(max);
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
	declare @crlf varchar(2);
	declare @i int;
	declare @outcount1 int;
	declare @outcount2 int;
	declare @name varchar(150);
	declare @startIndx int;
	declare @htmlTableLg varchar(100);
	declare @htmlTableSingleCol varchar(100);
	declare @htmlTableLgN varchar(20);
	declare @countryId varchar(3);
	declare @countryLevel varchar(40);
	declare @zoneName4 varchar(255);
	declare @loc varchar(45);
	declare @tblExists int;
	declare @locType varchar(30);
	declare @txtToWrite varchar(max);
    declare @msgText varchar(2000);
	declare @zone_Name varchar(255);
	declare @str varchar(8000);
	declare @crestaZone varchar(10);
	declare @crestaVintage varchar(4);
	declare @displayNote int;
	declare @DeprecatedCRESTAZones int;
	declare @adminLevel2 int;

	set @DeprecatedCRESTAZones=0;
	set @adminLevel2 = 0;

	if charindex('Deprecated',@fileName)>0
		set @DeprecatedCRESTAZones=1;
	else if charindex('AdminLevel2',@fileName)>0
		set @adminLevel2=1;

  	if @cid = '02'
		set @cntry_id = 'JPN';
	else
		set @cntry_id = @cid;

	set @txtToWrite ='';

	if @cid = ' ' or len(@cid) = 0 or @cid = 'XX' or @mapistat <= 0
		return;

	set @suffix = '.html';

	--create temp table
	if OBJECT_ID('tempdb..##TMP_CTRY_HTML','u') is not null drop table ##TMP_CTRY_HTML;
	create table ##TMP_CTRY_HTML (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS);

	--
	set @crlf     = char(10)+char(13)
	set @htmlH2   = '<H2>';
	set @htmlH2N  = '</H2>';
	set @htmlH3   = '<H3>';
	set @htmlH3N  = '</H3>';
	--
	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';

	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=60%>';

	set @htmlTableN = '</TABLE>';
	set @htmlTableLg = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=40%>';
	set @htmlTableLgN = '</TABLE>';
	set @htmlTableSingleCol = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=20%>';

	------------------------------------------------------------------------------------------
	-- ACHEN  27 June 2003
	-- Generate HTML locator files for other than United States, Canada, Japan, or Puerto Rico
	------------------------------------------------------------------------------------------

	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + dbo.trim(@cntry) + ' - Country Locators</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';
	--
	---------------------------------------------------------------------------------------
	-- Build Locators
	-- Add Description to the locator
	---------------------------------------------------------------------------------------
	set @i = 0;
	print '======================================================';
	set @msgText='Building Locators for '+ dbo.trim(@cntry);
	print @msgText;

	-------------------------------------------
	--  process Detail countries by MAPI_STAT
	-------------------------------------------
	--
	if @mapistat >= 62  or @mapistat = 6 or  @mapistat =7
	begin
		set @html = @htmlHeader;
		set @html = @html + @htmlBody;
		set @html = @html + @htmlH2;

		if @mapistat=6
			set @html = @html + 'Postal Codes in ' + dbo.trim(@cntry);
		else
			set @html = @html + dbo.trim(@zoneName) + ' in ' + dbo.trim(@cntry);

		set @html = @html + @htmlH2N + @crlf ;
		set @html = @html + @htmlTableLg  + @crlf;

		--add Locator and Description header
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Locator</b></p></td>'  + @crlf;

		if @mapistat=7
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Cities</b></p></td>'  + @crlf;
		else if @mapistat=6
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=62
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>2-Digit Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=63
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>3-Digit Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=64
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>4-Digit Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=65
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>5-Digit Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=66
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>6-Digit Postal Codes</b></p></td>'  + @crlf;
		else if @mapistat=88
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Commune Code</b></p></td>'  + @crlf;

		set @html = @html + @htmlTRN  + @crlf;
		set @outhtml = @html;
		set @html = '';
	end

	-- Postal codes for GBR--
	if @mapistat = 6
	begin
		declare curs6 cursor for
				select dbo.trim(LOCATOR)
				from WCCCODES
				where   COUNTRY_ID = @cid and mapi_stat = 6  order by 1
		open curs6
		fetch curs6 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
				set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ dbo.trim(@loc)  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%>'+ dbo.trim(SUBSTRING(@loc,5,99))  + '</td>' + @crlf;
			set @i = @i + 1;

			set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end

			fetch curs6 into @loc
		end
		close curs6
		deallocate curs6

		set @html = @html + @htmlTRN  + @crlf ;
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	if @mapistat = 62
	begin
		declare curs6 cursor for
			select dbo.trim(LOCATOR)
				from GEODATA
			where
				COUNTRY_ID = @cid and
				((mapi_stat = 8 and  right(dbo.trim(code_value),2) = 'PC' and len(dbo.trim(code_value)) > 3) or
				(mapi_stat = 6 and geo_stat = 202))
			union
				select dbo.trim(LOCATOR)
				from WCCCODES
				where
				COUNTRY_ID = @cid and mapi_stat = 6 and len(locator) - 4 = 	2
				ORDER BY 1 ASC
		open curs6
		fetch curs6 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>'+ right(replace(@loc,'PC',''),2)  + '</td>' + @crlf;
			set @i = @i + 1;

		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end
			fetch curs6 into @loc
		end
		close curs6
		deallocate curs6

		set @html = @html + @htmlTRN  + @crlf ;
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''

	end

	-- 3, 4, 6-digit postCode
	if @mapistat = 63 or @mapistat = 64  or @mapistat = 66
	begin
		declare curs33 cursor for
			select dbo.trim(LOCATOR)  from GEODATA
			where  COUNTRY_ID = @cid and
		  	    (mapi_stat = 6 and  geo_stat = 140 + @mapistat)    -- 203 or 204 or 206
		  	union
		  	select dbo.trim(LOCATOR)
			from WCCCODES
			where COUNTRY_ID = @cid and
			    (mapi_stat = 6 and  right(dbo.trim(locator),2) <> 'PC' and len(locator) - 4 = @mapistat-60)     -- len = 4, 6
			union
			 select dbo.trim(LOCATOR) from WCCCODES
			    	where COUNTRY_ID = @cid and
				(mapi_stat = 6 and  right(dbo.trim(locator),2) = 'PC' and len(locator) - 6 = @mapistat-60)   -- len = 3
	                ORDER BY 1 ASC
		open curs33
		fetch curs33 into @loc
		while @@fetch_status=0
		begin

			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>'+ right(replace(@loc,'PC',''),@mapistat-60)  + '</td>' + @crlf;
			set @i = @i + 1;

		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end
			fetch curs33 into @loc
		end
		close curs33
		deallocate curs33

		set @html = @html + @htmlTRN  + @crlf ;
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	-- 5-digit postCode
	-- treat FRA as special case because its 5-digit postal codes having geo_stat =202
	if @mapistat = 65
	begin
		-- treat FRA as special case because its 5-digit postal codes having geo_stat =202
		declare curs35 cursor for
			select dbo.trim(LOCATOR)  from GEODATA
				where  COUNTRY_ID = @cid and
			 	(mapi_stat = 6 and geo_stat = 205)
			 union
			select dbo.trim(LOCATOR) from WCCCODES
				where  COUNTRY_ID = @cid and
				(mapi_stat = 6 and   right(dbo.trim(locator),2) <> 'PC' and len(locator) - 4 = @mapistat - 60)     -- len = 3, 4, 6
	                ORDER BY 1 ASC
		open curs35
		fetch curs35 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>'+right( replace(@loc,'PC',''),5)  + '</td>' + @crlf;
			set @i = @i + 1;

		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end
			fetch curs35 into @loc
		end ;
		close curs35
		deallocate curs35

		set @html = @html + @htmlTRN  + @crlf ;
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	--Municipal and District codes--
	if @mapistat = 11 or @mapistat = 77
	begin
	    	set @html = @htmlHeader;
		set @html = @html + @htmlBody;
		set @html = @html + @htmlH2;

		set @html = @html + @zoneName + ' in ' + @cntry;

		set @html = @html + @htmlH2N + @crlf ;
		set @html = @html + @htmlTable  + @crlf;

		if @mapistat=11
		begin
			set @locType='District';
			set @zoneName4 = 'District';
		end
		else
		begin
			set @locType='Municipality Code';
			set @zoneName4 = 'Municipality';
		end

		--	add Locator and Description header
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Locator</b></p></td>'  + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>' + @zoneName4 + '</b></p></td>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		set @outhtml = @html;
		set @html = '';

		--Municipal codes and districts--
		set @str= dbo.trim(@fileName) + '.txt'
		exec absp_Util_DeleteFile @str

		declare curs35 cursor for
			select dbo.trim(LOCATOR), dbo.trim(zone_name)
			from WCCCODES
			where  COUNTRY_ID = @cid and LOC_TYPE= @locType
			ORDER BY 1 ASC
		open curs35
		fetch curs35 into @loc,@zone_name
		while @@fetch_status=0
		begin

			if @i = 0
			   set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%>'+ @zone_name  + '</td>' + @crlf;

			set @i = @i + 1;

		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
			 	set @outhtml = @outhtml + @html;
				set @html = '';
			end

			set @txtToWrite =  @LOC +','+ @zone_name

			--Create .txt files for municipal codes and district locators --
			set @str='echo ' + @txtToWrite + '>>"' + @fileName + '.txt'+'"'
			exec xp_cmdshell @str, no_output
			fetch curs35 into @loc,@zone_name
		end ;
		close curs35
		deallocate curs35

		set @html = @html + @htmlTRN  + @crlf ;

		--recover back to main variable the big string
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

    	-- Commune Code
	if @mapistat = 88
	begin
		declare curs88 cursor for
			select dbo.trim(LOCATOR)
			from WCCCODES
			where
			COUNTRY_ID = @cid and
			(mapi_stat = 6 and LOC_TYPE='Commune Code')     -- len = 3, 4, 6
			ORDER BY 1 ASC
		open curs88
		fetch curs88 into @loc
		while @@fetch_status=0
		begin
			-- treat FRA as special case because its 5-digit postal codes having geo_stat =202
			set @html = @html + @htmlTR  + @crlf;
			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%>'+ substring(@loc,5,99)  + '</td>' + @crlf;
		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end
			fetch curs88 into @loc
		end ;
		close curs88
		deallocate curs88

		set @html = @html + @htmlTRN  + @crlf ;
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	--
	-- city post code
	--
	if @mapistat = 7
	begin
		declare curs22 cursor for
			SELECT dbo.trim(LOCATOR)
				FROM GEODATA
				WHERE COUNTRY_ID = @cid and MAPI_STAT = @mapistat  and locator not like '%\_%' escape '\' and locator not like '%?%'
				GROUP BY LOCATOR having COUNT(LOCATOR) = 1  -- remove duplicate locators for now (per RHK)
			union
			SELECT dbo.trim(LOCATOR)                   -- old city locators
				FROM WCCCODES
				WHERE COUNTRY_ID = @cid and MAPI_STAT = @mapistat and  LOC_TYPE='City'  and locator not like '%\_%' escape '\' and locator not like '%?%'

				GROUP BY LOCATOR having COUNT(LOCATOR) = 1
			ORDER BY 1 ASC
		open curs22
		fetch curs22 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc  + '</td>' + @crlf;
			set @html = @html +  '<TD width=20%>'+ substring(@loc,5,45)  + '</td>' + @crlf;
			set @i = @i + 1;
		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end
			fetch curs22 into @loc
		end;
		close curs22
		deallocate curs22

		set @html = @html + @htmlTRN  + @crlf ;

		-- recover back to main variable the big string
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	--
	-- CRESTA/CRESTA Sub-Zone or Zone code
	--

	if @mapistat = 8 or @mapistat = 10
	begin

		set @i = 0;
		print '======================================================';
		set @msgText='Building Zone Locators for '+ @cntry
		print @msgText
		------------------------------------------
		--  process countries in LOCAPPND table
		------------------------------------------
		if @processLocator > 0
		begin

		--	For the special country 'PRI', CID is actually '00' and STATE_2 is actually 'PR'
		--	So the query and the for-loop will be treated differently from the rest.
		--      =================================================================================
			if @cid = 'PRI' and @mapistat = 8
			    exec absp_MakeWccHtmlPagesForPRI @cntry, @zoneName, @appendYear, @replaceYear, @fileName, @TOCName;
			else
				exec absp_MakeWccHtmlPagesForLocAppndCountry @cid, @cntry, @mapistat, @zoneName, @wccImport, @appendYear, @replaceYear, @fileName, @TOCName;

			return;
		end
		else
		begin
			set @html = @htmlHeader;
			set @html = @html + @htmlBody;
			set @html = @html + @htmlH2;

			if @wccImport = 'D'
			    set @zoneName = @zoneName2;

			if @mapistat = 8  and @adminLevel2=1
				set @html = @html + 'Admin Level 2 Codes in ' + @cntry;
			else if @mapistat = 8  and @adminLevel2=0
				set @html = @html + 'CRESTA Zones in ' + @cntry;
			else
				set @html = @html +  'CRESTA Sub Zones in ' + @cntry;

			set @html = @html + @htmlH2N + @crlf ;

			if @adminLevel2=1
				set @html = @html + @htmlTableSingleCol  + @crlf;
			else
				set @html = @html + @htmlTable  + @crlf;

			--  add Locator and Description header
			set @html = @html + @htmlTR  + @crlf;

			if @adminLevel2=1
			begin
				set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Admin Level 2</b></p></td>' + @crlf;
			end
			else
			begin
				set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>Locator</b></p></td>'  + @crlf;

				if @mapistat = 8
					set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>CRESTA Zone</b></p></td>' + @crlf;
				else
					set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>CRESTA Sub Zone</b></p></td>' + @crlf;

				set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Description</b></p></td>'  + @crlf;
			end

			if @DeprecatedCRESTAZones=1
				set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>CRESTA Vintage</b></p></td>'  + @crlf;

			set @html = @html + @htmlTRN  + @crlf;

                        set @outhtml = @html;
			set @html = '';

			if @wccImport = 'D'  and @mapistat = 8
			begin

				set @displayNote=0;
				if @DeprecatedCRESTAZones=0
					declare curs203 cursor for
					SELECT GEODATA.LOCATOR ,
					case left(substring(STATE, charindex( '-',STATE ) + 1, len(STATE)), 1)
					when ' ' then dbo.trim(substring(STATE, charindex( '-',STATE ) + 2, len(STATE)))
					else dbo.trim(STATE) end as name ,CrestaZone,CRESTAVintage
					FROM GEODATA JOIN STATEL on left(GEODATA.FIPS, len(STATEL.STATE_2)) = STATEL.STATE_2 and STATEL.COUNTRY_ID = GEODATA.COUNTRY_ID
            				where GEODATA.COUNTRY_ID = @cid AND abs(mapi_stat) = @mapistat and right(code_value, 2) <> 'PC'
            				and CRESTAVintage='' order by 1
            	else
                        	declare curs203 cursor for
					SELECT GEODATA.LOCATOR ,
					case left(substring(STATE, charindex( '-',STATE ) + 1, len(STATE)), 1)
					when ' ' then dbo.trim(substring(STATE, charindex( '-',STATE ) + 2, len(STATE)))
					else dbo.trim(STATE) end as name ,CrestaZone,CRESTAVintage
					FROM GEODATA JOIN STATEL on left(GEODATA.FIPS, len(STATEL.STATE_2)) = STATEL.STATE_2 and STATEL.COUNTRY_ID = GEODATA.COUNTRY_ID
            				where GEODATA.COUNTRY_ID = @cid AND abs(mapi_stat) = @mapistat and right(code_value, 2) <> 'PC'
            				and CRESTAVintage<>'' order by 1
				open curs203
				fetch curs203 into @loc,@name,@crestaZone,@crestaVintage
				while @@fetch_status=0
				begin
					if @cid<>'GBR'
					begin
						set @crestaZone=substring (@loc,6,2)
						if @crestaZone='' set @crestaZone='00'
					end
					if @i = 0
						set @html = @html + @htmlTR  + @crlf;
					set @html = @html +  '<TD width=16%>'+ @loc  + '</td>' + @crlf ;
					set @html = @html +  '<TD width=17%><p align=center style=''text-align:center''>' + @crestaZone + '</td>' + @crlf;
					set @html = @html +  '<TD width=17%>' + dbo.trim(@name) + '</td>' + @crlf;
					if @DeprecatedCRESTAZones=1
						set @html = @html +  '<TD width=16%><p align=center style=''text-align:center''>' + @crestaVintage + '</td>' + @crlf;
					set @i = @i + 1;

					set @html = @html + @htmlTRN  + @crlf;
					if len ( @html ) > 60000
					begin
						set @outhtml = @outhtml + @html;
						set @html = '';
					end
					fetch curs203 into @loc,@name,@crestaZone,@crestaVintage
				end
				close curs203
				deallocate curs203

			end
			else
			begin
				--Fixed SDG__00025327--
				--Don't show in the Helpfor some Locators in Asia Typhoon Countries
				exec @tblExists = absp_Util_CheckIfTableExists '#TMP_LOC_ASIATYPHOON' ;
				if (@tblExists = 1)
					drop table #TMP_LOC_ASIATYPHOON;

				create table #TMP_LOC_ASIATYPHOON (LOCATOR varchar(40));
			  	insert into #TMP_LOC_ASIATYPHOON values('PHL-002-000');
				insert into #TMP_LOC_ASIATYPHOON values('PHL-003-000');
				insert into #TMP_LOC_ASIATYPHOON values('PHL-004-000');
				insert into #TMP_LOC_ASIATYPHOON values('PHL-005-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-002-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-003-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-004-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-005-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-006-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-007-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-008-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-009-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-010-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-011-000');
				insert into #TMP_LOC_ASIATYPHOON values('TWN-012-000');

				insert into #TMP_LOC_ASIATYPHOON values('JPN-001-000');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-002-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-002-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-002-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-002-004');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-003-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-003-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-003-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-004-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-004-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-004-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-004-004');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-005-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-005-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-005-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-004');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-005');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-006-006');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-007-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-007-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-007-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-004');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-005');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-008-006');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-001');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-002');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-003');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-004');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-005');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-010-000');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-011-000');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-012-000');
				insert into #TMP_LOC_ASIATYPHOON values('JPN-009-004');

				set @displayNote=0;

				if @DeprecatedCRESTAZones=0  and @adminLevel2=0
					declare curs204 cursor for
						select WCCCODES.LOCATOR,
						case when WCCCODES.COUNTRY_ID='02' and (len(locator)>3 and substring(locator,5,1)<>'0') then
						rtrim(substring(locator,5,1)) + rtrim(Lower(substring(locator,6,34))) + ' Prefecture'
						else
						case left(substring(STATE, charindex( '-',STATE ) + 1, len(STATE)), 1)
						when ' ' then dbo.trim(substring(STATE, charindex( '-',STATE ) + 2, len(STATE)))
						else dbo.trim(STATE) end
						end ,
						CRESTAVintage,CRESTA
						FROM WCCCODES JOIN STATEL on WCCCODES.STATE_2 = STATEL.STATE_2 and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID
            					where WCCCODES.COUNTRY_ID = @cid AND abs(mapi_stat) = @mapistat
            					and CRESTAVintage='' order by 1
            	else if @DeprecatedCRESTAZones=0  and @adminLevel2=1
					declare curs204 cursor for
						select WCCCODES.LOCATOR,
						substring(WCCCODES.LOCATOR,5,99),
						CRESTAVintage,CRESTA
						FROM WCCCODES JOIN STATEL on WCCCODES.STATE_2 = STATEL.STATE_2 and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID
            					where WCCCODES.COUNTRY_ID = @cid AND abs(mapi_stat) = @mapistat
            					and CRESTAVintage='' order by 2
            	else
            		declare curs204 cursor for
						select WCCCODES.LOCATOR,
						case when WCCCODES.COUNTRY_ID='02' and (len(locator)>3 and substring(locator,5,1)<>'0') then
						rtrim(substring(locator,5,1)) + rtrim(Lower(substring(locator,6,34))) + ' Prefecture'
						else
						case left(substring(STATE, charindex( '-',STATE ) + 1, len(STATE)), 1)
						when ' ' then dbo.trim(substring(STATE, charindex( '-',STATE ) + 2, len(STATE)))
						else dbo.trim(STATE) end
						end ,
						CRESTAVintage,CRESTA
						FROM WCCCODES JOIN STATEL on WCCCODES.STATE_2 = STATEL.STATE_2 and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID
            					where WCCCODES.COUNTRY_ID = @cid AND abs(mapi_stat) = @mapistat
            					and CRESTAVintage<>'' order by 1
				open curs204
				fetch curs204 into @loc,@name,@crestaVintage,@crestaZone
				while @@fetch_status=0
				begin

					if not exists(select 1 from #TMP_LOC_ASIATYPHOON where LOCATOR = @loc)
					begin

						if @mapistat=10--SubZone
							select @crestaZone= SubCRESTA from WccCodes where locator=@loc
						else
						begin
							if (charindex('*',@loc)>0 )  set @displayNote=1;
							set @crestaZone=substring (@loc,6,2)
						end
						if @crestaZone='' set @crestaZone='00'

						if (charindex('*',@loc)=0 and @adminLevel2=0 ) or( (charindex('*',@loc)>0 and len(substring(@loc,charindex('*',@loc),len(@loc)-charindex('*',@loc)+1))>2) and (@adminLevel2=1))
						begin
							if @i = 0
								set @html = @html + @htmlTR  + @crlf;
							if  @adminLevel2=0
							begin
								set @html = @html +  '<TD width=16%>'+ @loc  + '</td>' + @crlf ;
								set @html = @html +  '<TD width=16%><p align=center style=''text-align:center''>' + dbo.trim(@crestaZone) + '</td>' + @crlf;

							end
							set @html = @html +  '<TD width=16%>' + dbo.trim(@name) + '</td>' + @crlf;


							if @DeprecatedCRESTAZones=1
								set @html = @html +  '<TD width=16%>' + dbo.trim(@crestaVintage) + '</td>' + @crlf;
							set @i = @i + 1;
							set @html = @html + @htmlTRN  + @crlf;

							if len ( @html ) > 60000
							begin
								set @outhtml = @outhtml + @html;
								set @html = '';
							end
						end
					end
					fetch curs204 into @loc,@name,@crestaVintage,@crestaZone
				end ;
				close curs204
				deallocate curs204

				exec @tblExists = absp_Util_CheckIfTableExists '#TMP_LOC_ASIATYPHOON' ;
				if (@tblExists = 1)
					drop table #TMP_LOC_ASIATYPHOON;

			end

			set @html = @html + @htmlTRN  + @crlf ;

			-- recover back to main variable the big string
			set @html = @outhtml  + @html;

		end
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''
	end

	set @html = @html + @htmlTableN;
	if @displayNote=1 and @adminLevel2=0
		set @html = @html + '<BR><B>Note:  CRESTA Zones may also be specified as a single digit (i.e. no leading zero) for CRESTA Zones that are less than 10.</B>';
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @cntry_id + @suffix + '#support-locators >  Go to Supported Geocoding Levels</a></H3>';
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';
	set @html = @html + @crlf + @htmlEnd;
	insert into ##TMP_CTRY_HTML values(@html)

	--Write to file
	set @fileName= @fileName + @suffix
	exec absp_Util_UnloadData 'Q','select line from ##TMP_CTRY_HTML order by line_no', @fileName


	print 'All Done!!!  '
	print '======================================================';
	if OBJECT_ID('tempdb..##TMP_CTRY_HTML','u') is not null drop table ##TMP_CTRY_HTML
	print 'End absp_MakeWccHtmlPagesForCountry'
end
