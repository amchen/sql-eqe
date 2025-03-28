if exists(select * from sysobjects where id = object_id(N'absp_GenerateRegionEQETableForSC') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateRegionEQETableForSC
end

go


create procedure absp_GenerateRegionEQETableForSC
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:        This procedure returns resultset which contains countryKey, geocodelevelId, region code
		and region description from WCCODES for mapi_stat =8.

Returns:        A single resultset. 

====================================================================================================

</pre>
</font>

##BD_END 

##RS  ProviderId ^^  The provider id.
##RS  CountryId ^^  The countryKey of WCCCODES.
##RS  GeocodeLevelId ^^  Code that defines the level of geocoding.
##RS  RegionCodeChar ^^  The region Code
##RS  RegionDescription ^^  The region description 

*/
as
begin

create table #temp_regioneqe (
															provider_id int, 
															country_id char(3)  COLLATE SQL_Latin1_General_CP1_CI_AS, 
															geocodelevelid int, 
															regioncodechar char(80)  COLLATE SQL_Latin1_General_CP1_CI_AS, 
															regiondescription varchar(1000)  COLLATE SQL_Latin1_General_CP1_CI_AS
															)

create table #temp_wcccodes (
															locator char(40) COLLATE SQL_Latin1_General_CP1_CI_AS, 
															country_id char(3) COLLATE SQL_Latin1_General_CP1_CI_AS, 
															fips char(5)  COLLATE SQL_Latin1_General_CP1_CI_AS
														)

create index temp_wcccodes_I1 on #temp_wcccodes (fips)
create index temp_wcccodes_I2 on #temp_wcccodes (country_id)

insert into #temp_wcccodes 
		select distinct ltrim(rtrim(locator)), ltrim(rtrim(country_id)) , fips  from wcccodes 
				where mapi_stat = 8 and country_id not in ('00', 'JAM', 'PRT')

-- All countries other than US, JAM and PRT

insert into #temp_regioneqe 
	select distinct 1, t1.country_id, 8, t1.locator, ltrim(rtrim(t2.name)) as name from #temp_wcccodes t1 
						inner join rrgnlist t2 on t2.fips = t1.fips and t1.country_id = t2.country_id

-- Get the region description for JAM and PRT from WCCCODES

insert into #temp_regioneqe 					

	select 1, ltrim(rtrim(country_id)), 8, ltrim(rtrim(replace(dbo.trim(locator), '*2002', ''))) as locator, ltrim(rtrim(zone_name)) from wcccodes 
						where country_id in('jam', 'prt') and zone_name <> '< >'


-- Get the state code and description from STATEL this will include Puerto Rico as state

insert into #temp_regioneqe 					

	select 1, ltrim(rtrim(country_id)), 8, ltrim(rtrim(state_2)) as state_2, ltrim(rtrim(state)) as state from statel where country_id in ('00','01')


-- Get the region description for Puerto Rico from WCCCODES 

insert into #temp_regioneqe 					

	select 1, ltrim(rtrim(country_id)), 8, ltrim(rtrim(replace(dbo.trim(locator), '*2002', ''))) as locator, ltrim(rtrim(zone_name)) from wcccodes 
		where country_id = '00' and zone_name <> '< >' 


select provider_id as ProviderId, countrykey as CountryId, 0, GeocodeLevelId, NULL, RegionCodeChar,	RegionDescription
	from #temp_regioneqe, country
	where #temp_regioneqe.country_id = country.country_id
	order by country.countrykey, RegionCodeChar

end
