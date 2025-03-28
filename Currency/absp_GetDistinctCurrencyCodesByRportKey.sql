if exists(select 1 from sysobjects where id = object_id(N'absp_GetDistinctCurrencyCodesByRportKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDistinctCurrencyCodesByRportKey
end
 go
create procedure absp_GetDistinctCurrencyCodesByRportKey @rportKey int,@targetCurrKey int, @targetDB varchar(130)='' 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds the number of distinct currency codes used by programs under the 
specified re-insurance portfolio which are or marked inactive within the given target
currency schema.

Returns:	Number of distinct currency codes or returns 0 if no distinct currency code are found. 

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@rportKey 	^^ Key of Re-insurance portfolio.
##PD   	@targetCurrKey	^^ Currency key of the target currency schema.
##RD	@missingCount	^^ Number of distinct currency codes [0 if not found]. 
*/
as
begin
   set nocount on
   declare @missingCount int
   declare @curs1_ProgKey int
   declare @sql nvarchar(max)
   
   set @missingCount = 0
   print 'inside  absp_GetDistinctCurrencyCodesByRportKey '
   
   if @targetDB=''
     	set @targetDB= DB_NAME();
     
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   declare curs1_rport  cursor fast_forward for 
     select  CHILD_KEY as PROGKEY from RPORTMAP where RPORT_KEY = @rportKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
  
   open curs1_rport
   fetch next from curs1_rport into @curs1_ProgKey
   while @@fetch_status = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByRportKey, prog_key = '+str(@curs1_ProgKey)
      
      set @sql = 'select  @missingCount = count(*)  from absvw_GetDistinctCurrencyCodesByProgKey 
        		where PROG_KEY = ' + str(@curs1_ProgKey ) + 
        		' and not left(CC,3) =  any(select  code from ' + dbo.trim(@targetDB) + '..EXCHRATE 
        		where EXCHGRATE > 0 and active = ''Y'' and  currsk_key =' + str(@targetCurrKey) + ')'
      execute sp_executesql @sql,N'@missingCount int output',@missingCount output
        		
      if @missingCount > 0
      begin
         close curs1_rport
         deallocate curs1_rport
         return @missingCount
      end
      execute @missingCount = absp_GetDistinctCurrencyCodesByProgKey @curs1_ProgKey,@targetCurrKey, @targetDB
      if @missingCount > 0
      begin
         close curs1_rport
         deallocate curs1_rport
         return @missingCount
      end
      fetch next from curs1_rport into @curs1_ProgKey
   end
   close curs1_rport
   deallocate curs1_rport
   return @missingCount
end


