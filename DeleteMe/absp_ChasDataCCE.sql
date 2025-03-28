if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ChasDataCCE') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ChasDataCCE
end
go
create procedure absp_ChasDataCCE @chasKey int,@currskKey int,@rowNum int = 0,@debug int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates the columns of the CHASDATA or IMPORT_CHASDATA_xxx (xxx being the given ChasKey) 
based on the COUNTRY_ID, PERIL, RISKTYPE ,ROW_NO for the given ChasKey.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  chasKey ^^  The chas_key for which the updation has to take place.
##PD  currskKey ^^  The key of the currency schema for which the currency of the given chas_key belongs to.  
##PD  rowNum ^^  The rowNum value based on which the updation has to take place in the table(0 - IMPORT_CHASDATA_xxx, Not equalto 0 - CHASDATA table). 
##PD  debug ^^  The debug flag

*/
as
begin
 
   set nocount on
   
  declare @exchgRate float(53)
   declare @debug2 int
   declare @sql varchar(max)
   declare @sql2 varchar(max)
   declare @CHASDATA varchar(max)
   declare @currcy varchar(max)
   declare @msgText varchar(max)
   
   set @debug2 = @debug
   set @CHASDATA = 'CHASDATA'
  -- bulk import mode
   if(@rowNum = 0)
   begin
      set @CHASDATA = 'IMPORT_CHASDATA_'+cast(@chasKey as CHAR)
   end
   if @debug2 > 0
   begin
      set @msgText = '1. absp_ChasDataCCE, @chasKey = '+rtrim(ltrim(str(@chasKey)))
      execute absp_MessageEx @msgText
   end
  /*
  for lp as curs cursor for
  select distinct trim ( CURRENCY ) as currcy from CHASDATA where CHAS_KEY = chasKey
  do
  */
   set @sql2 = 'select distinct ltrim(rtrim ( CURRENCY )) from ' + @CHASDATA + ' where CHAS_KEY = ' + cast(@chasKey as CHAR)
   if @debug2 > 0
   begin
      set @msgText = '1a. absp_ChasDataCCE, @sql2: '+ @sql2
      execute absp_MessageEx @msgText
   end
   begin
    
      execute('DECLARE my_curs CURSOR GLOBAL FOR ' + @sql2)
      open my_curs 
      while 1 = 1
      begin
         fetch next FROM my_curs into @currcy
         if @@fetch_status <> 0
         begin
            break
         end
         execute absp_ChasCurrencyRateOrConvert  @exchgRate OUTPUT, @currskKey,@currcy
         if @debug2 > 0
         begin
            set @msgText = '2. absp_ChasDataCCE, @exchgRate = '+cast(@exchgRate as CHAR)
            execute absp_MessageEx @msgText
         end
      -- convert USD to equivalent values
         set @sql = 'update '+@CHASDATA+' set '
         set @sql = @sql+'VALUECCE = ( 1000 * VALUEUSD ) /' + cast(@exchgRate as CHAR) + ','
         set @sql = @sql+'LIMITCCE =  ( 1000 * LIMITUSD ) / ' + cast(@exchgRate as CHAR) + ','
         set @sql = @sql+'POLLIMCCE = ( 1000 * POLLIMUSD ) / ' + cast(@exchgRate as CHAR) + ','
         set @sql = @sql+'UNDRCVRCCE =  ( 1000 * UNDRCVRUSD ) / ' + cast(@exchgRate as CHAR) + ','
         set @sql = @sql+'DEDUCTCCE = case '
      -- percentage deduct
         set @sql = @sql+'when DEDUCTIBLE < 0 AND DEDUCTIBLE > -1 then 0 '
         set @sql = @sql+'when DEDUCTIBLE < 1 AND DEDUCTIBLE >= 0 then DEDUCTIBLE '
         set @sql = @sql+'else ( DEDUCTUSD ) /' + cast(@exchgRate as CHAR) + ' end,'
         set @sql = @sql+'POLDEDCCE = case '
         set @sql = @sql+'when POLDEDUCT  < 0 AND POLDEDUCT > -1 then -POLDEDUCT '
         set @sql = @sql+'when POLDEDUCT  < 1 AND POLDEDUCT >= 0 then POLDEDUCT '
         set @sql = @sql+'else ( POLDEDUSD ) / '+cast(@exchgRate as CHAR)+' end, '
         set @sql = @sql+'PDEDMINCCE = case '
         set @sql = @sql+'when POLDEDMIN  < 0 AND POLDEDMIN > -1 then -POLDEDMIN '
         set @sql = @sql+'when POLDEDMIN  < 1 AND POLDEDMIN >= 0 then POLDEDMIN '
         set @sql = @sql+'else ( PDEDMINUSD ) / '+cast(@exchgRate as CHAR)+' end '
         set @sql = @sql+'WHERE CHAS_KEY = ' +  cast(@chasKey as CHAR) + ' and CURRENCY = '''+cast(@currcy as CHAR)+''' and '
         set @sql = @sql+'(case when ' + cast(@rowNum as CHAR)  + ' = 0 then ROW_NO else ' + cast(@rowNum as CHAR) + ' end) = ROW_NO' -- end of UPDATE CHASDATA
		
         if @debug2 > 0
         begin
            set @msgText = '3. absp_ChasDataCCE, @sql: '+@sql
            execute absp_MessageEx @msgText
         end
         execute(@sql)
         
      end
      close my_curs
      deallocate my_curs
   end -- this ends the currency loop
  -- SDG__00007361
  -- SDG__00005724 -- handle special Taiwan DEDUCTUSD and LIMITUSD amounts
  --   COUNTRY_ID = 'TWN', 0 < DEDUCTIBLE < -1, PERIL in ('Q', 'X') and RISKTYPE='R'
  --   set POLDEDUSD = DEDUCTUSD = (-100 * DEDUCTIBLE)
   set @sql = 'update '+@CHASDATA+' set '
   set @sql = @sql+'POLDEDCCE = DEDUCTUSD / 100,'
   set @sql = @sql+'DEDUCTCCE = DEDUCTUSD / 100, '
   set @sql = @sql+'PDEDMINCCE = PDEDMINUSD  / 100 '
   set @sql = @sql+'where CHAS_KEY = ' + str(@chasKey) + ' and '
   set @sql = @sql+'COUNTRY_ID = ''TWN'' and '
   set @sql = @sql+'DEDUCTIBLE < 0 and DEDUCTIBLE > -1 and '
   set @sql = @sql+'PERIL IN (''Q'', ''X'') and '
   set @sql = @sql+'RISKTYPE = ''R'' '
   if @debug2 > 0
   begin
      set @msgText = '4. absp_ChasDataCCE, @sql: '+@sql
      execute absp_MessageEx @msgText
   end
   execute(@sql)
   
end




