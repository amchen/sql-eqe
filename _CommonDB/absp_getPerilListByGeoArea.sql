if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getPerilListByGeoArea') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getPerilListByGeoArea
end

go

create procedure -- ====================================================================
-- This procedure returns three result sets each containing a different level of the layer exclusions tree.peril lookups
-- Set 1 is the continent level, Set 2 is the continent group and Set 3 is the detail level.
-- ====================================================================
absp_getPerilListByGeoArea as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MS SQL
Purpose:	This procedure returns three resultsets each containing the peril information at the 
following levels:-
1. base continent group level
2. individual continent level
3. regional group level


Returns:       Multiple result sets including the following fields at the above mentioned levels:-
1. Base continent group key
2. Country group id 
3. Regional group id
4. Peril name
5. Peril Id 
====================================================================================================

</pre>
</font>
##BD_END

##RS	contGrpId	^^ Base continent group key
##RS	countryGrpId	^^ Country group id
##RS	geoAreaId	^^ Regional group id
##RS	peril_name	^^ Peril name
##RS	peril_id	^^ Peril Id

*/
begin

   set nocount on
   
   -- Create a temp table to map peril_id to rregion group id.
	select distinct t1.rrgngrp_id, t3.country_ID country_id , t4.peril_id peril_id, t5.perildisplayname into #TMP1 from rrgngrps t1 
		inner join RREGIONS t2 on t1.rrgngrp_id = t2.rrgngrp_id 
		inner join rrgnlist t3 on t2.rrgn_key = t3.rrgn_key
		inner join mregnmem t4 on t4.country_id = t3.country_id 
		inner join ptl t5 on t5.peril_id = t4.peril_id and t5.in_list = 'Y' and trans_id = 67
		order by country_id, peril_id

	-- This procedure will create 3 resultset which will be used by the Layer Exclusion dialog
	-- The first resultset will be used for the top level node in the tree view (of Layer exclusion)
	select distinct  CONGROUP.CGRP_KEY as contGrpId, 0 as countryGrpId, 0 as geoAreaId, perildisplayname as peril_name , #tmp1.peril_id 
		from C_RRGNID
		inner join CGRPLIST on CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY 
		inner join CONGROUP on CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY
		inner join #tmp1 on #tmp1.rrgngrp_id = C_RRGNID.crrgn_key
		order by CONGROUP.CGRP_KEY asc,perildisplayname asc

	-- The next resultset will be for the continent group level (i.e. second level in the treeview).
	select distinct  CONGROUP.CGRP_KEY as contGrpId, CGRPLIST.clist_key as countryGrpId, 0 as geoAreaId, 
		perildisplayname as peril_name , #tmp1.peril_id 
		from C_RRGNID
		inner join CGRPLIST on CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY 
		inner join CONGROUP on CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY
		inner join #tmp1 on #tmp1.rrgngrp_id = C_RRGNID.crrgn_key
		order by countryGrpId asc,perildisplayname asc

	-- This resultset is for the country level nodes in the treeview.
	select distinct  CONGROUP.CGRP_KEY as contGrpId, CGRPLIST.clist_key as countryGrpId, #tmp1.rrgngrp_id as geoAreaId,
		perildisplayname as peril_name , #tmp1.peril_id 
		from C_RRGNID
		inner join CGRPLIST on CGRPLIST.CLIST_KEY = C_RRGNID.CLIST_KEY 
		inner join CONGROUP on CONGROUP.CGRP_KEY = CGRPLIST.CGRP_KEY
		inner join #tmp1 on #tmp1.rrgngrp_id = C_RRGNID.crrgn_key
		order by contGrpId, countryGrpId, geoAreaId ,perildisplayname
end



