if EXISTS(select * FROM sysobjects WHERE id = object_id(N'absp_GetGeoWizDataForDCountry') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_GetGeoWizDataForDCountry
end
 GO
create procedure absp_GetGeoWizDataForDCountry 
@countryId char(3),
@crestaZoneClause varchar(300) = '', 
@cityClause varchar(300) = '',
@postCodeClause varchar(300) = '',
@pbndy1Clause varchar(300) = '',
@pbndy2Clause varchar(300) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns cresta zones/zone codes, pbndy1 name, pbndy2 name and postal code given
countryId, or/and cresta zone where clause or/and  city where clause or/and postcode where clause


Returns:	cresta zones/zone codes, pbndy1 name, pbndy2 name and postal code

====================================================================================================
</pre>
</font>
##BD_END

##PD  countryId ^^  country Id.
##PD  @crestaZoneClause ^^  the cresta zone where clause.
##PD  @cityClause ^^  The city where clause.
##PD  @postCodeClause ^^  The post code where clause.
##PD  @pbndy1Clause ^^  The p-boundary1 clause
##PD  @pbndy1Clause ^^  The p-boundary2 clause

*/
AS
begin
 
set nocount on
declare @sql varchar(max)


set @sql = 'select distinct top(2000) crestazone, code_value,  pbndy1name , pbndy2Name, case pseudo_PC when ''99999'' then ''N/A'' else pseudo_PC end as postCode ' +
			'from GEODATA ' +
			'where country_id = ''' + @countryId + ''''
-- city entered
if len(@cityClause) > 0 
begin
	set @sql = @sql + ' and mapi_stat = 7 '
    if @cityClause != 'All***' 
	begin
			set @sql = @sql + ' and ' + @cityClause
	end  
end
-- postal code entered
else if len(@postCodeClause) > 0 
begin
	set @sql = @sql +
	' and ( ' +
			  ' GEO_STAT = 202 or' + 
              ' GEO_STAT = 203 or' +
			  ' GEO_STAT = 204 or' +
			  ' (GEODATA.COUNTRY_ID <> ''IRL'' and GEO_STAT = 205) or' +
			  ' GEO_STAT = 206 or' +
			  ' (mapi_stat = 8 and  right(ltrim(rtrim(code_value)),2) = ''PC'')' +
          ')'
		if @postCodeClause != 'All***' 
		begin
			set @sql = @sql + ' and ' + @postCodeClause
		end
end
-- cresta zone is selected
if len(@crestaZoneClause) > 0
begin 
   set @sql = @sql + ' and ' + @crestaZoneClause
end

if len(@pbndy1Clause) > 0
begin
	set @sql = @sql + ' and ' + @pbndy1Clause
end

if len(@pbndy2Clause) > 0
begin
	set @sql = @sql + ' and ' + @pbndy2Clause
end

set @sql = @sql + ' order by 1,2,3,4,5 '
--select @sql
execute (@sql)
end 