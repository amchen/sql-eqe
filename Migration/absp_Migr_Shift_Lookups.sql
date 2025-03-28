if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_Shift_Lookups') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_Shift_Lookups
end

go

create procedure absp_Migr_Shift_Lookups @theMode int,@tablename varchar(120),@sysMin int,@sysMax int,@colname varchar(120) = 'COVER_ID',@cntry_id char(3) = '@@@',@lookup_id int = 0,@debugFlag int = 1 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts mapping data into the mapping table or updates the column
of the given table with the mapping data based on theMode flag and the given range.


Returns:       nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  @theMode    ^^ An integer value based on which the mappings are created or migration is done.
##PD  @tablename  ^^ The name of the table for which the migration will be done..
##PD  @sysMin     ^^ An minimum value for the id reserved for the system.
##PD  @sysMax     ^^ An maximum value for the id reserved for the system.
##PD  @colname    ^^ The name of the column for the given table which is to be updated.
##PD  @cntry_id   ^^ The country id.
##PD  @lookup_id  ^^ the value of the given column name which is to be updated.
##PD  @debugFlag  ^^ An integer value for the debug flag.

*/
as
begin

set nocount on
  /*
  Mode    0 = create mapping table, DO NOT fix lookup table

  ie. call absp_Migr_Shift_Lookups(0, 'BNL');
  call absp_Migr_Shift_Lookups(0, 'CIL');
  call absp_Migr_Shift_Lookups(0, 'LTL');

  1 = create mapping table, fix lookup table

  ie. call absp_Migr_Shift_Lookups(1, 'BNL');
  call absp_Migr_Shift_Lookups(1, 'CIL');
  call absp_Migr_Shift_Lookups(1, 'LTL');

  2 = only gather statistics for remapping portfolio table

  ie. call absp_Migr_Shift_Lookups(2, 'SLIC', 'COVER_ID');
  call absp_Migr_Shift_Lookups(2, 'SLIC', 'LIMIT_ID');

  3 = perform remapping portfolio table

  ie. call absp_Migr_Shift_Lookups(3, 'SLIC', 'COVER_ID');
  call absp_Migr_Shift_Lookups(3, 'SLIC', 'LIMIT_ID');

  4 = create case when-then statement

  5 = execute case when-then statement

  Migration 5-1082: Customer lookup data is within system reserved TRANS_ID range

  a)  For each table in the LOOKUP group, we would need to figure out whether or
  not there are any entries in the reserved area:  

  e.g. select count(*) from CIL where TRANS_ID not in (0, 57, 58, 59,10000) and COVER_ID between 900 and 1900;
  (obviously this will need to be table driven from DICTLOOK rather than hardwired.

  b)  If count is 0, there is nothing to do.  Go onto the next table.

  c)  If count is > 0, then there is work to do. 

  1)  Build a temporary non-unique index on the PORT_ID and the field to be
  updated in the appropriate PORTFOLIO Table (SLIC.COVER_ID for this case).
  2)  Build the list of COVER_IDs that are in the reserved area of the lookup table.
  (Note:  We should probably create a little temporary mapping table that lists the
  bad IDs and the numbers that they are being changed to (Step 4 below) that
  we can leave in the database for traceability in case something goes wrong
  e.g. tablename is something like defect_10345_SLIC_MAP.  This will also help
  for debug and QA)
  3)  For each COVER_ID in 2), you need to find the next available COVER_ID in the User
  area of the table (this entry could be below or above the system area of the system
  area of the table).
  4)  Issue an update and commit to the Lookup table to change the COVER_ID to the new number.
  4a) Build the list of PORT_IDs that you will need to update
  (e.g. select DISTINCT PORT_ID from SLIC where SLIC.COVER_ID = "?" and PORT_ID > 0;)
  5)  Loop over PORT_IDs from 4a in the SLIC table and issue an update and commit as you
  change the COVER_IDs in that table until all Odd PORT_IDs have been processed.
  6)  Return to Step 3 for the next COVER_ID and repeat steps 3 through 6 until all
  COVER_IDs have been fixed.
  7)  Drop the temporary Index created in Step 1.

  d)  Return to Step a) and process the next table, continue until all tables are fixed up.

  */
  -- standard declares
   -- my name
   -- for messaging
   
   declare @me varchar(max) -- we do a lot of sql type work
   declare @debug int -- we do a lot of sql type work
   declare @sql nvarchar(4000) -- we do a lot of sql type work
   declare @sql2 nvarchar(4000) -- we do a lot of sql type work
  -- put other variables under here
   declare @sql3 varchar(max) -- generic loop counter as example
   declare @sql4 varchar(max)
   declare @i int
   declare @odd int
   declare @next_id int
   declare @oid int
   declare @pid int
   declare @maptbl varchar(max)
   declare @cnt int
   declare @min int
   declare @max int
   declare @umin int
   declare @umax int
   declare @tblname char(120)
   declare @exists int
   declare @syscnt int
   declare @startTime datetime
   declare @strTime char(20)
   declare @country_tbls varchar(max)
   declare @country_flag int
   declare @inlist varchar(max)
   declare @new_id int
   declare @msgText varchar(255)
   declare @cursMigr_TN varchar(255)
   declare @cursMigr_CN varchar(255)
   declare @cursMigr_OID varchar(255)
   declare @qry varchar(255)
   declare @curs4_lid varchar(255)
   declare @tempstr varchar(512)
   declare @temp_sql varchar(1024)

  -- initialize standard items
   set @maptbl = 'MIGR_LOOKUP_MAP'
   set @me = 'absp_Migr_Shift_Lookups: ' -- set to my name
   set @debug = @debugFlag -- initialize
   set @i = 0
  -- set flag if lookup table has COUNTRY_ID
   set @country_flag = 0
   /*
   select @country_tbls = list(distinct rtrim(ltrim(dc.tablename)))  
   from DICTCOL as dc,DICTLOOK as dl where
   dc.fieldname = 'COUNTRY_ID' and dc.tablename = dl.tablename
   */
   set @temp_sql = 'select distinct rtrim(ltrim(dc.tablename))  
   from DICTCOL as dc,DICTLOOK as dl where
   dc.fieldname = ''COUNTRY_ID'' and dc.tablename = dl.tablename '

   exec absp_util_geninlist @tempstr out, @temp_sql 

   set @tempstr = ltrim(rtrim(@tempstr))
   set @tempstr = right(@tempstr,len(@tempstr)-5)--trim off the firt ' in ( '
   set @country_tbls = ltrim(rtrim(left(@tempstr,len(@tempstr)-1))) -- trim off the trailing ')'
	
   if ltrim(rtrim(@country_tbls))='-2147000000'
   begin
	set @country_tbls= ''
   end

	
   set @country_flag = CHARINDEX(@tablename,@country_tbls)
  ------------ begin --------------------
   if @debug > 0
   begin
      set @msgText = @me+'starting mode = '+rtrim(ltrim(str(@theMode)))
      execute absp_MessageEx2 @msgText
   end
  -- Mode 0 or 1, create mapping table --
   if(@theMode = 0 or @theMode = 1)
   begin
    -- create map table
      if not exists(select 1 from sys.tables where name = 'MIGR_LOOKUP_MAP')
      begin
         set @sql = ' create table '+@maptbl+'(TBL char(70), COL char(70), OLD_ID int, NEW_ID int)'
         if @debug > 0
         begin
            execute absp_MessageEx2 @sql
         end
         execute(@sql)
         
         set @sql = ' create index '+@maptbl+'_IDX on '+@maptbl+'(TBL, COL, OLD_ID)'
         if @debug > 0
         begin
            execute absp_MessageEx2 @sql
         end
         execute(@sql)
		 
         
      end
    /*
    -- delete existing entries
    set @sql = 'delete from ' + @maptbl + ' where TBL = ''' + tablename + '''';
    if @debug > 0 then
    call absp_MessageEx2 (@sql);
    end if;
    execute immediate @sql;
    commit;
    */
    -- Build map table entries
      if exists(select 1 from SYS.TABLES where name = 'MIGR_LOOKUP_MAP')
      begin
      
	 -- get reserved system ranges
         set @sql = 'select @colname = EQEUNQ, @min = SYSID_MIN, @max = SYSID_MAX, @umin = UIDMIN,  @umax = UIDMAX from DICTLOOK '
         set @sql = @sql+'where TABLENAME = '''+rtrim(ltrim(@tablename))+''''
         if @debug > 0
         begin
            execute absp_MessageEx2 @sql
         end
        exec sp_executesql @sql,N'@colname char(70) out,@min int out,@max int out,@umin int out,@umax int out',@colname  out,@min  out,@max  out,@umin  out,@umax out
        			
	 -- get lookups within system range
         set @cnt = 0
         -- use parameters
         set @sql = 'select @cnt = count(*) from ' + @tablename
		 set @sql = @sql+' where TRANS_ID not in (0, 57, 58,59, 10000) and '
		 set @sql = @sql+@colname+' between '+rtrim(ltrim(str(@sysMin)))+' and '+rtrim(ltrim(str(@sysMax)))
		 
         if @debug > 0
         begin
            execute absp_MessageEx2 @sql
         end
         exec sp_executesql @sql, N'@cnt int out',@cnt out
        
	 if @cnt > 0
         begin
        -- 'check @country_flag'
			
	    if @country_flag = 0
            begin
		   set @sql = 'insert into ' + @maptbl + ' select '''+rtrim(ltrim(@tablename))+''','''+rtrim(ltrim(@colname))+''','
               	   set @sql = @sql+rtrim(ltrim(@colname))+',-99 from '+@tablename
               	   set @sql = @sql+' where TRANS_ID not in (0, 57, 58,59, 10000) and '
		   set @sql = @sql+@colname+' between '+rtrim(ltrim(str(@sysMin)))+' and '+rtrim(ltrim(str(@sysMax)))
		   set @sql = @sql+' order by '+@colname
            end
            else
            begin
          -- add COUNTRY_ID to where clause
		
               set @sql = 'insert into '+@maptbl+' select '''+rtrim(ltrim(@tablename))+''','''+rtrim(ltrim(@colname))+''','
               set @sql = @sql+rtrim(ltrim(@colname))+',-99 from '+@tablename
               set @sql = @sql+' where TRANS_ID not in (0, 57, 58,59, 10000) and '
               set @sql = @sql+@colname+' between '+rtrim(ltrim(str(@sysMin)))+' and '+rtrim(ltrim(str(@sysMax)))
               set @sql = @sql+' and COUNTRY_ID = '''+rtrim(ltrim(@cntry_id))+''''
               set @sql = @sql+' order by '+@colname
			
            end
            if @debug > 0
            begin
               execute absp_MessageEx2 @sql
            end
			
            execute(@sql)
			
            print 'get next available id that is within the user range but less than the minimum system range'
        -- get next available id that is within the user range but less than the minimum system range
			
            set @sql = 'select @next_id = cast(max('+@colname+') as int) + 1  from '+@tablename
			
	        set @sql = @sql+' where '+@colname+' < '+str(@min)
			
            if @debug > 0
            begin
               execute absp_MessageEx2 @sql
            end
            exec sp_executesql @sql,N'@next_id int out' ,@next_id out
            			
        -- make sure @next_id is not NULL
            set @next_id = isnull(@next_id,1)
				
        -- double check if next available id is valid, otherwise get next id greater than system range
            
	    if @next_id >= @min
            begin
				
               set @sql = 'select @next_id = cast(max('+@colname+') as int) + 1 from '+@tablename
               set @sql = @sql+' where '+@colname+' > '+str(@max)
				
               if @debug > 0
               begin
                  execute absp_MessageEx2 @sql
               end
               exec sp_executesql @sql,N'@next_id int out',@next_id out
               
            end
        -- loop thru lookup table
        
          -- make sure @next_id skips over system range if necessary
            declare cursMigr cursor fast_forward for select TBL ,COL ,OLD_ID  from MIGR_LOOKUP_MAP where NEW_ID = -99
            open cursMigr
            fetch next from cursMigr into @cursMigr_TN,@cursMigr_CN,@cursMigr_OID
            while @@fetch_status = 0
            begin
               if(@next_id >= @min and @next_id <= @max)
               begin
                  set @sql = 'select @next_id = cast(max('+@colname+') as int) + 1  from '+@tablename
                  set @sql = @sql+' where '+@colname+' > '+str(@max)
                  if @debug > 0
                  begin
                     execute absp_MessageEx2 @sql
                  end
                  exec sp_executesql @sql, N'@next_id int out', @next_id out                  
               end
          -- make sure @next_id is not NULL
               set @next_id = ISNULL(@next_id,@max+1)
			
          -- output message if @next_id is > user max
               if(@next_id > @umax)
               begin
                  set @sql = '**** ERROR: @next_id = '+cast(@next_id as CHAR)+' for '+@tablename+'.'+@colname
                  set @sql = @sql+' exceeds the user id maximum value of '+str(@umax)+' ****'
                  
                  execute absp_MessageEx2 @sql
               end
               else
               begin
                  set @sql = 'update '+@maptbl+' set NEW_ID = '+rtrim(ltrim(str(@next_id)))
                  set @sql = @sql+' where OLD_ID = '+rtrim(ltrim(str(@cursMigr_OID)))
                  
					if @debug > 0
                  begin
                     execute absp_MessageEx2 @sql
                  end
                  execute(@sql)
                  
                  if(@theMode = 1)
                  begin
              -- remap the ids in the lookup table
                     set @sql = 'update '+@cursMigr_TN+' set '+@cursMigr_CN+' = '+rtrim(ltrim(str(@next_id)))
                     set @sql = @sql+' where '+@cursMigr_CN+' = '+rtrim(ltrim(str(@cursMigr_OID)))
                     if @debug > 0
                     begin
                        EXECUTE absp_MessageEx2 @sql
                     end
                     execute(@sql)
                     
                  end
                  set @next_id = @next_id+1
               end
               fetch next from cursMigr into @cursMigr_TN,@cursMigr_CN,@cursMigr_OID
            end
            close cursMigr
			deallocate cursMigr
         end
      end
   end
  -- Mode 2 or 3, remap old id to new id --
   if(@theMode = 2 or @theMode = 3)
   begin
      select  @cnt  = count(*)  from MIGR_LOOKUP_MAP where col = @colname
          
      if @cnt > 0
      begin
      -- gather statistics only
         if @theMode = 2
         begin
        -- get lookup table name and lookup id
			
            set @sql2 = 'select @tblname = TBL from MIGR_LOOKUP_MAP where '
            set @sql2 = @sql2+'COL = ''' + @colname + ''' and '
            set @sql2 = @sql2+'OLD_ID = '+str(@lookup_id)
			
            if @debug > 0
            begin
               execute absp_MessageEx2 @sql2
            end
            select @tblname = TBL from MIGR_LOOKUP_MAP where COL = @colname and OLD_ID =@lookup_id
            
        -- get table count from system table
            select @syscnt =ROWCNT from SYSINDEXES where object_name(id)=@tablename and INDID<2
            
        /*
        -- get actual lookup id count from reference table
        set @sql2 = 'select count(*) into @cnt from ' + tablename + ' ';
        set @sql2 = @sql2 + 'where ' + colname + ' = ' + cast(lookup_id as char);
        if @debug > 0 then
        call absp_MessageEx2 (@sql2);
        end if;
        call absp_Util_ElapsedTime(@startTime);
        execute immediate @sql2; commit;
        @strTime = call absp_Util_ElapsedTime(@startTime);
        */
			
            set @sql2 = 'insert into MIGR_LOOKUP_STAT values( ''' + @tblname + ''' , ''' + @colname + ''','''+ cast(@lookup_id as CHAR)
            set @sql2 = @sql2+ ''',''' + @tablename + ''',''' + cast(@syscnt as char) + ''',0,'''')'
			
            if @debug > 0
            begin
               execute absp_MessageEx2 @sql2
            end
            insert into MIGR_LOOKUP_STAT values(@tblname , @colname,@lookup_id , @tablename ,@syscnt,0,'')
            
         end
      -- do the actual update
		
         if @theMode = 3
         begin
        -- update by chunking on odd PORT_ID if it exists
            set @exists = 0
            select @exists = count(*) from DICTCOL where TABLENAME =@tablename and FIELDNAME = 'PORT_ID'
            	
            if(@exists > 0)
            begin
               set @sql = 'select distinct PORT_ID from '+@tablename
               begin
                  execute('declare cursPort  cursor  global for '+@sql)		
                  open cursPort 
                  fetch next FROM cursPort into @pid
                  while @@fetch_status <> 0
                  begin
                     -- check for odd PORT_ID
                     set @odd = @pid%2
                     if @odd = 1
                     begin
                        -- update by PORT_ID
					
                        set @sql2 = 'update '+@tablename
                        set @sql2 = @sql2+' set '+ltrim(rtrim(@colname))+' = m.NEW_ID from MIGR_LOOKUP_MAP as m where '
                        set @sql2 = @sql2+'m.OLD_ID = '+ltrim(rtrim(@colname))+' and '
                        set @sql2 = @sql2+'m.COL = '''+ltrim(rtrim(@colname))+''' and '
                        set @sql2 = @sql2+'PORT_ID = '+rtrim(ltrim(str(@pid)))
                        if @debug > 0
                        begin
                           execute absp_MessageEx2 @sql2
                        end
					
			          execute(@sql2)
					
                     end
                     fetch next FROM cursPort into @pid
                  end
                  close cursPort 
		          deallocate cursPort 
               end
            end
            else
            begin
          -- update without PORT_ID
			
               set @sql2 = 'update '+@tablename 
               set @sql2 = @sql2+' set ' +ltrim(rtrim(@colname))+' = m.NEW_ID from MIGR_LOOKUP_MAP as m where '
               set @sql2 = @sql2+'m.OLD_ID = '+ltrim(rtrim(@colname))+' and '
               set @sql2 = @sql2+'m.COL = '''+ltrim(rtrim(@colname))+''''
            
			
			   if @debug > 0
               begin
                  execute absp_MessageEx2 @sql2
               end
               execute(@sql2)
            
            end
         end
      end
   end
  -- Mode 4 or 5, case when-then --

   if(@theMode = 4 or @theMode = 5)
   begin
      set @qry = 'select distinct lookup_id as lid from MIGR_LOOKUP_STAT where ref_tbl = '''+@tablename+''' and field_name = '''+@colname+''''
      execute absp_Util_GenInList @inlist out, @qry
    
	  set @sql2 = ''
      -- build the when-then statements
    
      -- get the new_id from the MAP table
      declare cursMigrLkupStat cursor for select distinct @lookup_id  from MIGR_LOOKUP_STAT where REF_TBL = @tablename and FIELD_NAME = @colname
      open cursMigrLkupStat 
      fetch next from cursMigrLkupStat  into @curs4_lid
      while @@fetch_status = 0
      begin
      		 select   @new_id = NEW_ID  from MIGR_LOOKUP_MAP where OLD_ID = @curs4_lid and COL = @colname
       		 set @sql2 = @sql2+' when '+@colname+' = '+cast(@curs4_lid as char)+' then '+cast(@new_id as char)
         	 fetch next from cursMigrLkupStat  into @curs4_lid
      end
      close cursMigrLkupStat 
	  deallocate cursMigrLkupStat 

    -- build the complete update statement
      set @sql3 = 'update '+@tablename+' set '+@colname+' = ( case '+@sql2+' else '+@colname+' end ) where '+@colname+' '+@inlist
    -- update by chunking on odd PORT_ID if it exists
      set @exists = 0
      select @exists = count(*) from DICTCOL where TABLENAME = @tablename and FIELDNAME = 'PORT_ID' 	  
      if(@exists > 0)
      begin
         set @sql = 'select distinct PORT_ID from '+@tablename
         begin
            execute('declare curs5 cursor global for '+@sql)
            open curs5 
            fetch next from curs5 into @pid
            while @@Fetch_status =0
            begin
               -- check for odd PORT_ID
               set @odd = @pid%2
               if @odd = 1
               begin
                  -- update by PORT_ID
                  set @sql4 = @sql3+' and PORT_ID = '+rtrim(ltrim(str(@pid)))
                  if @debug > 0
                  begin
                     execute absp_MessageEx2 @sql4
                  end
            -- do the actual update
                  if @theMode = 5
                  begin
                     execute(@sql4)
                  end
               end
               fetch next from curs5 into @pid
            end
            close curs5
	    deallocate curs5
         end
      end
      else
      begin
      -- update without PORT_ID
         if @debug > 0
         begin
            execute absp_MessageEx2 @sql3
         end
      -- do the actual update
         if @theMode = 5
         begin
            execute(@sql3)
            
         end
      end
   end
  ------------- end ---------------------
   if @debug > 0
   begin
      set @msgText = @me+'complete'
      execute absp_MessageEx2 @msgText
   end
end
