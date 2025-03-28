if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsRPortfolioImported') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_IsRPortfolioImported
end
 go

create procedure absp_IsRPortfolioImported @rportKey int ,@allPrograms int = 0
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This function will return a code signifying whether the given rport has been imported.

Returns:         A value @retVal
1. @retVal = 1, when the given rport is imported
2. @retVal = 0, when the given rport is not imported


====================================================================================================
</pre>
</font>
##BD_END

##PD @rportKey ^^  The key of the rport node which needs to be checked whether imported or not. 
##PD @allPrograms ^^  Option 1 = all programs must be imported, 0 = any single program must be imported.

##RD @retVal^^ A returned value, signifying whether the rport is imported or not.
*/
   as
begin

   set nocount on
   
   declare @retVal int
   declare @notImported int
   declare @nPrograms int
   declare @count int
  -- The first problem is to be sure there are Programs or else you get the wrong answer below
   select  @nPrograms = count(*)  from RPORTMAP where RPORTMAP.RPORT_KEY = @rportKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
  -- The trick is to count up how many Programs in this RPORT
  -- have al LPORT_KEY of 0.  If the answer is zero, then all are imported.
  -- If > 0, then at least one Program is not imported.
   select  @notImported = count(PROGINFO.LPORT_KEY)  from(PROGINFO join RPORTMAP on RPORTMAP.CHILD_KEY = PROGINFO.PROG_KEY) where
   PROGINFO.LPORT_KEY = 0 and RPORTMAP.RPORT_KEY = @rportKey and(RPORTMAP.CHILD_TYPE = 7 or CHILD_TYPE = 27)
  -- SDG__00015800 -- Exposure Tab is NOT Enabled at Reinsurance or MT Reinsurance Portfolio Levels
  --     Add an option to test for either ANY imported program or ALL imported programs.   Default is ANY.
   if @allPrograms = 0
   begin
	-- were ANY programs imported"?"   If so return 1 else return 0.
	  if @nPrograms > 0 and(@notImported = 0 or @notImported < @nPrograms)
	  begin
		 set @retVal = 1
	  end
	  else
	  begin
		 set @retVal = 0
	  end
   end
   else
   begin
	-- if the count is zero, then all imported; return 1(true)
	-- else not all, return 0 (false)
	  if @notImported = 0 and @nPrograms > 0
	  begin
		 set @retVal = 1
	  end
	  else
	  begin
		 set @retVal = 0
	  end
   end
   
   select @count = count(*) from exposureMap
   inner join rportmap on exposureMap.parentKey = rportmap.child_Key 
   inner join exposureInfo on exposureInfo.exposureKey = exposureMap.exposureKey 
   and (exposureInfo.status = 'Imported' or exposureInfo.status = 'Oakland')   
   and rport_key = @rportKey and (parentType = 7 or parentType = 27)
   
   if @count > 0 and @retVal = 0
   	set @retVal = 1
	
	
   return @retVal
end



