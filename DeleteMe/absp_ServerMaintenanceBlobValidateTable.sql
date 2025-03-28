if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ServerMaintenanceBlobValidateTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerMaintenanceBlobValidateTable
end

go
create procedure absp_ServerMaintenanceBlobValidateTable 
@tableName char(14),@fieldName char(14),@maintKey int, @groupId int, @invalidateOnMismatch bit = 0,@logMatches bit = 0,@optionFlag int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates the SVRMTLOG table with the values of the key fields of the given blob 
tablename that has a mismatch in the master and results database and invalidates the 
associated results. If logMatches = 1, the matching key values are also logged.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Name of the Blob table for which the invalidation will take place
##PD  @fieldName ^^  Name of the key field of the above table
##PD  @maintKey ^^  The maintenance key
##PD  @groupId ^^  The DBTASK group ID.
##PD  @invalidateOnMismatch ^^  A flag which indicates if the results are to be invalidated on mismatch
##PD  @logMatches ^^  A flag to indicate that even matches are to be logged
##PD  @optionFlag ^^  A flag to indicate if results are to be removed during invalidation

*/
AS


begin
   set nocount on
  /*
  this will log an entry for each server start and check master/result blob counts
  */
   declare @sSql varchar(max)
   declare @sSql2 varchar(max)
   declare @sSql3 varchar(max)
   declare @masterCnt int -- prog_key (or whatever)
   declare @resultCnt int
   declare @pk1 int
   declare @pk2 int
   declare @mKey int
   declare @tblName varchar(14)
   declare @fldName varchar(14)
   declare @mode int
   declare @IR_DBName varchar(2000)
   
   
   create table #MSTRKEYS
   (
      MSTRKEY int   null,
      MSTRCNT int   null
   )
   create table #RSLTKEYS
   (
      RSLTKEY int   null,
      RSLTCNT int   null
   )
   create table #ERRSKEYS
   (
      ERRKEY int   null
   )
   declare @ExecStr varchar(4000)
   declare @lp1_MSTRKEY int
   declare @lp1_RSLTKEY varchar(255)
   declare @lp1_MSTRCNT int
   declare @lp1 cursor
   declare @lp2_MSTRKEY int
   declare @lp2_RSLTKEY varchar(255)
   declare @lp2_RSLTCNT varchar(255)
   declare @lp2 cursor
   declare @lp3_MSTRKEY int
   declare @lp3_MSTRCNT int
   declare @lp3_RSLTCNT varchar(255)
   declare @lp3 cursor
   declare @lp4_MSTRKEY int
   declare @lp4_MSTRCNT int
   declare @lp4_RSLTCNT varchar(255)
   declare @lp4 cursor
   declare @lp5_ERRKEY int
   declare @lp5 cursor 
   
  -- OK, here we go
 
   set @mKey = @maintKey
   set @tblName = rtrim(ltrim(@tableName))
   set @fldName = rtrim(ltrim(@fieldName))
  --=================================================
  --Fixed defect SDG__00022679, SDG__00022682 
  if @tblName = 'PROGRS_A' or @tableName = 'PROGRS_P' 
  	set @fldName = 'PROG_KEY' 
  
  --=================================================
  --=================================================
  -- see what we have to work with
  -- distinct keys and counts from master
   set @sSql3 = 'select  '+@fldName+', count ( * )  from '+@tblName+' where '+@fldName+' > 0 '+' group by '+@fldName
  
  -- ----->> insert these into temp table
		execute('insert into #MSTRKEYS  '+@sSql3)
  -- distinct keys and counts from results ( a little more complicated )

   begin
     exec @mode=absp_Util_IsSingleDB
     if @mode=0
     begin
         set @IR_DBName=DB_NAME()+'_IR'

         set @sSql='declare curs0_blobVal cursor fast_forward global for 
         select ' +@fldName+', cnt  from  '+ @IR_DBName + '..' + @tblName +' where '+@fldName+' > 0 '+' group by '+@fldName  
     end
     else
          set @sSql='declare curs0_blobVal cursor fast_forward global for select ' +@fldName+', cnt  from  openquery(resultdb,''select '+ @fldName +', count(*) as cnt from '+@tblName +' where '+@fldName+' > 0 '+' group by '+@fldName +''') group by ' + @fldName + ',cnt' 
     execute(@sSql)
       
      open curs0_blobVal
      fetch next from curs0_blobVal into @pk1,@resultCnt
      while @@fetch_status=0
      begin
          -- ----->> insert these into temp table
          insert into #RSLTKEYS values(@pk1,@resultCnt)
          fetch next from curs0_blobVal into @pk1,@resultCnt
      end
      close curs0_blobVal
      deallocate curs0_blobVal
   end

  --select count(*) into @pk1 from #MSTRKEYS;
  --select count(*) into @pk2 from #RSLTKEYS;
  --message 'for ' + @tblName + ', counts = m, r ', @pk1, ',  ', @pk2;
  --============ case 1: Master only =======================
  
   set @lp1 = cursor fast_forward for 
   				select MSTRKEY,RSLTKEY,MSTRCNT from #MSTRKEYS 
   					left outer join #RSLTKEYS 
   					on #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY 
   					where isnull(MSTRKEY,0) <> isnull(RSLTKEY,0)

   open @lp1
   fetch next from @lp1 into @lp1_MSTRKEY,@lp1_RSLTKEY,@lp1_MSTRCNT
   while @@fetch_status = 0
   begin
      insert into SVRMTLOG values(@mKey,'MRB Status case 1','E',@tblName,@fldName,@lp1_MSTRKEY,@lp1_MSTRCNT,0)
    -- what to do with record"?"
      insert into #ERRSKEYS values(@lp1_MSTRKEY)
      fetch next from @lp1 into @lp1_MSTRKEY,@lp1_RSLTKEY,@lp1_MSTRCNT
   end
   close @lp1
   deallocate @lp1
  --============== case 2: Result only ===========================
  
   set @lp2 = CURSOR fast_forward FOR select MSTRKEY,RSLTKEY,RSLTCNT from #MSTRKEYS 
   				right outer join #RSLTKEYS on  #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY 
       where isnull(MSTRKEY,0) <> isnull(RSLTKEY,0)
   open @lp2
   fetch next from @lp2 into @lp2_MSTRKEY,@lp2_RSLTKEY,@lp2_RSLTCNT
   while @@fetch_status = 0
   begin
      insert into SVRMTLOG values(@mKey,'MRB Status case 2','E',@tblName,@fldName,@lp2_RSLTKEY,0,@lp2_RSLTCNT)
       -- what to do with record"?"
      insert into #ERRSKEYS values(@lp2_RSLTKEY)
      fetch next from @lp2 into @lp2_MSTRKEY,@lp2_RSLTKEY,@lp2_RSLTCNT
   end
   close @lp2
   deallocate @lp2
  --============== case 3: Counts no match"?" ===================
  
   set @lp3 = cursor fast_forward for select MSTRKEY,MSTRCNT,RSLTCNT from #MSTRKEYS 
      join  #RSLTKEYS on #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY 
      where  MSTRCNT <> RSLTCNT
   open @lp3
   fetch next from @lp3 into @lp3_MSTRKEY,@lp3_MSTRCNT,@lp3_RSLTCNT
   while @@fetch_status = 0
   begin
      insert into SVRMTLOG values(@mKey,'MRB Status case 3','E',@tblName,@fldName,@lp3_MSTRKEY,@lp3_MSTRCNT,@lp3_RSLTCNT)
    -- what to do with record"?"
      insert into #ERRSKEYS values(@lp3_MSTRKEY)
      fetch next from @lp3 into @lp3_MSTRKEY,@lp3_MSTRCNT,@lp3_RSLTCNT
   end
   close @lp3
   deallocate @lp3
   if @logMatches = 1
   begin
    --============== case 4: Counts match if LogAll flag set ===================
    
   set @lp4 = cursor fast_forward for select MSTRKEY,MSTRCNT,RSLTCNT from #MSTRKEYS 
     join #RSLTKEYS on #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY 
     where  MSTRCNT = RSLTCNT
      open @lp4
      fetch next from @lp4 into @lp4_MSTRKEY,@lp4_MSTRCNT,@lp4_RSLTCNT
      while @@fetch_status = 0
      begin
         insert into SVRMTLOG values(@mKey,'MRB Status case 4','I',@tblName,@fldName,@lp4_MSTRKEY,@lp4_MSTRCNT,@lp4_RSLTCNT)
         fetch next from @lp4 into @lp4_MSTRKEY,@lp4_MSTRCNT,@lp4_RSLTCNT
      end
      close @lp4
      deallocate @lp4
   end

end
