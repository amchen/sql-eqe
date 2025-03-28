if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MakeWccHtml') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWccHtml
end
go

create procedure absp_MakeWccHtml  @country_id varchar(3)=' ',
    				   @directory varchar(255) ='c:\\tmp\\NewHtml'

as
begin
	--
	--  directory       is where you want to place the generated HTML files (ie. "c:\html")
	--  country_id      is a specific 3-char country code to generate (ie. 'BEL')
	--                  Default means do it for all countries in the country table
	--
	if exists (select 1 from SYS.TABLES where NAME = '#COUNTRY_SUM')  
		drop table #COUNTRY_SUM;
	 

   
	create table #COUNTRY_SUM (
		COUNTRYKEY int,
		COUNTRY_ID  varchar(3)  COLLATE SQL_Latin1_General_CP1_CI_AS,
		COUNTRY varchar(50)  COLLATE SQL_Latin1_General_CP1_CI_AS,
		CRESTA_ZONE  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		ZONE_CODE  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		COMMUNE  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		MULTI_YEAR  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		CITIES  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		ADMIN_LEVEL_2 varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		POST2  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		POST3  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		POST4  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		POST5  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		POST6  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		MUNICIPAL_CODE varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		DISTRICT varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		LATLONG_OK  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS,
		WCCIMPORT  varchar(10) default '&nbsp'  COLLATE SQL_Latin1_General_CP1_CI_AS
	);

	    exec absp_MakeCountrySummaryHtmlPages  @directory, 0 ; -- run in legacy mode, do not create COUNTRY_SUM since it has been created 
	    exec absp_MakeWccHtmlToc @directory ;
	    exec absp_MakeWccHtmlPages @country_id,@directory ;
end