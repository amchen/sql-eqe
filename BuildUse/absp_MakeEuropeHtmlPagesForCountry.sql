if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeEuropeHtmlPagesForCountry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeEuropeHtmlPagesForCountry
end
go

create procedure absp_MakeEuropeHtmlPagesForCountry
    @mapistat       int = 0,
    @CID            varchar(3),
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
begin

--  CID        	    is a specific 3-char country code to generate (ie. BEL)
--                  Default means do it for all countries in the country table
--  directory       is where you want to place the generated HTML files (ie. "c:\html")

	set nocount on;

	print 'Start absp_MakeEuropeHtmlPagesForCountry';
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
	declare @sql varchar(4000);
	declare @valias varchar(30);

	-- select Code_Value,substring(Code_Value,5,99) from GeoData where Country_ID='AUT'
	declare @czQuery table (Country_ID varchar(3), LowRes varchar(500), HighRes varchar(500));
	insert @czQuery values ('AUT','and Code_Value like ''AUT_%'' and Geo_Stat in (402)','and Code_Value like ''AUT_%'' and Geo_Stat in (204)');
	insert @czQuery values ('BEL','and Code_Value like ''BEL_%'' and Geo_Stat in (401)','and Code_Value like ''BEL_%'' and Geo_Stat in (204)');
	insert @czQuery values ('CHE','and Code_Value like ''CHE_%'' and Geo_Stat in (409)','and Code_Value like ''CHE_%'' and Geo_Stat in (204)');
	insert @czQuery values ('CZE','and Code_Value like ''CZE_%'' and Geo_Stat in (402)','and Code_Value like ''CZE_%'' and Geo_Stat in (205)');
	insert @czQuery values ('DEU','and Code_Value like ''DEU_%'' and Geo_Stat in (402)','and Code_Value like ''DEU_%'' and Geo_Stat in (205)');
	insert @czQuery values ('DNK','and Code_Value like ''DNK_%'' and Geo_Stat in (402)','and Code_Value like ''DNK_%'' and Geo_Stat in (204)');
	insert @czQuery values ('ESP','and Code_Value like ''ESP_%'' and Geo_Stat in (452)','and Code_Value like ''ESP_%'' and Geo_Stat in (205)');
	insert @czQuery values ('EST','and Code_Value like ''EST_%'' and Geo_Stat in (452)','and Code_Value like ''EST_%'' and Geo_Stat in (205)');
	insert @czQuery values ('FIN','and Code_Value like ''FIN_%'' and Geo_Stat in (402)','and Code_Value like ''FIN_%'' and Geo_Stat in (205)');
	insert @czQuery values ('FRA','and Code_Value like ''FRA_%'' and Geo_Stat in (405)','and Code_Value like ''FRA_%'' and Geo_Stat in (205)');
	insert @czQuery values ('GBR','and Code_Value like ''GBR_%'' and Geo_Stat in (402)','and Code_Value like ''GBR_%'' and Geo_Stat in (204)');
	insert @czQuery values ('HUN','and Code_Value like ''HUN_%'' and Geo_Stat in (402)','and Code_Value like ''HUN_%'' and Geo_Stat in (204)');
	insert @czQuery values ('IRL','and Code_Value like ''IRL_%'' and Geo_Stat in (456)','and Code_Value like ''IRL_%'' and Geo_Stat in (204)');
	insert @czQuery values ('ITA','and Code_Value like ''ITA_%'' and Geo_Stat in (402)','and Code_Value like ''ITA_%'' and Geo_Stat in (205)');
	insert @czQuery values ('LTU','and Code_Value like ''LTU_%'' and Geo_Stat in (452)','and Code_Value like ''LTU_%'' and Geo_Stat in (205)');
	insert @czQuery values ('LUX','and Code_Value like ''LUX_%'' and Geo_Stat in (420)','and Code_Value like ''LUX_%'' and Geo_Stat in (202)');
	insert @czQuery values ('LVA','and Code_Value like ''LVA_%'' and Geo_Stat in (452)','and Code_Value like ''LVA_%'' and Geo_Stat in (204)');
	insert @czQuery values ('NLD','and Code_Value like ''NLD_%'' and Geo_Stat in (402)','and Code_Value like ''NLD_%'' and Geo_Stat in (204)');
	insert @czQuery values ('NOR','and Code_Value like ''NOR_%'' and Geo_Stat in (402)','and Code_Value like ''NOR_%'' and Geo_Stat in (204)');
	insert @czQuery values ('POL','and Code_Value like ''POL_%'' and Geo_Stat in (452)','and Code_Value like ''POL_%'' and Geo_Stat in (205)');
	insert @czQuery values ('PRT','and Code_Value like ''PRT_%'' and Geo_Stat in (402)','and Code_Value like ''PRT_%'' and Geo_Stat in (204)');
	insert @czQuery values ('ROU','and Code_Value like ''ROU_%'' and Geo_Stat in (408)','and Code_Value like ''ROU_%'' and Geo_Stat in (206)');
	insert @czQuery values ('SVK','and Code_Value like ''SVK_%'' and Geo_Stat in (402)','and Code_Value like ''SVK_%'' and Geo_Stat in (205)');
	insert @czQuery values ('SWE','and Code_Value like ''SWE_%'' and Geo_Stat in (406)','and Code_Value like ''SWE_%'' and Geo_Stat in (205)');


	set @DeprecatedCRESTAZones=0;
	set @adminLevel2 = 0;
	set @cntry_id = @cid;
	set @txtToWrite = '';

	if @cid = ' ' or len(@cid) = 0 or @cid = 'XX'
		return;

	set @suffix = '.html';

	-- create temp table
	if OBJECT_ID('tempdb..##TMP_CTRY_HTML','u') is not null drop table ##TMP_CTRY_HTML;
	create table ##TMP_CTRY_HTML (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS);

	set @crlf     = char(10)+char(13)
	set @htmlH2   = '<H2>';
	set @htmlH2N  = '</H2>';
	set @htmlH3   = '<H3>';
	set @htmlH3N  = '</H3>';
	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=25%>';
	set @htmlTableN = '</TABLE>';
	set @htmlTableLg = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=40%>';
	set @htmlTableLgN = '</TABLE>';
	set @htmlTableSingleCol = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=10%>';

	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + dbo.trim(@cntry) + ' - Geocoding Levels</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';

	set @i = 0;
	print '======================================================';
	set @msgText = 'Building Pages for '+ dbo.trim(@cntry);
	print @msgText;

	-------------------------------------------
	--  process Detail countries by MAPI_STAT
	-------------------------------------------

	if @mapistat >= 62 or @mapistat in (6,7)
	begin
		set @html = @htmlHeader;
		set @html = @html + @htmlBody;
		set @html = @html + @htmlH2;

		if @mapistat = 6
			set @html = @html + 'Postal Codes in ' + dbo.trim(@cntry);
		else
			set @html = @html + dbo.trim(@zoneName) + ' in ' + dbo.trim(@cntry);

		set @html = @html + @htmlH2N + @crlf ;

		if @mapistat = 7
			set @html = @html + '<H3>If duplicate cities exist within a country, all data imported by city will be imported into the city having the largest population.</H3>'  + @crlf;

		set @html = @html + @htmlTableSingleCol + @crlf;

		-- add Description header
		set @html = @html + @htmlTR  + @crlf;

		if @mapistat = 7
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Cities</b></p></td>' + @crlf;
		else if @mapistat = 6
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Postal Codes</b></p></td>' + @crlf;
		else if @mapistat = 62
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>2-Digit Postal Codes</b></p></td>' + @crlf;
		else if @mapistat = 63
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>3-Digit Postal Codes</b></p></td>' + @crlf;
		else if @mapistat = 64
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>4-Digit Postal Codes</b></p></td>' + @crlf;
		else if @mapistat = 65
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>5-Digit Postal Codes</b></p></td>' + @crlf;
		else if @mapistat = 66
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>6-Digit Postal Codes</b></p></td>' + @crlf;

		set @html = @html + @htmlTRN + @crlf;
		set @outhtml = @html;
		set @html = '';
	end

	-- 2-digit postCode
	if @mapistat = 62
	begin
		declare curs6 cursor for
			select Code_Value
			from GEODATA
			where ((@cid = 'NOR' and COUNTRY_ID = @cid and Geo_Stat = 202) or (@cid <> 'NOR' and COUNTRY_ID = @cid and Geo_Stat in (402,202,452,408)))
				and len(Code_Value)=2
			order by 1 asc;
		open curs6
		fetch curs6 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>' + @loc + '</td>' + @crlf;
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

		set @html = @html + @htmlTRN  + @crlf;
		set @html = @outhtml + @html;
		insert into ##TMP_CTRY_HTML values(@html);
		set @html = '';
	end

	-- 3, 4, 6-digit postCode
	if @mapistat = 63 or @mapistat = 64  or @mapistat = 66
	begin
		declare curs33 cursor for
			select Code_Value
			from GEODATA
			where COUNTRY_ID = @cid
				and (mapi_stat = 6 and geo_stat = 140 + @mapistat)		-- 203 or 204 or 206
		  	    and len(Code_Value) = (@mapistat - 60)
			order by 1 asc;
		open curs33
		fetch curs33 into @loc
		while @@fetch_status=0
		begin

			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>' + @loc + '</td>' + @crlf;
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
		set @html = @outhtml + @html;
		insert into ##TMP_CTRY_HTML values(@html);
		set @html = '';
	end

	-- 5-digit postCode
	if @mapistat = 65
	begin
		declare curs35 cursor for
			select Code_Value
			from GEODATA
			where COUNTRY_ID = @cid
				and (mapi_stat = 6 and geo_stat = 205)
				and len(Code_Value) = (@mapistat - 60)
			order by 1 asc;
		open curs35
		fetch curs35 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%><p align=center style=''text-align:center''>' + @loc + '</td>' + @crlf;
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
		set @html = @outhtml + @html;
		insert into ##TMP_CTRY_HTML values(@html);
		set @html = '';
	end

	---------------------------------------------------------------------------------
	-- Old CRESTA Zones in ('CZE','DNK','ESP','HUN','LUX','NOR','PRT','ROU','SWE')
	---------------------------------------------------------------------------------
	if @mapistat = 11
	begin
		-- Create/populate data table
		if exists (select 1 from sys.tables where name='OldCrestaZones') drop table OldCrestaZones;

		select distinct CrestaZone, CrestaVintage, 'XXXXX' ValidAlias into OldCrestaZones
			from GEODATA
			where Country_ID = @cid
			and CrestaVintage <> ''
			order by 1;

		update OldCrestaZones set ValidAlias = right(CrestaZone,1) where CrestaZone like '0_';
		update OldCrestaZones set ValidAlias = '&nbsp' where ValidAlias = 'XXXXX';

		set @html = @htmlHeader;
		set @html = @html + @htmlBody;

		if (@cid = 'CZE') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="CZE_1999.gif" width="1000">' + @crlf;
		end
		if (@cid = 'DNK') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="DNK_2007.gif" width="1000">' + @crlf;
		end
		if (@cid = 'ESP') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="ESP_1999.gif" width="1000">' + @crlf;
		end
		if (@cid = 'HUN') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="HUN_2006.gif" width="1000">' + @crlf;
		end
		if (@cid = 'LUX') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="LUX_1999.gif" width="1000">' + @crlf;
		end
		if (@cid = 'NOR') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - Extreme North' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_Extreme_North.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - North' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_North.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - Central' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_Middle.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - South' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_South.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - West' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_SouthWest.gif" width="1000">' + @crlf;
			set @html = @html + @htmlH2 + @cntry + ' - Oslo' + @htmlH2N + @crlf;
			set @html = @html + '<img src="NOR_2006_Oslo.gif" width="1000">' + @crlf;
		end
		if (@cid = 'PRT') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="PRT_1999.gif" width="1000">' + @crlf;
		end
		if (@cid = 'ROU') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="ROU_2006.gif" width="1000">' + @crlf;
		end
		if (@cid = 'SWE') begin
			set @html = @html + @htmlH2 + @zoneName + ' Maps for ' + @cntry + @htmlH2N + @crlf;
			set @html = @html + '<img src="SWE_2006.gif" width="1000">' + @crlf;
		end

		set @html = @html + @htmlH2;
		set @html = @html + @zoneName + 's in ' + @cntry;
		set @html = @html + @htmlH2N + @crlf ;
		set @html = @html + @htmlTableLg  + @crlf;

		--	add column header
		set @html = @html + @htmlTR  + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>CRESTA Zones</b></p></td>'   + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>CRESTA Vintage</b></p></td>' + @crlf;
		set @html = @html + '<TD width=20%><p align=center style=''text-align:center''><b>Valid Aliases</b></p></td>'  + @crlf;
		set @html = @html + @htmlTRN  + @crlf;
		set @outhtml = @html;
		set @html = '';

		set @str = dbo.trim(@fileName) + '.txt';
		exec absp_Util_DeleteFile @str;

		declare curs35 cursor for
			select CrestaZone, CrestaVintage, ValidAlias
			from OldCrestaZones
			ORDER BY 1 ASC;
		open curs35;
		fetch curs35 into @zone_name, @crestaVintage, @valias;
		while @@fetch_status=0
		begin

			if @i = 0
			   set @html = @html + @htmlTR  + @crlf;

			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''>'+ @zone_name      + '</p></td>' + @crlf;
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''>'+ @crestaVintage  + '</p></td>' + @crlf;
			set @html = @html + '<TD width=20%><p align=center style=''text-align:center''>'+ @valias         + '</p></td>' + @crlf;

			set @i = @i + 1;

		    set @html = @html + @htmlTRN  + @crlf;

			if len ( @html ) > 60000
			begin
			 	set @outhtml = @outhtml + @html;
				set @html = '';
			end

			set @txtToWrite = @zone_name + ',' + @crestaVintage + ',' + @valias;

			-- Create .txt files for municipal codes and district locators --
			--set @str='echo ' + @txtToWrite + '>>"' + @fileName + '.txt'+'"'
			--exec xp_cmdshell @str, no_output

			fetch curs35 into @zone_name, @crestaVintage, @valias;
		end ;
		close curs35
		deallocate curs35

		set @html = @html + @htmlTRN  + @crlf ;

		--recover back to main variable the big string
		set @html = @outhtml  + @html;
		insert into ##TMP_CTRY_HTML values(@html)
		set @html=''

		if exists (select 1 from sys.tables where name='OldCrestaZones') drop table OldCrestaZones;
	end

	-- city post code
	if @mapistat = 7
	begin
		declare curs22 cursor for
			SELECT Code_Value
				FROM GEODATA
				WHERE COUNTRY_ID = @cid and MAPI_STAT = @mapistat
				ORDER BY Code_Value
		open curs22
		fetch curs22 into @loc
		while @@fetch_status=0
		begin
			if @i = 0
			    set @html = @html + @htmlTR  + @crlf;

			set @html = @html +  '<TD width=20%>'+ @loc + '</td>' + @crlf;
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
		insert into ##TMP_CTRY_HTML values(@html);
		set @html = '';
	end

	-- LowRes CRESTA Zones
	if @mapistat = -8
	begin

		set @i = 0;
		print '======================================================';
		set @msgText = 'Building LowRes CRESTA Zones for '+ @cntry;
		print @msgText;

		set @html = @htmlHeader;
		set @html = @html + @htmlBody;
		set @html = @html + @htmlH2;
		set @html = @html + 'LowRes CRESTA Zones in ' + @cntry;
		set @html = @html + @htmlH2N + @crlf ;
		set @html = @html + @htmlTable + @crlf;

		--  add headers
		set @html = @html + @htmlTR + @crlf;
		set @html = @html + '<TD width=50%><p align=center style=''text-align:center''><b>LowRes CRESTA Zones</b></p></td>' + @crlf;
		set @html = @html + '<TD width=50%><p align=center style=''text-align:center''><b>Valid Aliases</b></p></td>' + @crlf;
		set @html = @html + @htmlTRN + @crlf;

		-- save and reset html
		set @outhtml = @html;
		set @html = '';

		-- get the where clause
		select @sql = LowRes from @czQuery where Country_ID = @cid;
		set @sql = 'select rtrim(Code_Value), rtrim(substring(Code_Value,5,99)),len(Code_Value) from GeoData where Country_ID=''@cid''' + @sql;
		set @sql = replace(@sql,'@cid',@cid);

		execute('declare cursRes cursor forward_only global for ' + @sql + ' order by 3 desc, 1 asc');

		open cursRes;
		fetch cursRes into @loc, @name, @outcount1;
		while @@fetch_status=0
		begin
			if @i = 0
				set @html = @html + @htmlTR + @crlf;

			set @html = @html + '<TD width=30%><p align=center style=''text-align:center''>' + @loc  + '</td>' + @crlf ;
			set @html = @html + '<TD width=30%><p align=center style=''text-align:center''>' + @name + '</td>' + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end

			set @i = @i + 1;
			fetch cursRes into @loc, @name, @outcount1;
		end
		close cursRes;
		deallocate cursRes;

		set @html = @html + @htmlTRN + @crlf;

		-- recover back to main variable the big string
		set @html = @outhtml + @html;
	end

	-- HighRes CRESTA Zones
	if @mapistat = -9
	begin

		set @i = 0;
		print '======================================================';
		set @msgText = 'Building HighRes CRESTA Zones for '+ @cntry;
		print @msgText;

		set @html = @htmlHeader;
		set @html = @html + @htmlBody;
		set @html = @html + @htmlH2;
		set @html = @html + 'HighRes CRESTA Zones in ' + @cntry;
		set @html = @html + @htmlH2N + @crlf ;
		set @html = @html + @htmlTable + @crlf;

		--  add headers
		set @html = @html + @htmlTR + @crlf;
		set @html = @html + '<TD width=50%><p align=center style=''text-align:center''><b>HighRes CRESTA Zones</b></p></td>' + @crlf;
		set @html = @html + '<TD width=50%><p align=center style=''text-align:center''><b>Valid Aliases</b></p></td>' + @crlf;
		set @html = @html + @htmlTRN + @crlf;

		-- save and reset html
		set @outhtml = @html;
		set @html = '';

		-- get the where clause
		select @sql = HighRes from @czQuery where Country_ID = @cid;
		set @sql = 'select rtrim(Code_Value), rtrim(substring(Code_Value,5,99)),len(Code_Value) from GeoData where Country_ID=''@cid''' + @sql;
		set @sql = replace(@sql,'@cid',@cid);

		execute('declare cursRes cursor forward_only global for ' + @sql + ' order by 3 desc, 1 asc');

		open cursRes;
		fetch cursRes into @loc, @name, @outcount1;
		while @@fetch_status=0
		begin
			if @i = 0
				set @html = @html + @htmlTR + @crlf;

			set @html = @html + '<TD width=30%><p align=center style=''text-align:center''>' + @loc  + '</td>' + @crlf ;
			set @html = @html + '<TD width=30%><p align=center style=''text-align:center''>' + @name + '</td>' + @crlf;
			set @html = @html + @htmlTRN  + @crlf;
			if len ( @html ) > 60000
			begin
				set @outhtml = @outhtml + @html;
				set @html = '';
			end

			set @i = @i + 1;
			fetch cursRes into @loc, @name, @outcount1;
		end
		close cursRes;
		deallocate cursRes;

		set @html = @html + @htmlTRN + @crlf;

		-- recover back to main variable the big string
		set @html = @outhtml + @html;
	end


	insert into ##TMP_CTRY_HTML values(@html);
	set @html = '';

	set @html = @html + @htmlTableN;
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @cntry_id + @suffix + '#support-locators >  Go to Supported Geocoding Levels</a></H3>';
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';
	set @html = @html + @crlf + @htmlEnd;
	insert into ##TMP_CTRY_HTML values(@html)

	-- Write to file
	set @fileName = @fileName + @suffix;
	exec absp_Util_UnloadData 'Q','select line from ##TMP_CTRY_HTML order by line_no', @fileName;

	print 'All Done!';
	print '======================================================';
	if OBJECT_ID('tempdb..##TMP_CTRY_HTML','u') is not null drop table ##TMP_CTRY_HTML;
	print 'End absp_MakeEuropeHtmlPagesForCountry';
end
