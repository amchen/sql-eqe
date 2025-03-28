if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getCountriesbyGroup') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getCountriesbyGroup
end

go

create procedure absp_getCountriesbyGroup @countryGrpId int ,@contGrpKey int = 1 ,@contGrpType int = 0 ,@active char(1) = 'Y' 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MS SQL
Purpose:

This procedure will return a single resultset, which contain all region groups under the given
country group Id sorted by region groups name.

Returns:       Single result set containing the following fields:

1. continent
2. geoAreaGroup
3. geoArea
4. geoName
5. continentType
6. active
====================================================================================================
</pre>
</font>
##BD_END

##PD  @countryGrpId 	^^  The Country Group Id under which the region groups are to be fetched. 
##PD  @contGrpKey 	^^  The Group Key of the continent under which the region group belongs to. Default value 1 .
##PD  @contGrpType 	^^  The type of the group key of the continent.Default value 0.
##PD  @active 		^^  A single character 'Y' designating Active and 'N' designating 'Non Active'.Default value 'Y'.


##RS  continent 	^^  The Group Key of the continent the country belongs to.
##RS  geoAreaGroup 	^^  The Country Group Id under which the region groups are being fetched.
##RS  geoArea 		^^  The region group Id of the region groups.
##RS  geoName 		^^  The name of region groups
##RS  continentType 	^^  The type of continent group.
##RS  active 		^^  A single character 'Y' designating Active and 'N' designating 'Non Active'.

*/
begin
 
   set nocount on
   
  select distinct  @contGrpKey as Continent, C_RRGNID.CLIST_KEY as geoAreaGroup, C_RRGNID.RRGNGRP_ID as geoArea, RRGNGRPS.NAME as geoName, @contGrpType as continentType, @active as active from
   C_RRGNID as C_RRGNID,EXPREGNS as EXPREGNS,RREGIONS as RREGIONS,RRGNGRPS as RRGNGRPS,RRGNLIST as RRGNLIST where
   C_RRGNID.CLIST_KEY = @countryGrpId and
   C_RRGNID.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and
   RRGNLIST.COUNTRY_ID = EXPREGNS.COUNTRY_ID and
   RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and
   C_RRGNID.RRGNGRP_ID = RRGNGRPS.RRGNGRP_ID and
   RRGNLIST.COUNTRY_ID <> 'X' order by
   RRGNGRPS.NAME asc
end


--exec absp_getCountriesbyGroup -2 ,1,0 ,Y

