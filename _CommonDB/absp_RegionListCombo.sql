if exists(select * from SYSOBJECTS where ID = object_id(N'absp_RegionListCombo') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_RegionListCombo
end
go

create procedure absp_RegionListCombo @progKey int 
as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure returns a single resultset containing region group name and Id for all 
available exposure regions based on country_id.

Returns:       Single result set containing the following fields:

1. Region group name
2. Region group ID

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@progKey 	^^ Program Key.(Unused parameter)
##RS	@NAME		^^ Region group name
##RS	@RRGNGRP_ID	^^ Region group ID
*/
begin

   set nocount on
   
   select   NAME AS NAME, RRGNGRP_ID AS RRGNGRP_ID from RRGNGRPS where RRGNGRP_ID =
   any(select distinct RRGNGRP_ID from RREGIONS where RRGN_KEY =
   any(select RRGN_KEY from RRGNLIST where COUNTRY_ID =
   any(select distinct COUNTRY_ID from EXPREGNS where COUNTRY_ID <> 'XX'))) order by
   NAME asc
end



