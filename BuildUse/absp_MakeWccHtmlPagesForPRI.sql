if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlPagesForPRI') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlPagesForPRI
end
go

create procedure  absp_MakeWccHtmlPagesForPRI
	@CNTRY varchar (50),
	@zoneName varchar(255),
	@appendYear varchar(10),
	@replaceYear varchar(10),
	@fileName varchar(255),
	@TOCName varchar(255)
as
begin try

	set nocount on
	--
	--  cntry_id is a specific 3-char country code to generate (ie. BEL)
	--
	declare @html varchar(max);
	declare @htmlH2 varchar(10);
	declare @htmlH2N varchar(10);
	declare @htmlTable varchar(100);
	declare @htmlTableLg varchar(100);
	declare @htmlTableN varchar(20);
	declare @htmlTR varchar(10);
	declare @htmlTRN varchar(10);
	declare @htmlIMG varchar(10);
	declare @htmlIMGN varchar(10);
	declare @htmlHeader varchar(255);
	declare @htmlBody varchar(255);
	declare @htmlEnd varchar(255);
	declare @crlf varchar(2);
	declare @name varchar(150);
	declare @startIndx int;
	declare @results varchar(40);
	declare @countryId varchar(3);
	declare @CID varchar(3);
	declare @i int;
	declare @suffix varchar(5);
	declare @state2 varchar(2);
	declare @desc  varchar(80);
	declare @l  int;
	declare @locator  varchar(45);
	declare @loc   varchar(45);
	declare @zone_name  varchar(50);
	declare @str varchar(max)
	declare @fName varchar(1000)
	declare @crestaZone varchar(10)
	declare @crestaVintage varchar(4)
	declare @displayNote int
	declare @DeprecatedCRESTAZones int
	declare @adminLevel2 int

	set @DeprecatedCRESTAZones=0
	set @adminLevel2 = 0
	if charindex('Deprecated',@fileName)>0
		set @DeprecatedCRESTAZones=1
	else if charindex('AdminLevel2',@fileName)>0
		set @adminLevel2=1

	--create temp table
	if OBJECT_ID('tempdb..##TMP_PRI_HTML','u') is not null drop table ##TMP_PRI_HTML
	create table ##TMP_PRI_HTML (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS)

	set @crlf     = CHAR(10)+CHAR(13)
	set @htmlH2   = '<H2>';
	set @htmlH2N  = '</H2>';
	set @htmlIMG  = '<img src="';
	set @htmlIMGN = '.gif">';

	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=60%>';
	set @htmlTableLg = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=20%>';
	set @htmlTableN = '</TABLE>';
	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + rtrim(@CNTRY) + ' - ' + substring(dbo.trim(@appendYear),2,LEN(dbo.trim(@appendYear))) + ' Country Locators</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';

	set @suffix = '.html';
	set @CID = 'PRI';
	set @html = '';
	set @i = 0;

	set @html = @htmlHeader;
	set @html = @html + @htmlBody;
	set @html = @html + @htmlH2;

	if @adminLevel2=1
		set @html = @html + 'Admin Level 2 Codes in ' +dbo.trim(@CNTRY);
	else if  @adminLevel2=0 and @DeprecatedCRESTAZones=0
		set @html = @html + ' CRESTA Zones in ' + @CNTRY;
	else
		set @html = @html +  substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear)))  + ' CRESTA Zones in ' + @CNTRY;

	set @html = @html + @htmlH2N + @crlf ;

	if @adminLevel2=1
	begin
		set @html = @html + @htmlTableLg + @crlf;
		set @html = @html + @htmlTR + @crlf;
		set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Admin Level 2</b></p></td>' + @crlf;
	end
	else
	begin
		set @html = @html + @htmlTable + @crlf;
		set @html = @html + @htmlTR + @crlf;
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>Locator</b></p></td>'     + @crlf;
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>CRESTA Zone</b></p></td>' + @crlf;
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>Description</b></p></td>' + @crlf;
	end

	if @DeprecatedCRESTAZones=1
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>CRESTA Vintage</b></p></td>' + @crlf;

	set @html = @html + @htmlTRN + @crlf;

	insert into ##TMP_PRI_HTML values(@html)
	set @html=''

	----	For the special country 'PRI', CID is actually '00' and STATE_2 is actually 'PR'
	----	So the query and the for-loop will be treated differently from the rest.
	----  =================================================================================

	--set @countryId = '00';
	--set @displayNote=0;
	--declare curs1 cursor for
	--	SELECT STATE_2 , STATE  FROM STATEL
	--		WHERE  COUNTRY_ID=@countryId and STATE_2 = 'PR' ORDER BY STATE_2
	--open curs1
	--fetch curs1 into @state2, @desc
	--while @@fetch_status=0
	--begin
	--	if @DeprecatedCRESTAZones=0  and @adminLevel2=0
	--		declare curs2 cursor for
	--			SELECT len(LOCATOR),dbo.trim(LOCATOR), LOCATOR, dbo.trim(ZONE_NAME),dbo.trim(CRESTAVintage),CRESTA
	--			FROM WCCCODES
	--			WHERE COUNTRY_ID = @countryId AND STATE_2 = dbo.trim(@state2)
	--			AND charindex(dbo.trim(@appendYear),LOCATOR) > 0  AND dbo.trim(ZONE_NAME) <> '<>'
	--			AND  mapi_stat = 8 and CRESTAVintage='' ORDER BY 1,2 ASC
	--	else if @DeprecatedCRESTAZones=0  and @adminLevel2=1
	--		declare curs2 cursor for
	--			SELECT len(LOCATOR),dbo.trim(LOCATOR), substring(LOCATOR,5,99),dbo.trim(CRESTAVintage),CRESTA
	--			FROM WCCCODES
	--			WHERE COUNTRY_ID = @countryId AND STATE_2 = dbo.trim(@state2)
	--			AND charindex(dbo.trim(@appendYear),LOCATOR) > 0  AND dbo.trim(ZONE_NAME) <> '<>'
	--			AND  mapi_stat = 8 and CRESTAVintage='' ORDER BY 3 ASC
	--	else
	--		declare curs2 cursor for
	--			SELECT len(LOCATOR),dbo.trim(LOCATOR), LOCATOR, dbo.trim(ZONE_NAME),dbo.trim(CRESTAVintage),CRESTA
	--			FROM WCCCODES
	--			WHERE COUNTRY_ID = @countryId AND STATE_2 = dbo.trim(@state2)
	--			AND charindex(dbo.trim(@appendYear),LOCATOR) > 0  AND dbo.trim(ZONE_NAME) <> '<>'
	--			AND  mapi_stat = 8  and CRESTAVintage<>'' ORDER BY 1,2 ASC
	--	open curs2
	--	fetch curs2 into @l,@loc,@locator,@zone_Name,@crestaVintage,@crestaZone
	--	while @@fetch_status=0
	--	begin

	--		if (charindex('*',@loc)>0 )  set @displayNote=1;
	--		set @name=@zoneName

	--		set @crestaZone=substring (@loc,6,2)
	--		if @crestaZone='' set @crestaZone='00'

	--		if (charindex('*',@loc)=0 and @adminLevel2=0 ) or( (charindex('*',@loc)>0 and len(substring(@loc,charindex('*',@loc),len(@loc)-charindex('*',@loc)+1))>2) and (@adminLevel2=1))
	--		begin
	--			if @i = 0
	--				set @html = @html + @htmlTR  + @crlf;

	--			--process the locator
	--			exec absp_processTheLocator @results out, @CID, @loc;
	--			if  @adminLevel2=0
	--			begin
	--				set @html = @html +  '<TD width=16%>'+  @results  + '</td>' + @crlf ;
	--				set @html = @html +  '<TD width=16%><p align=center style=''text-align:center''>' + dbo.trim(@crestaZone) + '</td>' + @crlf;
	--				--set @name = '<TD width=17%>' + @zone_Name + '</td>';
	--			end
	--			set @html = @html +  '<TD width=16%>' + @name  + '</td>' + @crlf;


	--			if @DeprecatedCRESTAZones=1
	--				set @name = '<TD width=17%><p align=center style=''text-align:center''>' + @crestaVintage + '</td>';
	--			set @html = @html +  @name  + @crlf ;
	--			set @i = @i + 1;

	--			set @html = @html + @htmlTRN  + @crlf;

	--		end
	--		fetch curs2 into @l,@loc,@locator,@zone_Name,@crestaVintage,@crestaZone
	--	end
	--	close curs2
	--	deallocate curs2
	--	fetch curs1 into @state2, @desc
	--end;
	--close curs1
	--deallocate curs1

	--if @i > 0
	--begin
	--	while @i < 2
	--	begin
	--		set @html = @html + '<TD width=16%> .</td>' + @crlf;
	--		set @html = @html +'<TD width=17%> .</td>' + @crlf;
	--		set @i = @i + 1;
	--	end;
	--	set @html = @html + @htmlTRN  + @crlf ;
	--end;
	--set @html = @html + @htmlTableN;

	--if @displayNote=1
	--	set @html = @html + '<BR><B>Note:  CRESTA Zones may also be specified as a single digit (i.e. no leading zero) for CRESTA Zones that are less than 10.</B>';

	--set @html = @html + '<BR><BR>' + @crlf;


	--set @html = @html + '<BR>';
	--set @html = @html + '<H3><a href=' + @CID + '.html' + '#support-locators >  Go to Supported Geocoding Levels</a></H3>';
	--set @html = @html + '<BR>';
	--set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';

	--set @html = @html + @crlf + @htmlEnd;


	--insert into ##TMP_PRI_HTML values(@html)

	----Write to file
	--set @fName=@filename + '_' + substring(dbo.trim(@appendYear),2,LEN(dbo.trim(@appendYear))) + '.html'
	--exec absp_Util_UnloadData 'Q','select * from ##TMP_PRI_HTML',@fName
	--truncate table ##TMP_PRI_HTML


	--	add the old map
	set @i = 0;

	--set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + @CNTRY + ' - ' + substring(dbo.trim(@replaceYear),2,LEN(dbo.trim(@replaceYear))) + ' Country Locators</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	--set @html = @htmlHeader;
	--set @html = @html + @htmlBody;
	--set @html = @html + @htmlH2 + @crlf ;

	--set @html = @html + substring(@replaceYear,2,LEN(@replaceYear)) + ' ' + @zoneName + ' in ' + @CNTRY;
	--set @html = @html + @htmlH2N + @crlf ;
	--set @html = @html + @htmlTable  + @crlf ;

	----	add Locator and Description header
	--set @html = @html + @htmlTR  + @crlf;
	--set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>Locator</b></p></td>'  + @crlf;
	--set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>CRESTA Zone</b></p></td>' + @crlf;
	--set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Description</b></p></td>'  + @crlf;
	--if @DeprecatedCRESTAZones=1
	--	set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>CRESTA Vintage</b></p></td>'  + @crlf;

	--set @html = @html + @htmlTRN  + @crlf;
	--
	--	add the locators for the old map

	set @countryId = '00';
	set @displayNote=0;

	declare curs11 cursor for
		SELECT STATE_2, STATE
		FROM STATEL
		WHERE COUNTRY_ID=@countryId and STATE_2 = 'PR' ORDER BY STATE_2
	open curs11
	fetch curs11 into @state2, @desc
	while @@fetch_status=0
	begin
		SELECT  @startIndx= charindex( '-', @desc ) ;
		set @name = substring(@desc, @startIndx+1, len(@desc));
		if (left(@name, 1) = ' ')
				 set @name = substring(@name, 2, len(@desc));

		set @name = dbo.trim(@name);

 		if @DeprecatedCRESTAZones=1
 			declare curs21 cursor for
 				SELECT dbo.trim(LOCATOR), LOCATOR, dbo.trim(ZONE_NAME),dbo.trim(CRESTAVintage),CRESTA
 				FROM WCCCODES
 				WHERE COUNTRY_ID = @countryId AND STATE_2 = @state2
 				and dbo.trim(ZONE_NAME) <> '<>' and
				charindex(@appendYear,LOCATOR) = 0  AND
				mapi_stat = 8
				and CRESTAVintage<>''
				ORDER BY LOCATOR ASC
		else
			declare curs21 cursor for
 				SELECT dbo.trim(LOCATOR), LOCATOR, dbo.trim(ZONE_NAME),dbo.trim(CRESTAVintage),CRESTA
 				FROM WCCCODES
 				WHERE COUNTRY_ID = @countryId AND STATE_2 = @state2
 				and dbo.trim(ZONE_NAME) <> '<>' and
				charindex(@appendYear,LOCATOR) = 0  AND
				mapi_stat = 8
				and CRESTAVintage=''
				ORDER BY LOCATOR ASC
 		open curs21
 		fetch curs21 into  @loc,@locator,@zone_Name,@crestaVintage,@crestaZone
 		while @@fetch_status=0
		begin
			if @i = 0
				set @html = @html + @htmlTR  + @crlf;

			if (charindex('*',@loc)>0)  set @displayNote=1;

			set @crestaZone=substring (@loc,6,2);

			if @crestaZone='' set @crestaZone='00';

			--process the locator
			if (charindex('*',@loc)=0 and @adminLevel2=0 ) or( (charindex('*',@loc)>0 and len(substring(@loc,charindex('*',@loc),len(@loc)-charindex('*',@loc)+1))>2) and (@adminLevel2=1))
			begin
				if  @adminLevel2=0
				begin
					set @html = @html + '<TD width=16%><p align=center style=''text-align:center''>' + @LOC                  + '</td>' + @crlf;
					set @html = @html + '<TD width=16%><p align=center style=''text-align:center''>' + dbo.trim(@crestaZone) + '</td>' + @crlf;
					set @html = @html + '<TD width=16%><p align=center style=''text-align:center''>' + @name                 + '</td>' + @crlf;
				end
				else
					set @html = @html + '<TD width=16%><p align=center style=''text-align:center''>' + dbo.trim(substring(@LOC,5,99)) + '</td>' + @crlf;

				if @DeprecatedCRESTAZones=1
					set @html = @html + '<TD width=16%><p align=center style=''text-align:center''>' + @crestaVintage + @crlf;

				set @i = @i + 1;

				set @html = @html + @htmlTRN  + @crlf;

			end
			fetch curs21 into @loc,@locator,@zone_Name,@crestaVintage,@crestaZone;
		end;
		close curs21;
		deallocate curs21;
		fetch curs11 into @state2, @desc;
	end;
	close curs11;
	deallocate curs11;

	set @html = @html + @htmlTRN + @crlf;


	set @html = @html + @htmlTableN;
	if @displayNote=1 and @adminLevel2=0
		set @html = @html + '<BR><B>Note:  CRESTA Zones may also be specified as a single digit (i.e. no leading zero) for CRESTA Zones that are less than 10.</B>';

	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @CID + @suffix + '#support-locators >  Go to Supported Geocoding Levels</a></H3>';
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';

	set @html = @html + @crlf + @htmlEnd;

	insert into ##TMP_PRI_HTML values(@html)

	--Write to file
	set @fName= @filename +  '.html'
	exec absp_Util_UnloadData 'Q','select line from ##TMP_PRI_HTML order by line_no',@fName
	if OBJECT_ID('tempdb..##TMP_PRI_HTML','u') is not null drop table ##TMP_PRI_HTML

end try

begin catch
	exec absp_Util_DeleteFile @fileName
	if OBJECT_ID('tempdb..##TMP_PRI_HTML','u') is not null drop table ##TMP_PRI_HTML
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
