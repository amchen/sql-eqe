if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_getAllGeoAreas') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getAllGeoAreas
end

go
create procedure absp_getAllGeoAreas as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return multiple resultsets as follows :-

1st result set returns the number of continent groups
2nd result set returns the number of continental regions under the base continent group
3rd result set returns the base continent group name
The successive result sets returns each continental region under the base continent group
and all the corresponding reinsurance regions respectively.

Returns:       
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

##RS  continent 	^^  The Group Key of the continent the country belongs to.
##RS  geoAreaGroup 	^^  The Country Group Id under which the countries are being fetched.
##RS  geoArea 		^^  The region group Id the countries belong to.
##RS  geoName 		^^  The name of the group of regions
##RS  continentType 	^^  The type of the group key of the continent.
##RS  active 		^^  A single character 'Y' designating Active and 'N' designating 'Non Active'.

*/
begin

  set nocount on
  -- get the continent count 
   declare @curs1_contGrpId int
   declare @curs1_contGrpType int
   declare @curs1_ACTIVE char(1)
   declare @curs1 cursor
   declare @curs2_CGRP_KEY int
   declare @curs2_countryGrpId int
   declare @curs2 cursor
   
   select   0 AS continent, 0 AS geoAreaGroup, 0 AS geoArea, 'continentCount' AS geoName, count(*) AS continentType, 'Y' AS ACTIVE 
     from CONGROUP
   
  -- get the countryGrp count
   select   0 AS continent, 0 AS geoAreaGroup, 0 AS geoArea, 'countryGrpCount' AS geoName, count(*) AS continentType, 'Y' AS active 
     from CGRPLIST
     
  -- return geoAreas in hierarchical order for each continent, each countryGrp 
  
    --select CGRP_KEY as contGrpId, CGRP_DESC, CGRP_TYPE as contGrpType, ACTIVE from CONGROUP do
    
    -- continent data for each continent 
   set @curs1 = cursor fast_forward for select CGRP_KEY ,CGRP_TYPE ,ACTIVE from CONGROUP
   open @curs1
   fetch next from @curs1 into @curs1_contGrpId,@curs1_contGrpType,@curs1_ACTIVE
   while @@fetch_status = 0
   begin
      select   CGRP_KEY AS continent, 0 AS geoAreaGroup, 0 AS geoArea, CGRP_DESC AS geoName, CGRP_TYPE AS continentType, ACTIVE = CASE ACTIVE WHEN 'Y' THEN 1 ELSE 0 END from CONGROUP where CGRP_KEY = @curs1_contGrpId
    
      -- countryGrp data for each countryGrp
      set @curs2 = cursor fast_forward for select CGRP_KEY,CLIST_KEY  from CGRPLIST where  CGRP_KEY = @curs1_contGrpId
      open @curs2
      fetch next from @curs2 into @curs2_CGRP_KEY,@curs2_countryGrpId
      while @@fetch_status = 0
      begin
         select   CGRP_KEY AS continent, CLIST_KEY AS geoAreaGroup, 0 AS geoArea, CLIST_DESC AS geoName, @curs1_contGrpType AS continentType, @curs1_ACTIVE AS active from CGRPLIST where
         CGRP_KEY = @curs1_contGrpId and CLIST_KEY = @curs2_countryGrpId order by geoName asc
      -- list of geoArea data per countryGrp    
         execute absp_getCountriesbyGroup @curs2_countryGrpId,@curs1_contGrpId,@curs1_contGrpType,@curs1_ACTIVE
         fetch next from @curs2 into @curs2_CGRP_KEY,@curs2_countryGrpId
      end
      close @curs2
      deallocate @curs2
      fetch next from @curs1 into @curs1_contGrpId,@curs1_contGrpType,@curs1_ACTIVE
   end
   close @curs1
   deallocate @curs1
end
