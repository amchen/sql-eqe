if exists(select * from sysobjects where id = object_id(N'absp_APortfolioStats') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_APortfolioStats
end
 go
create procedure absp_APortfolioStats @AportKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the number of pports and rports under a given accumulation portfolio.

Returns:       A single result set with two values:
1. PPORT_CNT = The number of pports under the given aport
2. RPORT_CNT = The number of rports under the given aport
3. MT_RPORT_CNT = The number of multi-treaty rports under the given aport

====================================================================================================
</pre>
</font>
##BD_END

##PD  @AportKey ^^  The key of the aport node for which the status is to be identified. 

##RS PPORT_CNT ^^ The count of pports under the given aport.
##RS RPORT_CNT ^^ The count of rports under the given aport.
##RS MT_RPORT_CNT ^^ The count of multi-treaty rports under the given aport.
*/
begin

   set nocount on
   
  -- this query gets all the stats you need
   declare @pportCount int
   declare @rportCount int
   declare @mt_rportCount int
   select   @pportCount = count(*)  from APORTMAP where APORT_KEY = @AportKey and CHILD_TYPE = 2
   select   @rportCount = count(*)  from APORTMAP where APORT_KEY = @AportKey and CHILD_TYPE = 3
   select   @mt_rportCount = count(*)  from APORTMAP where APORT_KEY = @AportKey and CHILD_TYPE = 23
  -- return the  answers
   select   @pportCount as PPORT_CNT, @rportCount as RPORT_CNT, @mt_rportCount as MT_RPORT_CNT
end




