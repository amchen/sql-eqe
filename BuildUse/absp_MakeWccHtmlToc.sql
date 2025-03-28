if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtmlToc') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtmlToc
end
go

create procedure absp_MakeWccHtmlToc
    @directory varchar(255) = 'c:\\html'
as
begin try
	--
	--  directory is where you want to place the generated HTML files (ie. "c:\html")
	--

	set nocount on
	print 'Start absp_MakeWccHtmlToc'

	declare @path varchar(240);
	declare @suffix varchar(5);
	declare @filename varchar(255);
	declare @html varchar(8000);
	declare @htmlHeader varchar(256);
	declare @htmlBody varchar(256);
	declare @htmlEnd varchar(256);
	declare @htmlH2 varchar(10);
	declare @htmlH2N varchar(10);
	declare @htmlTable varchar(100);
	declare @htmlTR varchar(10);
	declare @htmlTRN varchar(10);
	declare @htmlIMG varchar(10);
	declare @htmlIMGN varchar(10);
	declare @crlf varchar(2);
	declare @i int;
	declare @cntry varchar(50)
	declare @link varchar(8000)
	declare @str varchar(max)
	--
	set @path = @directory + '\\';
	set @suffix = '.html';
	--

	--create temp table
	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML
	create table ##TMP_HTML (line_no int identity not null,line varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS)

	set @crlf = CHAR(10) + CHAR(13);
	set @htmlH2 = '<H2>';
	set @htmlH2N = '</H2>';
	set @htmlIMG = '<img src="';
	set @htmlIMGN = '.gif">';
	--
	set @htmlTR = '<TR>';
	set @htmlTRN = '</TR>';
	set @htmlTable = '<TABLE BORDER CELLSPACING=1 CELLPADDING=7 WIDTH=95%>';
	--
	set @htmlHeader = '<HTML>' + @crlf + '<HEAD>' + @crlf + '<TITLE>Geocoding Levels by Country</TITLE>' + @crlf + '</HEAD>' + @crlf ;
	set @htmlBody = '<BODY background=backgnd.gif>' + @crlf ;
	set @htmlEnd = '</TABLE></BODY></HTML>';
	--
	set @filename = @path + '_TOC.html';
	--
	set @html = @htmlHeader;
	set @html = @html + @htmlBody;
	set @html = @html + @htmlH2 ;
	set @html = @html + 'Summary of Geocoding Levels by Country';
	set @html = @html + @htmlH2N + @crlf;
	set @html = @html + '<H3><a href=CountrySummary.html>Summary of Geocoding Levels</a></H3>' + '<BR>'+  @crlf;
	set @html = @html + @htmlH2 ;
	set @html = @html + 'Geocoding Levels by Country';
	set @html = @html + @htmlH2N + @crlf;
	set @html = @html + @htmlTable + @crlf ;

	insert into ##TMP_HTML values(@html)

	--
	set @i = 0;
	declare curs2 cursor for
		SELECT '<TD WIDTH="25%"><a href='+ dbo.trim(ABBREV) + '.html> ' + dbo.trim(country) + '</a></TD>', dbo.trim(country)
	    	FROM country
	    	where COUNTRYKEY > 4 and IsLicensed = 'Y' and Country_ID not in ('JPN')
	    	ORDER BY country
	open curs2
	fetch curs2 into @link, @cntry
	while @@fetch_status=0
	begin
	    --print 'Building TOC for ', CNTRY, '  ';
	    set @html=''
	    if @i = 0

		set @html = @html + @htmlTR  + @crlf ;

	    set @html = @html +  @link  + @crlf ;
	    set @i = @i + 1;
	    if @i = 4
	    begin
		set @html = @html + @htmlTRN  + @crlf ;
		set @i = 0;
	    end
	    insert into ##TMP_HTML values(@html)
	    fetch curs2 into @link, @cntry
	end ;
	close curs2
	deallocate curs2

	set @html=''

	if (@i > 0)
	begin
		while (@i < 4)
		begin
		    set @html = @html + '<TD width=25%>&nbsp</td>' + @crlf ;
		    set @i = @i + 1;
		end;
		set @html = @html + @htmlTRN  + @crlf ;
	end;

	set @html = @html  + @htmlEnd ;
	insert into ##TMP_HTML values(@html)

	--Write to file
	exec absp_Util_UnloadData 'Q','select line from ##TMP_HTML order by line_no',@fileName

	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML

end try

begin catch
	exec absp_Util_DeleteFile @fileName
	if OBJECT_ID('tempdb..##TMP_HTML','u') is not null drop table ##TMP_HTML
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
