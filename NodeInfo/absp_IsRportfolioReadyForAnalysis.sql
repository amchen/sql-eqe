if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsRportfolioReadyForAnalysis') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_IsRportfolioReadyForAnalysis
end
 go

create procedure absp_IsRportfolioReadyForAnalysis @rportKey int 

/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL
Purpose: 

This procedure returns the number of base cases that exist under imported programs underneath the
given rport. (applies to both regular and multi-treaty reinsurance portfolios)

Returns:      The number of case layers under imported programs residing under the given rport.
Zero if none exist.

=================================================================================
</pre> 
</font> 
##BD_END 

##BPD  @rportKey ^^ The key of the rport for which it is to be checked if it requires analysis.

##RD  @countLayers ^^ The number of case layers under imported programs residing under the given rport.

*/
as
begin

   set nocount on
   
   declare @countLayers int
   declare @rport_node_type int
   declare @prog_node_type int
   declare @sql nvarchar(4000)
   declare @count int
  -- Based on the RPORT node type we can find out the program node_type since
  -- we cannot have a Multi-Treaty program under a Regular RPORT and vice-versa
   execute @rport_node_type = absp_Util_GetRPortType @rportKey
  -- How many cases exist in total under this Rportfolio
  -- in all imported programs"?"  If > 0 then you could do
  -- an analysis, else it makes no sense
   if(@rport_node_type = 3)
   begin
	  set @prog_node_type = 7
	  set @sql = 'select @countLayers = count(CSLAYR_KEY) from (RPRTINFO inner join  RPORTMAP on RPRTINFO.RPORT_KEY = RPORTMAP.RPORT_KEY) inner join ((CASELAYR inner join PROGINFO on (CASELAYR.CASE_KEY = PROGINFO.BCASE_KEY )))  on RPORTMAP.CHILD_KEY = PROGINFO.PROG_KEY where PROGINFO.LPORT_KEY > 0 and  RPRTINFO.RPORT_KEY = '+ltrim(rtrim(str(@rportKey)))+' and RPORTMAP.CHILD_TYPE = '+ ltrim(rtrim(str(@prog_node_type)))
   end
   else
   begin
	  if(@rport_node_type = 23)
	  begin
		 set @prog_node_type = 27
		 set @sql = 'select @countLayers = count(CSLAYR_KEY) from (RPRTINFO inner join  RPORTMAP on RPRTINFO.RPORT_KEY = RPORTMAP.RPORT_KEY) inner join ((CASELAYR inner join (CASEINFO inner join PROGINFO on CASEINFO.PROG_KEY=PROGINFO.PROG_KEY) on (CASELAYR.CASE_KEY = CASEINFO.CASE_KEY ))) on RPORTMAP.CHILD_KEY = CASEINFO.PROG_KEY where PROGINFO.LPORT_KEY > 0 and  RPRTINFO.RPORT_KEY = '+ ltrim(rtrim(str(@rportKey))) +' and RPORTMAP.CHILD_TYPE = '+ ltrim(rtrim(str(@prog_node_type)))
	  end
   end
   execute sp_executesql @sql,N'@countLayers int output', @countLayers output
   
   select  @count = count(*) from rportmap 
   inner join exposureMap on  exposureMap.parentKey = rportmap.child_Key 
   inner join exposureInfo on  exposureInfo.exposureKey = exposureMap.exposureKey 
   inner join proginfo on proginfo.prog_key = exposureMap.parentKey
   inner join caseinfo on proginfo.prog_key = caseinfo.prog_key
   and (parentType = 7 or parentType = 27)
   and (exposureInfo.status = 'Imported' or exposureInfo.status = 'Oakland')
   and rport_key = @rportKey
   
   if(@countLayers <= 0 and @count > 0)
   	set @countLayers = @count
   
   return @countLayers
end





