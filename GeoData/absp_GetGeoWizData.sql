if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetGeoWizData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetGeoWizData
end
go

create procedure absp_GetGeoWizData @selectedCountry char(3), @selectedState varchar(100), @countyWhere varchar(1000) = '', @cityWhere varchar(1000) = '', @zipWhere varchar(1000) = '', @selectAll bit = 1
as

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console" >
====================================================================================================
DB Version:    ASA
Purpose:       This procedure returns a result set for GeoCoding Selection Wizard based on 
			   the given search criteria from Tables like ZIPCT, ZIPCT01, ZIPCT02.
     
Returns:       Search result.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  selectedCountry 	^^ Country given as search criteria.
##PD  selectedState 	^^ State given as search criteria.
##PD  countyWhere 		^^ Where clause for county filter.
##PD  cityWhere 	    ^^ Where clause for City filter.
##PD  zipWhere 			^^ Where clause for Zip filter.

##RS  STATE	    ^^ State.
##RS  COUNTY	^^ County.
##RS  FIPS	    ^^ FIPS.
##RS  CITY	    ^^ City.
##RS  ZIP_CODE	^^ Zip Code.

*/

begin
declare @city char(100)
declare @county char(100)
declare @zip char(100)
declare @zipTable char(10)
declare @innerJoin varchar(1000)
declare @stateWhere varchar(1000)
declare @colNames varchar(1000)
declare @andString char(5)
declare @indx int
declare @query varchar(max)


exec absp_Util_Log_Info '--------- START -----------', 'absp_GetGeoWizData'
set @zipTable = 'ZIPCT'
set @stateWhere = ''
set @innerJoin = ''
set @indx = 0
set @colNames = ''
set @andString = ''

if(@selectedCountry = '01' or @selectedCountry = '02') 
	set @zipTable = ltrim(rtrim(@zipTable)) + ltrim(rtrim(@selectedCountry))

set @colNames = ltrim(rtrim(@zipTable)) + '.STATE,  COUNTY, FIPS'

if(@selectAll = 0) 
begin
	if(len(@cityWhere) > 0) 
		set @colNames = @colNames + ', CITY'

	if(len(@zipWhere) > 0) 
		set @colNames = @colNames + ', ZIP_CODE'

end
else 
	set @colNames = @colNames + ', CITY , ZIP_CODE' 

	
set @query = 'SELECT distinct TOP(2000) ' + @colNames + ' FROM  ' + ltrim(rtrim(@zipTable))


if(len(@selectedState) > 0 ) 
begin
	
	if(charindex('*', @selectedState) > 0) 
	begin
		set @innerJoin = ' INNER JOIN STATEL ON STATEL.STATE_2 = ' + ltrim(rtrim(@zipTable)) + '.STATE'
		set @stateWhere = @stateWhere + ' STATEL.STATE LIKE ''' + replace(@selectedState,'*','%') + ''''		
	end
	else
		set @stateWhere = 'STATE = ''' + @selectedState + ''''
end

set @query = @query + @innerJoin + ' where ' 

if(len(@stateWhere) > 0) 
begin
	set @query = @query + @andString + @stateWhere
	set @andString = ' AND '
end

if(len(@countyWhere) > 0) 
begin
	set @query = @query + @andString + ltrim(rtrim(@countyWhere))
	set @andString = ' AND '
end

if(len(@cityWhere) > 0) 
begin
	print @cityWhere
	set @query = @query + @andString + ltrim(rtrim(@cityWhere))
	set @andString = ' AND '
end

if(len(@zipWhere) > 0) 
	set @query = @query + @andString + ltrim(rtrim(@zipWhere))



set @query = @query + ' order by ' + @colNames
print @query

execute( @query )
exec absp_Util_Log_Info '--------- END -----------', 'absp_GetGeoWizData'

END
