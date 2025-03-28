if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ChasDataSetPolDedsAndLims') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ChasDataSetPolDedsAndLims
end
go

create procedure absp_ChasDataSetPolDedsAndLims @chasKey int,@currskKey int,@rowNum int = 0,@debug int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates the columns of the CHASDATA or IMPORT_CHASDATA_xxx (xxx = integer) table
based on the CHAS_KEY, CURRENCY, POLICYID, ROW_NO in the CHASDATA or 
IMPORT_CHASDATA_xxx (xxx = integer) table.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  chasKey ^^  The chas_key for which th eupdation has to take place.
##PD  currskKey ^^  The currskkey value for that chas_key.  
##PD  rowNum ^^  The rowNum value based on which the updation has to take place in the table(0 - IMPORT_CHASDATA_xxx Not equalto 0 - CHASDATA table). 
##PD  debug ^^  An integer value used for debugging

*/
as
begin
 
   set nocount on
   
  declare @lastPolDed float(53)
   declare @lastPolLim money
   declare @lastPolDedUSD float(53)
   declare @lastPolLimUSD money
   declare @lastUndercover money
   declare @lastPolDedMin float(53)
   declare @lastUndcvrUSD float(53)
   declare @lastPdedMaxUSD float(53)
   declare @exchgRate float(53)
   declare @debug2 int
   declare @sql nvarchar(4000)
   declare @sql2 varchar(max)
   declare @sql3 varchar(max)
   declare @CHASDATA varchar(max)
   declare @currcy char(8)
   declare @PID char(32)
   declare @MINROW int
   declare @MAXROW int
   declare @msgText varchar(max)
   set @debug2 = @debug
   set @CHASDATA = 'CHASDATA'
   set @lastUndercover = 0
   set @lastUndcvrUSD = 0
   set @currcy = ''
--custom initializations
   --set @lastPolDedUSD = 0
   --set @lastPolLimUSD = 0
  -- bulk import mode
   if(@rowNum = 0)
   begin
      set @CHASDATA = 'IMPORT_CHASDATA_'+cast(@chasKey as CHAR)
   end
   if @debug2 > 0
   begin
      set @msgText = '1. absp_ChasDataSetPolDedsAndLims, chasKey = '+cast(@chasKey as CHAR)+', currskKey = '+cast(@currskKey as CHAR)+', rowNum = '+cast(@rowNum as CHAR)
      execute absp_MessageEx @msgText
   end
  /*
  for lp as curs cursor for
  select distinct trim ( CURRENCY ) as currcy from CHASDATA where CHAS_KEY = chasKey
  do
  */
   set @sql2 = 'select distinct ltrim(rtrim ( CURRENCY )) from '+@CHASDATA+' where CHAS_KEY = '+cast(@chasKey as CHAR)
   if @debug2 > 0
   begin
      set @msgText = '1a. absp_ChasDataSetPolDedsAndLims, @sql2: '+@sql2
      execute absp_MessageEx @msgText
   end
   begin
    
      execute('declare my_curs cursor global for '+@sql2)
      open my_curs 
      my_loop: while 1 = 1
      begin
         fetch next from my_curs into @currcy
         if @@fetch_status <> 0
         begin
            break
         end
         execute absp_ChasCurrencyRateOrConvert @exchgRate out, @currskKey,@currcy
         if @debug2 > 0
         begin
            set @msgText = '2. absp_ChasDataSetPolDedsAndLims, @exchgRate = '+cast(@exchgRate as char)
            execute absp_MessageEx @msgText
         end
      -- find all policies with > 1 row where pollim or polded > 0
      /*
      for lp1 as curs1 cursor for
      select  POLICYID AS PID,
      Min ( ROW_NO ) AS MINROW,
      Max ( ROW_NO ) AS MAXROW
      from CHASDATA
      where CHAS_KEY = chasKey  and CURRENCY = currcy and
      (case when rowNum = 0 then ROW_NO else rowNum end) = ROW_NO
      group by  POLICYID
      having ( Count(*) > 1 ) and ( Sum ( POLDEDUCT ) > 0  or Sum ( POLLIMIT ) > 0)
      order by CHASDATA.POLICYID asc
      do
      */
         set @sql3 = 'select replace(dbo.trim(POLICYID), '''''''', '''') as POLICYID , min(ROW_NO), max(ROW_NO) from '+@CHASDATA
         set @sql3 = @sql3+' where CHAS_KEY = ' + cast(@chasKey as CHAR) + ' and CURRENCY = '''+isnull(@currcy,'')+''' and '
         set @sql3 = @sql3+'(case when ' + cast(@rowNum as CHAR) + '  = 0 then ROW_NO else ' + cast(@rowNum as CHAR) + ' end) = ROW_NO '
         set @sql3 = @sql3+'GROUP BY POLICYID '
         set @sql3 = @sql3+'having ( count(*) > 1 ) '
         set @sql3 = @sql3+'and ( sum ( POLDEDUCT ) > 0 or sum ( POLLIMIT ) > 0  or sum (POLDEDMIN) > 0 OR sum (UNDERCOVER) > 0) '
         set @sql3 = @sql3+'order by policyid asc'
         if @debug2 > 0
         begin
            set @msgText = '2a. absp_ChasDataSetPolDedsAndLims, @sql3: '+@sql3
            execute absp_MessageEx @msgText
         end
         begin
        
            execute('declare my_curs3 cursor global for '+@sql3)
            open my_curs3 
            my_loop3: while 1 = 1
            begin
               fetch next from my_curs3 into @PID,@MINROW,@MAXROW
               if @@fetch_status <> 0
               begin
                  break
               end
          
               set @lastPolDedUSD = 0
               set @lastPolLimUSD = 0
               if @debug2 > 0
               begin
                  execute absp_MessageEx '3. absp_ChasDataSetPolDedsAndLims'
               end
          -- the rule according to CHAS is you get the LAST value you saw as the rows went by.
          -- Seems funny, but there it is. 
               set @sql = N'select @lastPolDed = POLDEDUCT,@lastPolLim  = POLLIMIT,@lastPolDedUSD = POLDEDUCT* ' + cast(@exchgRate as char) + N' ,@lastPolLimUSD = POLLIMIT* ' + cast(@exchgRate as char) + N', '
               set @sql = @sql+N' @lastUndercover = UNDERCOVER,@lastPolDedMin = POLDEDMIN, @lastUndcvrUSD = UNDERCOVER*'+ cast(@exchgRate as char) + N',@lastPdedMaxUSD = POLDEDMIN*'+ cast(@exchgRate as char) 
               set @sql = @sql+N'from '+@CHASDATA+' where '
               set @sql = @sql+N'CHAS_KEY = ' + cast(@chasKey as CHAR) + N' and POLICYID = '''+@PID+N''' and ROW_NO = '+cast(@MAXROW as CHAR)
               set @sql = @sql+N' and CURRENCY = '''+@currcy+''' '
               if @debug2 > 0
               begin
                  set @msgText = '4. absp_ChasDataSetPolDedsAndLims, @sql: '+@sql
                  execute absp_MessageEx @msgText
               end
               --execute(@sql)
				exec sp_executesql @sql,N'@lastPolDed float(53) output, @lastPolLim money output, 
										 @lastPolDedUSD float(53) output,@lastPolLimUSD money output,
										 @lastUndercover money output, @lastPolDedMin float(53) output, 
										 @lastUndcvrUSD float(53) output, @lastPdedMaxUSD float(53) output',
										 @lastPolDed out, @lastPolLim out, @lastPolDedUSD out,
										 @lastPolLimUSD out, @lastUndercover out, @lastPolDedMin out, 
										 @lastUndcvrUSD out, @lastPdedMaxUSD out
				 
          -- OK, now that we have a policy that needs work, update all rows so
          -- pollim and polded are the same

               set @sql = 'update '+@CHASDATA+' set '
               set @sql = @sql+'POLDEDUCT = ' + cast(@lastPolDed as CHAR) + ', '
               set @sql = @sql+'POLLIMIT = ' + cast(@lastPolLim as CHAR)  +  ', '
               set @sql = @sql+'UNDERCOVER = ' + cast(@lastUndercover as CHAR)+ ' , '
               set @sql = @sql+'POLDEDMIN = ' + cast(@lastPolDedMin as CHAR) + ', '
               set @sql = @sql+'POLDEDUSD = case when ' + cast(@lastPolDed as CHAR) + ' < 0 then 0 '
               set @sql = @sql+'when(' + cast(@lastPolDed as CHAR) + ' >= 0 and ' + cast(@lastPolDed as CHAR) + ' < 1) then ' + cast(@lastPolDed as CHAR) + '*100 '
               set @sql = @sql+'when ' + cast(@lastPolDedUSD as CHAR) + ' >= 100 then ' + cast(@lastPolDedUSD as CHAR) 
               set @sql = @sql+'when( ' +cast(@lastPolDedUSD as CHAR) + ' >= 50 and ' + cast(@lastPolDedUSD as CHAR) + ' < 100) then 100 '
               set @sql = @sql+'else 0 end, '
               set @sql = @sql+'POLLIMUSD = case when ' + cast(@lastPolLim as CHAR) + ' < 0 then 0 '
               set @sql = @sql+'when(' + cast(@lastPolLim as CHAR) + '>= 0 and ' + cast(@lastPolLim as CHAR) + ' < 1) then ' + cast(@lastPolLim as CHAR) + '*VALUEUSD '
               set @sql = @sql+'else ' + cast(@lastPolLimUSD as CHAR) + '/1000 end, '
               set @sql = @sql+'UNDRCVRUSD = ' + cast(@lastUndcvrUSD as CHAR) + '/1000, '
               set @sql = @sql+'PDEDMINUSD = case when ' + cast(@lastPolDedMin as CHAR) + ' < 0 then 0 '
               set @sql = @sql+'when(' + cast(@lastPolDedMin as CHAR) + ' >= 0 and ' + cast(@lastPolDedMin as CHAR) + ' < 1) then ' + cast(@lastPolDedMin*100 as CHAR)
               set @sql = @sql+'when ' + cast(@lastPdedMaxUSD as CHAR) + ' >= 100 then ' + cast(@lastPdedMaxUSD as CHAR)
               set @sql = @sql+'when(' + cast(@lastPdedMaxUSD as CHAR) + ' >= 50 and ' + cast(@lastPdedMaxUSD as CHAR) + ' < 100) then 100 '
               set @sql = @sql+'else 0 end '
               set @sql = @sql+'where CHAS_KEY = ' + cast(@chasKey as CHAR) + 'and POLICYID = '''+@PID+''' and '
               set @sql = @sql+'CURRENCY = '''+@currcy+''' AND (ROW_NO BETWEEN '+cast(@MINROW as CHAR)
          -- defect 12745 skip updating rows having error code > 0 so they can be thrown out by the next re-import&analyze
               set @sql = @sql+' AND '+cast(@MAXROW as CHAR)+') AND ERR_CODE = 0'
               if @debug2 > 0
               begin
                  set @msgText = '5. absp_ChasDataSetPolDedsAndLims, @sql: '+@sql
                  execute absp_MessageEx @msgText
               end
               execute(@sql)
              
            end
            close my_curs3
			deallocate my_curs3
         end -- this end policies count > 1 loop
      -- note that the above got all policies with count > 1
      -- now we have to do those that have just 1 row
         set @sql = N'update '+@CHASDATA+ N' set '
         set @sql = @sql+N'POLDEDUSD = case when POLDEDUCT < 0 then 0 '
         set @sql = @sql+N'when(POLDEDUCT >= 0 and POLDEDUCT < 1) then POLDEDUCT*100 '
         set @sql = @sql+N'when POLDEDUCT >= 100 then POLDEDUCT*' + cast(@exchgRate as char)
         set @sql = @sql+N'when(POLDEDUCT >= 50 and POLDEDUCT*' + cast(@exchgRate as char) + '  < 100) then 100 '
         set @sql = @sql+N'else 0 end, '
         set @sql = @sql+N'POLLIMUSD = case when POLLIMIT < 0 then 0 '
         set @sql = @sql+N'when(POLLIMIT >= 0 and POLLIMIT < 1) then POLLIMIT * VALUEUSD '
         set @sql = @sql+N'else POLLIMIT*' + cast(@exchgRate as char) + N'/1000 end, '
         set @sql = @sql+N'UNDRCVRUSD = UNDERCOVER*' + cast(@exchgRate as char) + N'/1000, '
         set @sql = @sql+N'PDEDMINUSD = case when POLDEDMIN < 0 then 0 '
         set @sql = @sql+N'when(POLDEDMIN >= 0 and POLDEDMIN < 1) then POLDEDMIN*100 '
         set @sql = @sql+N'when POLDEDMIN >= 100 then POLDEDMIN*' + cast(@exchgRate as char)
         set @sql = @sql+N'when(POLDEDMIN >= 50 and PDEDMINUSD < 100) then 100 '
         set @sql = @sql+N'else 0 end '
         set @sql = @sql+N'where CHAS_KEY = ' + cast(@chasKey as CHAR) + N' and CURRENCY = '''+@currcy+N''' and '
      -- SDG__00015522 - Fix the problem: Undercover not imported correctly when the policy limit is 0
         set @sql = @sql+'((POLDEDUCT <> 0 and POLDEDUSD = 0) or (POLLIMIT <> 0 and POLLIMUSD = 0) or (UNDERCOVER <> 0 and UNDRCVRUSD = 0) ) and '
      -- defect 12745 skip updating rows having error code > 0 so they can be thrown out by the next re-import&analyze
         set @sql = @sql+'(case when ' + cast(@rowNum as CHAR) + ' = 0 then ROW_NO else ' + cast(@rowNum as CHAR) + ' end) = ROW_NO ' + ' AND ERR_CODE = 0'
         if @debug2 > 0
         begin
            set @msgText = '6. absp_ChasDataSetPolDedsAndLims, @sql: '+@sql
            execute absp_MessageEx @msgText
         end
	exec sp_executesql @sql,N'@lastPolDedUSD float(53)',@lastPolDedUSD 
      end
      close my_curs
      deallocate my_curs
   end -- this ends the currency loop
  -- Now we have to set the currency equivalent fields
 
   execute absp_ChasDataCCE @chasKey,@currskKey,@rowNum,@debug2

   if @debug2 > 0
   begin
      execute absp_MessageEx '7. absp_ChasDataSetPolDedsAndLims, Done'
   end
-- SDG__00006081 -- Set each policys PARTTYPE to be the same in each row of the policy
-- SDG_00008471 -- new rule does not require last row policy any more.
--call absp_ChasDataSetPartType(chasKey);
end
