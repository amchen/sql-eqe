if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlPagesForLocAppndCountry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlPagesForLocAppndCountry
end
go

create procedure  absp_MakeWccHtmlPagesForLocAppndCountry  
	@cntry_id char(3),
	@CNTRY char (50),
	@mapistat int,
	@zoneName varchar(255),
	@wccImport char(1),
	@appendYear char(10),
	@replaceYear char(10),
	@fileName varchar(255),
	@TOCName varchar(255)
as
begin try
	set nocount on 
	print 'Start  absp_MakeWccHtmlPagesForLocAppndCountry'
	--
	--  cntry_id is a specific 3-char country code to generate (ie. BEL)
	--           Default means do it for all countries in the country table
	--  directory is where you want to place the generated HTML files (ie. "c:\html")
	--
	declare @htmlH2 varchar(10);
	declare @htmlH2N varchar(10);
	declare @htmlTable varchar(100);
	declare @htmlTableLg varchar(100);
	declare @htmlTableN varchar(20);
	declare @htmlTR varchar(10);
	declare @htmlTRN varchar(10);
	declare @htmlHeader varchar(255);
	declare @htmlBody varchar(255);
	declare @htmlEnd varchar(255);
	declare @html varchar(max);
	declare @outhtml varchar(max);
	declare @crlf varchar(2);
	declare @name varchar(150);
	declare @startIndx int;
	declare @results varchar(40);
	declare @countryId varchar(3);
	declare @CID varchar(3);
	declare @i int;
	declare @imageCount int;
	declare @suffix varchar(5);
	declare @str varchar(max);
	declare @l int;
	declare @loc  varchar(45);
	declare @fname  varchar(2000);
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
	if OBJECT_ID('tempdb..##TMP_LOC_HTML','u') is not null drop table ##TMP_LOC_HTML
	create table ##TMP_LOC_HTML (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS)
	
	set @crlf     = CHAR(10)+CHAR(13)
	set @htmlH2   = '<H2>'; 
	set @htmlH2N  = '</H2>';

	set @htmlTR = '<TR>'; 
	set @htmlTRN = '</TR>'; 
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=60%>'; 
	set @htmlTableLg = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=20%>'; 
	set @htmlTableN = '</TABLE>';

	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</BODY></HTML>';

	set @suffix = '.html';
	set @CID = @cntry_id;
	set @html = '';
	set @i = 0;
 
	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>' + @CNTRY + ' - ' + substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear))) + ' Country Locators</TITLE>' + @crlf + '</HEAD>' + @crlf ;

	set @html = @htmlHeader;
	set @html = @html + @htmlBody;
	set @html = @html + @htmlH2;
	
	--set cresta zone (mapi_stat =8) & cresta sub-zones (mapi_stat = 10) header
	 if @mapistat = 8  and @adminLevel2=1
			set @html = @html + 'Admin Level 2 Codes in ' + @cntry;
	else if @mapistat = 8  and @adminLevel2=0 and @DeprecatedCRESTAZones=0
		set @html = @html + ' CRESTA Zones in ' + @CNTRY;
	else if @mapistat = 8  and @adminLevel2=0 and @DeprecatedCRESTAZones=1 and @CID='AUS'
		set @html = @html + substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear))) + ' ICA Zones in ' + @CNTRY;
	else if @mapistat = 8  and @adminLevel2=0 and @DeprecatedCRESTAZones=1 and @CID<>'AUS'
		set @html = @html + substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear))) + ' CRESTA Zones in ' + @CNTRY;
	else if @mapistat = 10
		set @html = @html + substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear))) + ' CRESTA Sub Zones in ' + @CNTRY;
	else 
		set @html = @html + substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear))) + ' ' + @zoneName + ' in ' + @CNTRY;
	 
	set @html = @html + @htmlH2N + @crlf ;
	
	if @adminLevel2=1
			set @html = @html + @htmlTableLg  + @crlf;
	else
			set @html = @html + @htmlTable  + @crlf;
				

--	add Locator and Description header
	set @html = @html + @htmlTR  + @crlf;
	if @adminLevel2=1
	begin
		set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Admin Level 2</b></p></td>' + @crlf;
	end
	else
	begin
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>Locator</b></p></td>'  + @crlf;
		if @mapistat=8
			set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>CRESTA Zone</b></p></td>' + @crlf;
		else
			set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>CRESTA Sub Zone</b></p></td>' + @crlf;
		set @html = @html + '<TD width=17%><p align=center style=''text-align:center''><b>Description</b></p></td>'  + @crlf;
	END
	
	 if @DeprecatedCRESTAZones=1	
		set @html = @html + '<TD width=16%><p align=center style=''text-align:center''><b>CRESTA Vintage</b></p></td>'  + @crlf;

	set @html = @html + @htmlTRN  + @crlf;

	set @outhtml = @html;
	set @html = '';

	insert into ##TMP_LOC_HTML values(@outhtml );

--	add the locators for the old map

      
	set @displayNote=0;			
	if @wccImport = 'D'  and @mapistat = 8 
	begin
		if @DeprecatedCRESTAZones=0	
			declare curs13 cursor for
				SELECT  len(GEODATA.LOCATOR), GEODATA.LOCATOR,
				case left(substring(STATE, charindex( '-', STATE ) + 1, len(STATE)), 1) 
				when ' ' then dbo.trim(substring(STATE, charindex(  '-', STATE ) + 2, len(STATE)))
				else dbo.trim(STATE) end as name ,dbo.trim(CRESTAVintage)
				FROM GEODATA JOIN STATEL on left(GEODATA.FIPS,2) = STATEL.STATE_FIPS and STATEL.COUNTRY_ID = GEODATA.COUNTRY_ID 
				where GEODATA.COUNTRY_ID = @CID AND abs(mapi_stat) = @mapistat and right(code_value, 2) <> 'PC' and GEODATA.LOCATOR not like '%' + dbo.trim(@appendYear)
				and CRESTAVintage=''
				order by 1 ,2
			else
			declare curs13 cursor for
				SELECT  len(GEODATA.LOCATOR), GEODATA.LOCATOR,
				case left(substring(STATE, charindex( '-', STATE ) + 1, len(STATE)), 1) 
				when ' ' then dbo.trim(substring(STATE, charindex(  '-', STATE ) + 2, len(STATE)))
				else dbo.trim(STATE) end as name ,dbo.trim(CRESTAVintage)
				FROM GEODATA JOIN STATEL on left(GEODATA.FIPS,2) = STATEL.STATE_FIPS and STATEL.COUNTRY_ID = GEODATA.COUNTRY_ID 
				where GEODATA.COUNTRY_ID = @CID AND abs(mapi_stat) = @mapistat and right(code_value, 2) <> 'PC' and GEODATA.LOCATOR not like '%' + dbo.trim(@appendYear)
				and CRESTAVintage<>''
				order by 1 ,2
		open curs13
		fetch curs13 into @l, @loc,@name,@crestaVintage
		while @@fetch_status=0
		begin

			if @i = 0 
				set @html = @html + @htmlTR  + @crlf;
		    
			set @crestaZone=substring (@loc,6,2)
			if @crestaZone='' set @crestaZone='00'
				
			--process the locator
			--exec absp_processTheLocator @results out, @CID, @LOC;
			set @html = @html +  '<TD width=16%>'+  @LOC  + '</td>' + @crlf ;
			set @html = @html +  '<TD width=17%><p align=center style=''text-align:center''>' + dbo.trim(@crestaZone) + '</td>' + @crlf;
			set @html = @html +  '<TD width=17%>' + dbo.trim(@name) + '</td>' + @crlf;
			if @DeprecatedCRESTAZones=1	
				set @html = @html +  '<TD width=17%><p align=center style=''text-align:center''>' + dbo.trim(@crestaVintage) + '</td>' + @crlf;
			set @i = @i + 1;

				set @html = @html + @htmlTRN  + @crlf;
	 
			insert into ##TMP_LOC_HTML values(@html );
			set @html=''
			fetch curs13 into @l, @loc,@name,@crestaVintage
		end 
		close curs13
		deallocate curs13
	end
	else
	begin
		if @DeprecatedCRESTAZones=0	and @adminLevel2=0		
			declare curs13 cursor for
				SELECT  len(WCCCODES.LOCATOR) , WCCCODES.LOCATOR, 
				case left(substring(STATE, charindex(  '-',STATE  ) + 1, len (STATE)), 1) 
				when ' ' then dbo.trim(substring(STATE, charindex(  '-',STATE ) + 2, len (STATE)))
				else dbo.trim(STATE) end as name ,CRESTAVintage,CRESTA
				FROM WCCCODES JOIN STATEL on left(WCCCODES.FIPS,2) = STATEL.STATE_FIPS and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID 
				where WCCCODES.COUNTRY_ID = @CID AND abs(mapi_stat) = @mapistat -- and WCCCODES.LOCATOR not like '%' + dbo.trim(@appendYear)
				and CRESTAVintage=''
      			order by 1,2
      	else if @DeprecatedCRESTAZones=0 and @adminLevel2=1	
			declare curs13 cursor for
				SELECT  len(WCCCODES.LOCATOR) , WCCCODES.LOCATOR, dbo.trim(substring(WCCCODES.LOCATOR,5,99)) 
				as name ,CRESTAVintage,CRESTA
				FROM WCCCODES JOIN STATEL on left(WCCCODES.FIPS,2) = STATEL.STATE_FIPS and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID 
				where WCCCODES.COUNTRY_ID = @CID AND abs(mapi_stat) = @mapistat -- and WCCCODES.LOCATOR not like '%' + dbo.trim(@appendYear)
				and CRESTAVintage=''
      			order by 3 
      	else
			declare curs13 cursor for
				SELECT  len(WCCCODES.LOCATOR) , WCCCODES.LOCATOR, 
				case left(substring(STATE, charindex(  '-',STATE  ) + 1, len (STATE)), 1) 
				when ' ' then dbo.trim(substring(STATE, charindex(  '-',STATE ) + 2, len (STATE)))
				else dbo.trim(STATE) end as name ,CRESTAVintage,CRESTA
				FROM WCCCODES JOIN STATEL on left(WCCCODES.FIPS,2) = STATEL.STATE_FIPS and STATEL.COUNTRY_ID = WCCCODES.COUNTRY_ID 
				where WCCCODES.COUNTRY_ID = @CID AND abs(mapi_stat) = @mapistat  --and WCCCODES.LOCATOR not like '%' + dbo.trim(@appendYear)
				and CRESTAVintage<>''
      			order by 1,2 
		open curs13
		fetch curs13 into  @l, @loc,@name,@crestaVintage,@crestaZone
		while @@fetch_status=0
		begin	
			if @mapistat=10--SubZone
				select @crestaZone= SubCRESTA from WccCodes where locator=@loc
			else
			begin
				if (charindex('*',@loc)>0)  set @displayNote=1;
				set @crestaZone=substring (@loc,6,2)
			end
			if @crestaZone=''  set @crestaZone='00'
			
				if (charindex('*',@loc)=0 and @adminLevel2=0 ) or( (charindex('*',@loc)>0 and len(substring(@loc,charindex('*',@loc),len(@loc)-charindex('*',@loc)+1))>2) and (@adminLevel2=1))
				begin
					if @i = 0  
						set @html = @html + @htmlTR  + @crlf;
			
					--process the locator
					--exec absp_processTheLocator @results out, @CID, @LOC;
					if  @adminLevel2=0
					begin
						set @html = @html +  '<TD width=16%>'+  @LOC  + '</td>' + @crlf ;
						set @html = @html +  '<TD width=17%><p align=center style=''text-align:center''>' + dbo.trim(@crestaZone) + '</td>' + @crlf;
						if substring(@name,1,9)='Zone Code' set @name=replace(@name,'Zone Code','CRESTA Zone');
					end
					set @html = @html +  '<TD width=17%>' + dbo.trim(@name) + '</td>' + @crlf;
						
					
					if @DeprecatedCRESTAZones=1			
						set @html = @html +  '<TD width=17%><p align=center style=''text-align:center''>' + dbo.trim(@crestaVintage) + '</td>' + @crlf;
					set @i = @i + 1;

					set @html = @html + @htmlTRN  + @crlf;
	  
					insert into ##TMP_LOC_HTML values(@html );
					set @html=''
			end
            fetch curs13 into  @l, @loc,@name,@crestaVintage,@crestaZone
		end ;
		close curs13
		deallocate curs13
		
	end
--
	if @i > 0 
	begin
		while @i < 3 
		begin
			set @html = @html + '<TD width=16%> .</td>' + @crlf;
			set @html = @html +'<TD width=17%> .</td>' + @crlf;
			set @i = @i + 1;
		end;
		set @html = @html + @htmlTRN  + @crlf ;
	end;
	
	set @html = @html + @htmlTableN;
	if @displayNote=1 and @adminLevel2=0
		set @html = @html + '<BR><B>Note:  CRESTA Zones may also be specified as a single digit (i.e. no leading zero) for CRESTA Zones that are less than 10.</B>';

	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @CID + @suffix + '#support-locators >  Go to Supported Geocoding Levels</a></H3>';
	set @html = @html + '<BR>';
	set @html = @html + '<H3><a href=' + @TOCName + '>  Go to Table of Contents</a></H3>';
	
	set @html = @html + @crlf + @htmlEnd;
	
	insert into ##TMP_LOC_HTML values(@html );
        set @html=''
        
	--Write to file
	--set @fName= @filename + '_' + dbo.trim(substring(dbo.trim(@replaceYear),2,len(dbo.trim(@replaceYear)))) + '.html'
	set @fName= @filename  + '.html'
	exec absp_Util_UnloadData 'Q','select line from ##TMP_LOC_HTML order by line_no',@fName
	if OBJECT_ID('tempdb..##TMP_LOC_HTML','u') is not null drop table ##TMP_LOC_HTML
					
end try
begin catch
	exec absp_Util_DeleteFile @fileName 
	if OBJECT_ID('tempdb..##TMP_LOC_HTML','u') is not null drop table ##TMP_LOC_HTML
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch