if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDistinctCurrencyCodesByFldrKey') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDistinctCurrencyCodesByFldrKey
end
 go
create procedure absp_GetDistinctCurrencyCodesByFldrKey @fldrKey int,@targetCurrKey int,@targetDB varchar(130)='' 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds distinct number of currency codes under the sub-level nodes of 
the specified folder which are missing or marked inactive in the given target currency schema.
As soon as missing currency codes are found in any one of child folders, accumulation portfolios,
reinsurance portfolios or primary portfolios, the first encountered number of missing currency 
code will be returned in this order of searching.


Returns:	Number of distinct currency codes or returns 0 if no distinct currency codes are found. 

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@fldrKey 	^^ Folder Key.
##PD   	@targetCurrKey	^^ Currency key of the target currency schema.
##RD	@missingCount	^^ Number of distinct currency codes. 
*/
as
begin

set nocount on
   declare @missingCount int
   declare @curs1_FldrKey int
   declare @curs2_AportKey int
   declare @curs3_RportKey int
   declare @curs4_PportKey int
   
   print 'inside  absp_GetDistinctCurrencyCodesByFldrKey '
    declare curs1  cursor local fast_forward  for select  CHILD_KEY   from FLDRMAP where FOLDER_KEY = @fldrKey and CHILD_TYPE = 0
   open curs1
   fetch next from curs1 into @curs1_FldrKey
   while @@FETCH_STATUS = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByFldrKey, folder_key = '+str(@curs1_FldrKey)
      execute @missingCount = absp_GetDistinctCurrencyCodesByFldrKey @curs1_FldrKey,@targetCurrKey,@targetDB
      if @missingCount > 0
      begin
        close curs1
	deallocate curs1
	return @missingCount
      end
      fetch next from curs1 into @curs1_FldrKey
   end
   close curs1
   deallocate curs1
   
   declare curs2  cursor  fast_forward  for select  CHILD_KEY   from FLDRMAP where FOLDER_KEY = @fldrKey and CHILD_TYPE = 1
   open curs2
   fetch next from curs2 into @curs2_AportKey
   while @@FETCH_STATUS = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByFldrKey, aport_key = '+str(@curs2_AportKey)
      execute @missingCount = absp_GetDistinctCurrencyCodesByAportKey @curs2_AportKey,@targetCurrKey,@targetDB
      if @missingCount > 0
      begin
         close curs2
	 deallocate curs2
         return @missingCount
      end
      fetch next from curs2 into @curs2_AportKey
   end
   close curs2
   deallocate curs2
   
   declare curs3  cursor local fast_forward  for select  CHILD_KEY  from FLDRMAP  
       where  FOLDER_KEY = @fldrKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
   open curs3
   fetch next from curs3 into @curs3_RportKey
   while @@FETCH_STATUS = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByFldrKey, rport_key = '+str(@curs3_RportKey)
      execute @missingCount = absp_GetDistinctCurrencyCodesByRportKey @curs3_RportKey,@targetCurrKey,@targetDB
      if @missingCount > 0
      begin
         close curs3
         deallocate curs3
         return @missingCount
      end
      fetch next from curs3 into @curs3_RportKey
   end
   close curs3
   deallocate curs3
   
end



