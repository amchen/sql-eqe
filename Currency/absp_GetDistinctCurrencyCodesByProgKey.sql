if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDistinctCurrencyCodesByProgKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDistinctCurrencyCodesByProgKey
end
 go
create procedure absp_GetDistinctCurrencyCodesByProgKey @progKey int,@targetCurrKey int , @targetDB varchar(130)= '' 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds the number of distinct currency codes used by cases, inuring covers or
logical portfolios under the specified program, which are not available within the given target
currency schema. As soon as missing currency codes are found in any one of child cases, inuring
covers or logical portfolios, the first encountered number of missing currency code will be 
returned in this order of searching. This is basically called to invalidate the differences in 
currency codes between 2 different currency schemas during copying of nodes.

Returns:	Number of distinct currency codes or returns 0 if no distinct codes are found. 

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@progKey 	^^ Key of program.
##PD   	@targetCurrKey	^^ Currency key of the target currency schema.
##RD	@missingCount	^^ Number of distinct currency codes [0 if not found].
*/
as
begin

  set nocount on
   declare @missingCount int
   declare @curs1_CaseKey int  
   declare @curs2_InurKey int
   declare @curs3_LportKey int
   declare @sql nvarchar(max)
   
   set @missingCount = 0
   print 'inside  absp_GetDistinctCurrencyCodesByProgKey '
   
   if @targetDB=''
     	set @targetDB= DB_NAME();
     
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   declare curs1_prog  cursor fast_forward  for select  CASE_KEY   from CASEINFO where  PROG_KEY = @progKey
   open curs1_prog
   fetch next from curs1_prog into @curs1_CaseKey
   while @@fetch_status = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByProgKey, case_key = '+str(@curs1_CaseKey)
      set @sql='select  @missingCount = count(*)  from absvw_GetDistinctCurrencyCodesByCaseKey 
         where  CASE_KEY = ' + str(@curs1_CaseKey ) + 
         ' and not left(CC,3) = any(select  code from ' + dbo.trim(@targetDB) + '..exchrate 
         where EXCHGRATE > 0 and active = ''Y'' 
         and currsk_key = ' + str(@targetCurrKey) + ')'
      
      execute sp_executesql @sql,N'@missingCount int output',@missingCount output
   
      if @missingCount > 0
      begin
         close curs1_prog
         deallocate curs1_prog
         return @missingCount
      end
      fetch next from curs1_prog into @curs1_CaseKey
   end
   close curs1_prog
   deallocate curs1_prog
   
   declare curs2_Inur  cursor fast_forward  for select  INUR_KEY   from INURINFO where PROG_KEY = @progKey
   open curs2_Inur
   fetch next from curs2_Inur into @curs2_InurKey
   while @@fetch_status = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByProgKey, inur_key = '+str(@curs2_InurKey)
      set @sql='select  @missingCount = count(*)  from absvw_GetDistinctCurrencyCodesByInurKey 
         where INUR_KEY ='+str(@curs2_InurKey) + 
         ' and not left(CC,3) = any(select  code from ' + dbo.trim(@targetDB) + '..exchrate 
          where EXCHGRATE > 0 and active = ''Y'' and currsk_key = ' + str(@targetCurrKey) + ')'
      
      execute sp_executesql @sql,N'@missingCount int output',@missingCount output

      if @missingCount > 0
      begin
          close curs2_Inur
          deallocate curs2_Inur
          return @missingCount
      end
      fetch next from curs2_Inur into @curs2_InurKey
   end
   close curs2_Inur
   deallocate curs2_Inur
   
   
   return @missingCount
end


