exec absp_MakeWccHtml
	@country_id = ' ' ,
	@directory = 'D:\Temp\GeoHelp'



select * from RRgnList
where Country_ID='aut' 

select Code_Value,CrestaZone,* from GeoData
where Country_ID='aut' 
and Code_Value=CrestaZone

select Code_Value,SUBSTRING(Code_Value,5,99),* from GeoData
where Country_ID='ESP' 
and Code_Value like 'ESP_%'
and Geo_Stat in (452)

select Code_Value,SUBSTRING(Code_Value,5,99) from GeoData
where Country_ID='ESP' 
and Code_Value like 'ESP_%'
and Geo_Stat in (205)

select Code_Value,CrestaZone,* from GeoData
where Country_ID='bel' 
and Mapi_Stat in (8,6)

select Code_Value,CrestaZone,* from GeoData
where Country_ID='dnk' 
and Mapi_Stat in (8,6)

select * from datavint






