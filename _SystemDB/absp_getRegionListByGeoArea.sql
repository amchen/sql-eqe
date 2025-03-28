if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getRegionListByGeoArea') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getRegionListByGeoArea
end

go

create procedure -- =========================================================
-- Return the list of all Regions for all Countries.   Used by the Layer Exclusions panel.
-- =========================================================
absp_getRegionListByGeoArea as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure returns a single result set containing the list of all Regions for all
region groups grouped by geographical area.

Returns:       Single result set containing the following fields:

1. Continent group id
2. Country group id
3. Geographical area id
4. Region name
5. Region ID


====================================================================================================

</pre>
</font>
##BD_END

##RS	contGrpId	^^ Continent group id
##RS	countryGrpId	^^ Country group id
##RS	geoAreaId	^^ Geographical area id
##RS	rrgn_name	^^ Region name
##RS	rrgn_key	^^ Region ID

*/
begin

   set nocount on
   
   select distinct  0 as contGrpId, 0 as countryGrpId, RREGIONS.RRGNGRP_ID as geoAreaId, RREGIONS.NAME as rrgn_name, RREGIONS.RRGN_KEY as RRGN_KEY from
   RREGIONS as RREGIONS,RRGNGRPS as RRGNGRPS where
   RRGNGRPS.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and RREGIONS.NAME <> 'All Regions' order by
   geoAreaId asc,RREGIONS.NAME asc
end



