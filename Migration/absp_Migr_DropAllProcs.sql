if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_DropAllProcs') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_DropAllProcs
end

go

create procedure absp_Migr_DropAllProcs 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

		This procedure drops all procs (except itself), events, triggers, and views. 

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END
*/
begin
  set nocount on
  
  /*
  This proc drops all DBA owned procs (except itself), events, triggers, and views
  */
   declare @sql varchar(max)
   declare @name varchar(max)
   declare @executeFlag int
   declare @absev_curs_event_name varchar(255)
   declare @tr_curs_NAME varchar(255)
   declare @absp_curs_NAME varchar(255)
   declare @absp_FN_curs_NAME varchar(255)
   declare @absvw_curs_NAME varchar(255)
   
   set @executeFlag = 1
   print GetDate()
   print ': absp_Migr_DropAllProcs - Begin'
   
    -- events
   if exists(select 1 from sysobjects where name = 'absp_Enable_All_System_Events' and type = 'P')
   begin
      execute absp_Enable_All_System_Events 0
      execute absp_Enable_All_System_Events 0
   end
    ---
    
   declare absev_curs  cursor fast_forward for select rtrim(ltrim(NAME)) as EVENTNAME from msdb.dbo.sysjobs where NAME like '%absev_Arc_Monitor_Disk%'
   open absev_curs
   fetch next from absev_curs into @absev_curs_event_name
   while @@fetch_status = 0
   begin
	-- Drop The Jobs --
	set @sql = 'msdb.dbo.sp_delete_job  @job_name = N''' + @absev_curs_event_name + ''''
	print GetDate()
        print ': '+@sql
        if(@executeFlag = 1)
        begin
           execute(@sql)
        end
	fetch next from absev_curs into @absev_curs_event_name
    end
    close absev_curs
    deallocate absev_curs

  -- end of the events cursor
  -- triggers
   declare tr_curs cursor fast_forward for select NAME from sysobjects where TYPE = 'TR' and UID = 1
   open tr_curs
   fetch next from tr_curs into @tr_curs_NAME
   while @@fetch_status = 0
   begin
      set @name = isnull(@tr_curs_NAME,'')
      if(len(@name) > 1)
      begin
         set @sql = 'drop trigger '+@name
         print GetDate()
         print ': '+@sql
         if(@executeFlag = 1)
         begin
            execute(@sql)
         end
      end
      fetch next from tr_curs into @tr_curs_NAME
   end
   close tr_curs
   deallocate tr_curs
   
  -- end of the triggers cursor
  -- procedures
   declare absp_curs  cursor fast_forward for select NAME from sysobjects where TYPE = 'P' and UID = 1
   open absp_curs
   fetch next from absp_curs into @absp_curs_NAME
   while @@fetch_status = 0
   begin
      if(@absp_curs_NAME <> 'absp_Migr_DropAllProcs')
      begin
         set @sql = 'drop procedure '+@absp_curs_NAME
         print GetDate()
         print ': '+@sql
         if(@executeFlag = 1)
         begin
            execute(@sql)
         end
      end
      fetch next from absp_curs into @absp_curs_NAME
   end
   close absp_curs
   deallocate absp_curs
  -- end of the procedures cursor
  -- function
     declare absp_FN_curs cursor fast_forward for select NAME from sysobjects where TYPE = 'FN' and UID = 1
     open absp_FN_curs
     fetch next from absp_FN_curs into @absp_FN_curs_NAME
     while @@fetch_status = 0
     begin
        if(@absp_FN_curs_NAME <> 'absp_Migr_DropAllFunctions')
        begin
           set @sql = 'drop function '+@absp_FN_curs_NAME
           print GetDate()
           print ': '+@sql
           if(@executeFlag = 1)
           begin
              execute(@sql)
           end
        end
        fetch next from absp_FN_curs into @absp_FN_curs_NAME
     end
     close absp_FN_curs
     deallocate absp_FN_curs
  -- end of the function cursor
  
  -- views
   declare absvw_curs cursor fast_forward for select NAME from sysobjects where TYPE = 'V' and UID = 1
   open absvw_curs
   fetch next from absvw_curs into @absvw_curs_NAME
   while @@fetch_status = 0
   begin
      set @sql = 'drop view '+@absvw_curs_NAME
      print GetDate()
      print ': '+@sql
      if(@executeFlag = 1)
      begin
         execute(@sql)
      end
      fetch next from absvw_curs into @absvw_curs_NAME
   end
   close absvw_curs
   deallocate absvw_curs
  -- end of the views cursor
   print GetDate()
   print ': absp_Migr_DropAllProcs - End'
end


