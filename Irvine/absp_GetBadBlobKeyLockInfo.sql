if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetBadBlobKeyLockInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetBadBlobKeyLockInfo
end

go
create procedure absp_GetBadBlobKeyLockInfo
@tempPath varchar(max) = '' 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure generates lock information based on the values of the key fields of the given blob 
tablename that has a mismatch in the primary and intermediateresults database (Temporary Table #LOCKINFO
is assumed previously created) 

Returns:	nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @tempPath ^^	log file path
*/
AS
-- SDG__00017296, SDG__00019516 Invalidation on server startup takes forever

begin
   set nocount on
  /*
  this will log an entry for each server start and check master/result blob counts
  */
   declare @sSql varchar(max)
   declare @sSql3 varchar(max)
   declare @resultCnt int
   declare @pk1 int
   declare @tblName varchar(120)
   declare @fldName varchar(120)
   declare @message varchar(max)
 
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
 
   IF OBJECT_ID('tempdb..#LOCKINFO','u') IS NULL
   begin
	   --print ' inside absp_GetBadBlobKeyLockInfos: LOCKINFO doesnt exist... It will be created!'
	   exec absp_Util_LogIt ' inside absp_GetBadBlobKeyLockInfos: LOCKINFO doesnt exist... It will be created!' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
	   create table #LOCKINFO
	   (
			 KEY1 	  int,
			 KEY2 	  int,
			 KEY3 	  int,
			 NODETYPE int    
	   )
   end

   --=================================================

  -- OK, here we go
   --print '   '
   --print GetDate() 
   --print '==========================================='
   --print 'absp_GetBadBlobKeyLockInfo: starting'
   exec absp_Util_LogIt '   ' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
   exec absp_Util_LogIt '===========================================' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
   exec absp_Util_LogIt 'absp_GetBadBlobKeyLockInfo: starting' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath

  --=================================================
  
  -- for each table ...
  -- get the count by key from master
   declare lp1  cursor fast_forward  for 
          select distinct rtrim(ltrim(TABLENAME)) as TN, rtrim(ltrim(KEYNAME)) as KN from DELCTRL where BLOB_DB = 'R' order by TN asc
   open lp1
   fetch next from lp1 into @tblName,@fldName
   while @@fetch_status = 0
   begin
 
      -- print ' inside absp_GetBadBlobKeyLockInfos: get LockInfo for  '+@tblName+':'+@fldName
	  --=================================================
	  -- see what we have to work with
	  -- distinct keys and counts from master
	   set @sSql3 = 'select  '+@fldName+', count ( * )  from '+@tblName+' where '+@fldName+' > 0 '+' group by '+@fldName
	  --print '@sSql3 = ' + @sSql3;
	  -- ----->> insert these into temp table
	  execute('insert into #MSTRKEYS  '+@sSql3)
	  
	  -- distinct keys and counts from results ( a little more complicated )
	  
	  set @sSql='select ' +@fldName+', count ( * ) from  openquery(resultdb,''select '+ @fldName +' from '+@tblName  +' where '+@fldName+'  > 0 '') group by ' + @fldName  
	  execute('insert into #RSLTKEYS  ' + @sSql)

	  --============ case 1: Master only =======================
	  
		--message '-&gt;1:for table ' +  @tblName + ' rmaster only has ' + @fldName + ' = ', MSTRKEY;
	   set @lp1 = cursor fast_forward for select MSTRKEY,RSLTKEY,MSTRCNT from #MSTRKEYS left outer join #RSLTKEYS on
	   #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY where
	   isnull(MSTRKEY,0) <> isnull(RSLTKEY,0)

	   open @lp1
	   fetch next from @lp1 into @lp1_MSTRKEY,@lp1_RSLTKEY,@lp1_MSTRCNT
	   while @@fetch_status = 0
	   begin
		  -- add entries to #LOCKINFO
		  --insert into #ERRSKEYS values(@lp1_MSTRKEY)
          --print ' inside absp_GetBadBlobKeyLockInfos - @lp1_MSTRKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp1_MSTRKEY)))
          set @message = ' inside absp_GetBadBlobKeyLockInfos - @lp1_MSTRKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp1_MSTRKEY)))
		  exec absp_Util_LogIt @message ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
		  execute absp_AddLockInfo @tblName, @fldName, @lp1_MSTRKEY, @tempPath
		  fetch next from @lp1 into @lp1_MSTRKEY,@lp1_RSLTKEY,@lp1_MSTRCNT
	   end
	   close @lp1
	   deallocate @lp1

	  --============== case 2: Result only ===========================
	  
	   set @lp2 = CURSOR fast_forward FOR select MSTRKEY,RSLTKEY,RSLTCNT from #MSTRKEYS right 
		   outer join #RSLTKEYS on  #MSTRKEYS.MSTRKEY = #RSLTKEYS.RSLTKEY 
		   where isnull(MSTRKEY,0) <> isnull(RSLTKEY,0)
	   open @lp2
	   fetch next from @lp2 into @lp2_MSTRKEY,@lp2_RSLTKEY,@lp2_RSLTCNT
	   while @@fetch_status = 0
	   begin
		  -- add entries to #LOCKINFO
          --print ' inside absp_GetBadBlobKeyLockInfos - @lp2_RSLTKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp2_RSLTKEY)))
          set @message = ' inside absp_GetBadBlobKeyLockInfos - @lp2_RSLTKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp2_RSLTKEY)))
		  exec absp_Util_LogIt @message ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
		  execute absp_AddLockInfo @tblName, @fldName, @lp2_RSLTKEY, @tempPath  
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
			-- add entries to #LOCKINFO
          --print ' inside absp_GetBadBlobKeyLockInfos - @lp3_MSTRCNT = '+rtrim(ltrim(str(@lp3_MSTRCNT))) +  ', @lp3_RSLTCNT = '+rtrim(ltrim(str(@lp3_RSLTCNT))); 
          --print ' inside absp_GetBadBlobKeyLockInfos - @lp3_MSTRKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp3_MSTRKEY)))
          set @message = ' inside absp_GetBadBlobKeyLockInfos - @lp3_MSTRKEY: get LockInfo for  '+@tblName+':'+@fldName+' = '+rtrim(ltrim(str(@lp3_MSTRKEY)))
		  exec absp_Util_LogIt @message ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
		  execute absp_AddLockInfo @tblName, @fldName, @lp3_MSTRKEY, @tempPath   
		  fetch next from @lp3 into @lp3_MSTRKEY,@lp3_MSTRCNT,@lp3_RSLTCNT
	   end
	   close @lp3
	   deallocate @lp3
       
       delete from #RSLTKEYS
       delete from #MSTRKEYS    
	   
       fetch next from lp1 into @tblName,@fldName
   end
   close lp1
   deallocate lp1

   --print 'absp_GetBadBlobKeyLockInfo: ending'
   --print '   '
   exec absp_Util_LogIt 'absp_GetBadBlobKeyLockInfo: ending' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
   exec absp_Util_LogIt '===========================================' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath
   exec absp_Util_LogIt '   ' ,1 ,'absp_GetBadBlobKeyLockInfos' , @tempPath

end