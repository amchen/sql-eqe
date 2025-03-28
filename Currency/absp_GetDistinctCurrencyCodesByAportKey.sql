
if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_GetDistinctCurrencyCodesByAportKey') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDistinctCurrencyCodesByAportKey
end
 go
create procedure absp_GetDistinctCurrencyCodesByAportKey @aportKey int,@targetCurrKey int, @targetDB varchar(130)=''
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds the number of currency codes used by retrocession treaties, reinsurance
portfolios or primary portfolios under the specified accumulation portfolio, which are missing  
or marked inactive in the given target currency schema. As soon as missing currency codes are 
found in any one of child retrocession treaties, reinsurance portfolios or primary portfolios,
the first encountered number of missing currency code will be returned in this order of searching.  


Returns:	Number of distinct currency codes or returns 0 if no missing currency codes are found. 

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@aportKey 	^^ Key of accumulation portfolio.
##PD   	@targetCurrKey	^^ Currency key of the target currency schema.
##RD	@missingCount	^^ Number of distinct currency codes. 
*/
as
begin

set nocount on
   declare @missingCount int
   declare @curs1_RtroKey int
   declare @curs2_RportKey int
   declare @curs3_PportKey int
   declare @sql nvarchar(max)
   
   print 'inside  absp_GetDistinctCurrencyCodesByAportKey '
   
   if @targetDB=''
     	set @targetDB= DB_NAME();
     
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   declare curRtro  cursor fast_forward  for 
         select  RTRO_KEY as RTROKEY from RTROINFO where  PARENT_KEY = @aportKey and PARENT_TYP = 1
   open curRtro
   fetch next from curRtro into @curs1_RtroKey
   while @@fetch_status = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByAportKey, rtro_key = '+str(@curs1_RtroKey)
      
      set @sql = 'select  @missingCount = count(*)  from absvw_GetDistinctCurrencyCodesByRtroKey where
        		RTRO_KEY = ' + str(@curs1_RtroKey) + ' and
        		not left(CC,3) = any(select  CODE from '+ dbo.trim(@targetDB) + '..EXCHRATE  
        		where EXCHGRATE > 0 and ACTIVE = ''Y'' and  CURRSK_KEY = ' + str(@targetCurrKey) + ')'
      execute sp_executesql @sql,N'@missingCount int output',@missingCount output

      if @missingCount > 0
      begin
         close curRtro
	     deallocate curRtro
         return @missingCount
      end
      fetch next from curRtro into @curs1_RtroKey
   end
   close curRtro
   deallocate curRtro
   
   declare curAport  cursor fast_forward  for 
      select  CHILD_KEY as RPORTKEY from APORTMAP where APORT_KEY = @aportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
   
   open curAport
   fetch next from curAport into @curs2_RportKey
   while @@fetch_status = 0
   begin
      print 'inside  absp_GetDistinctCurrencyCodesByAportKey, rport_key = '+str(@curs2_RportKey)
      execute @missingCount = absp_GetDistinctCurrencyCodesByRportKey @curs2_RportKey,@targetCurrKey,@targetDB
      if @missingCount > 0
      begin
 	close curAport
	deallocate curAport
         return @missingCount
      end
      fetch next from curAport into  @curs2_RportKey
   end
   close curAport
   deallocate curAport
   
 
end


