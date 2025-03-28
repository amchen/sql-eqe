if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getLobListByGeoArea') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getLobListByGeoArea
end

go

create procedure -- PSB note 23 Sep 04: we looked at this whilst adding commits to
-- all the procedures.  This one looked spooky and we decided to leave it alone.
-- The issue is he selects then deletes; when would the commit take effect
-- and would it change the resultant 4-part return"?"
-- ====================================================================
-- This procedure returns three result sets each containing a different level of the layer exclusions tree. LOB lookups
-- Set 1 is the continent level, Set 2 is the continent group and Set 3 is the detail level.
-- ====================================================================
absp_getLobListByGeoArea @triggerFlag int = 2 
as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:     MSSQL
Purpose:	This procedure returns three result sets each containing the line of business at the following
levels:-
1. base continent group level
2. individual continent level
3. regional group level


Returns:       Multiple result sets including the following fields at the above mentioned levels:-
1. Base continent group key
2. Country group id
3. Regional group id
4. Line of business name
5. Line of business name Id 
6. Whether common to all countries (Y/N)
====================================================================================================

</pre>
</font>
##BD_END

##RS	contGrpId	^^ Base continent group key
##RS	countryGrpId	^^ Country group id
##RS	geoAreaId	^^ Regional group id
##RS	LOB_NAME	^^ Line of business name
##RS	R_LOB_NO	^^ Line of business Id
##RS	COMMON	^^ Whether common to all countries ('Y' for yes and 'N' for No)

*/
begin
 
   set nocount on
   
   print 'start absp_getLobListByGeoArea() '
  -- ====================================================================
  -- The continent level lookups  (0 for both continent group and region)
  -- ====================================================================
   
	select distinct CONGROUP.CGRP_KEY as CGRP_KEY,0 as CLIST_KEY,0 as RRGNGRP_ID,
					RiskType.NAME as LOB_NAME,RiskType.RiskTypeID as R_LOB_NO,'TRUE'AS COMMON
					from
					C_RRGNID as C_RRGNID,CGRPLIST as CGRPLIST,CONGROUP as CONGROUP,RiskType,
					RREGIONS as RREGIONS,RRGNGRPS as RRGNGRPS,RRGNLIST as RRGNLIST 
					where
					CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY and
					CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY and
					RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and
					RREGIONS.RRGNGRP_ID = RRGNGRPS.RRGNGRP_ID and
					C_RRGNID.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and CONGROUP.ACTIVE = 'Y'
					group by 
					CONGROUP.CGRP_KEY,C_RRGNID.CLIST_KEY,RREGIONS.RRGNGRP_ID,RiskType.NAME,RiskType.RiskTypeID
					order by
					CONGROUP.CGRP_KEY, RiskType.NAME asc
	   
  -- ====================================================================
  -- The continent group level lookups  (0 for continent group only)
  -- ====================================================================

	select distinct CONGROUP.CGRP_KEY as CGRP_KEY,C_RRGNID.CLIST_KEY as CLIST_KEY,0 as RRGNGRP_ID,
					RiskType.NAME as LOB_NAME,RiskType.RiskTypeID as R_LOB_NO,'TRUE'AS COMMON
					from
					C_RRGNID as C_RRGNID,CGRPLIST as CGRPLIST,CONGROUP as CONGROUP,RiskType,
					RREGIONS as RREGIONS,RRGNGRPS as RRGNGRPS,RRGNLIST as RRGNLIST 
					where
					CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY and
					CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY and
					RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and
					RREGIONS.RRGNGRP_ID = RRGNGRPS.RRGNGRP_ID and
					C_RRGNID.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and CONGROUP.ACTIVE = 'Y'
					group by 
					CONGROUP.CGRP_KEY,C_RRGNID.CLIST_KEY,RREGIONS.RRGNGRP_ID,RiskType.NAME,RiskType.RiskTypeID
					order by
					C_RRGNID.CLIST_KEY,RiskType.NAME asc
	   
  -- ====================================================================
  -- The detail level lookups 
  -- ====================================================================
   select CONGROUP.CGRP_KEY as CGRP_KEY, C_RRGNID.CLIST_KEY as CLIST_KEY, RREGIONS.RRGNGRP_ID as RRGNGRP_ID, 
			RiskType.NAME as LOB_NAME,RiskType.RiskTypeID as R_LOB_NO,'TRUE'AS COMMON
			from
			C_RRGNID as C_RRGNID,CGRPLIST as CGRPLIST,CONGROUP as CONGROUP,RiskType,
			RREGIONS as RREGIONS,RRGNGRPS as RRGNGRPS,RRGNLIST as RRGNLIST 
			where
			CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY and
			CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY and
			RREGIONS.RRGN_KEY = RRGNLIST.RRGN_KEY and

			RREGIONS.RRGNGRP_ID = RRGNGRPS.RRGNGRP_ID and
			C_RRGNID.RRGNGRP_ID = RREGIONS.RRGNGRP_ID and CONGROUP.ACTIVE = 'Y'
			group by 
			CONGROUP.CGRP_KEY,C_RRGNID.CLIST_KEY,RREGIONS.RRGNGRP_ID,RiskType.NAME,RiskType.RiskTypeID 
			order by
			RREGIONS.RRGNGRP_ID, RiskType.NAME asc

   print 'stop absp_getLobListByGeoArea() '
end



