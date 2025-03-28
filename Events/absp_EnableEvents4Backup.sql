if exists(select 1 from SysObjects where Name = 'absp_EnableEvents4Backup' And Type = 'P')
begin
	drop procedure absp_EnableEvents4Backup
end

go

create procedure absp_EnableEvents4Backup @isEnable bit
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:	    MSQL
Purpose:		This Procedure Enables Or Disables all Jobs of the SysJobs Table except
				absev_BackupDatabase. It also Confirms Whether the events have actually been Enabled
				Or Disabled Or System is Busy in the Process.

Returns:		Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD   isEnable 	^^ Input Parameter [0 To Disable Events OR 1 To Enable Events]

*/
as
begin


-- we no longer have SQL Agent Jobs, just return
return


   set nocount on

   declare @sql varchar(max)
   declare @strEnable int
   declare @strYN int
   declare @bDone bit
   declare @Job_Name varchar(255)
   declare @CUR_EVT_ENABLE cursor

   begin Try
	set @bDone = 0
	while (@bDone = 0)
	begin
	  if @isEnable = 0
	  begin
		 set @strEnable = 0 -- ' disable'
		 set @strYN = 1
	  end
	  else
	  begin
		 set @strEnable = 1 --' enable'
		 set @strYN = 0
	  end

	  set @CUR_EVT_ENABLE = cursor fast_forward for select name from msdb.dbo.sysjobs
	  open @CUR_EVT_ENABLE
	  fetch next from @CUR_EVT_ENABLE into @Job_Name
	  while @@FETCH_STATUS = 0
	  begin
		If Upper(@Job_Name) <> 'ABSEV_BACKUPDATABASE'
		begin
			 set @sql =  'msdb.dbo.sp_update_job	@job_name = N''' + @Job_Name +''', @enabled = ' + Ltrim(Rtrim(Str(@strEnable)))
	 		 execute(@sql)
		end
             	 fetch next from @CUR_EVT_ENABLE INTO @Job_Name
	  end
	  close @CUR_EVT_ENABLE
	  deallocate @CUR_EVT_ENABLE

       	if exists(select 1 from SYSOBJECTS where NAME = 'absp_Util_Sleep' and type = 'P')
         begin
		execute absp_Util_Sleep 500
	  end

	-- Check if events have been enabled or disabled completely
	-- If not, goto tryagain:
	if exists(select 1 from msdb.dbo.sysjobs where enabled = @strYN and NAME <> 'absev_backupDatabase')
	  begin
		 print 'Events are busy, trying again:  '
		 print GetDate()
		 print ' '
		 set @bDone = 0
	  end
  	else
	  begin
		 set @bDone = 1
	  end
   end

 end Try
 begin Catch
	select Error_Line() As Line_No,  Error_Message() As Description,  Error_Number() As Error_No
 end Catch
end




