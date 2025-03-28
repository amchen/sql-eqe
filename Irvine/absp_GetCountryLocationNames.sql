if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetCountryLocationNames') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetCountryLocationNames
end
 go
create procedure absp_GetCountryLocationNames @country_id char(3)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:   MSSQL
Purpose:

This procedure creates a list of country specific location names

Returns:	 list of country specific location names.

====================================================================================================
</pre>
</font>
##BD_END
##PD	@country_id ^^ the country_id of the country to be searched. 
*/
as
begin
 set nocount on
	if exists (select * from tempdb.dbo.sysobjects o where 	o.xtype in ('U') and name like '#TMPCNTRYLOC%')
	begin
	drop Table #TMPCNTRYLOC
	end
	create table #TMPCNTRYLOC(country_id char(3) COLLATE SQL_Latin1_General_CP1_CI_AS, country char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, codeValue char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, pbndy1 char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, pbndy2 char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, postalCode char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, zone char(50) COLLATE SQL_Latin1_General_CP1_CI_AS)
	insert into #TMPCNTRYLOC values ('00','United States', 'City', 'State', 'County',  'Zip', '');
	insert into #TMPCNTRYLOC values ('01','Canada', 'City', 'Province', 'Cresta Zone', 'Postal Code', ''); 
	insert into #TMPCNTRYLOC values ('02','Japan', 'City', 'Cresta Zone', 'Prefecture',  'Postal Code', '');  
		
	insert into #TMPCNTRYLOC
	select distinct rtrim(datavint.country_id), rtrim(datavint.country), 'City',
	case substring(rtrim(bndry1Name), len(rtrim(bndry1Name))-2, 3) 
		   when 'ies' then substring(rtrim(bndry1Name),1,len(rtrim(bndry1Name))-3) + 'y' 
		   else case substring(rtrim(bndry1Name), len(rtrim(bndry1Name)), len(rtrim(bndry1Name))) 
			when 's' then substring(rtrim(bndry1Name), 1, len(rtrim(bndry1Name))-1)
			else rtrim(bndry1Name) end
		   end,
		   case substring(rtrim(bndry2Name), len(rtrim(bndry2Name))-2, 3) 
		   when 'ies' then substring(rtrim(bndry2Name),1,len(rtrim(bndry2Name))-3) + 'y' 
		   else case substring(rtrim(bndry2Name),  len(rtrim(bndry2Name)), len(rtrim(bndry1Name))) 
			when 's' then substring(rtrim(bndry2Name), 1, len(rtrim(bndry2Name))-1)
			else rtrim(bndry2Name) end
		   end,
		   'Postal Code',
		   subrgnlist
	 from (datavint inner join country on country.country_id = datavint.country_id) 
		  inner join EXPREGNS on datavint.country_id = EXPREGNS.country_id and EXPREGNS.data_level = '1' 
	
	if not exists(select 1 from #TMPCNTRYLOC where country_id = @country_id) begin
		insert into #TMPCNTRYLOC values (@country_id, @country_id, 'City', 'PBoundary1', 'PBoundary2', 'Postal Code', 'Cresta Zone/Zone Code')
		update #TMPCNTRYLOC set #TMPCNTRYLOC.COUNTRY = ltrim(rtrim(COUNTRY.COUNTRY)) FROM #TMPCNTRYLOC, COUNTRY where COUNTRY.COUNTRY_ID = #TMPCNTRYLOC.COUNTRY_ID and #TMPCNTRYLOC.COUNTRY_ID = @country_id;
	end

	select * from #TMPCNTRYLOC where country_id = @country_id
	
end
