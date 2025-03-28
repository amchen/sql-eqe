if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Enable_All_System_Events') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Enable_All_System_Events
end
go

create procedure absp_Enable_All_System_Events @isEnable bit 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This Procedure Enables Or Disables the Events of the System Table. It also Confirms Whether
the events have actually been Enabled Or Disabled Or System is Busy in the Process.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @isEnable ^^ Input Parameter [0 To Disable Events OR 1 To Enable Events]
*/
as
begin

   set nocount on
   
   declare @sql char(8000)
   declare @strEnable int
   declare @strYN int
   declare @bDone bit
   declare @Job_Name varchar(255)
   declare @cur_Evt_Enable cursor
   declare @createDt  char(14)
   
begin try
	begin transaction
	set @bDone = 0

	while (@bDone = 0)
	   begin

		  if @isEnable = 0
			  begin
				 set @strEnable = 0 -- ' disable'
				 set @strYN = 1
				 if exists(select 1 from SYS.TABLES where NAME = 'BKPROP')
					 begin
						if not exists(select 1 from BKPROP where BK_KEY = 'Migration')
							begin
							   exec absp_Util_GetDateString @createDt output,'Mmm dd yyyy hh:nnAA'
							   insert into BKPROP(BK_KEY,BK_VALUE) values('Migration',@createDt)
							end
					 end
			  end
		  else
			  begin
				 set @strEnable = 1 --' enable'
				 set @strYN = 0
				 if exists(select 1 from SYS.TABLES where NAME = 'BKPROP')
					 begin
						delete from BKPROP where BK_KEY = 'Migration'
					 end
			  end

		  set @cur_Evt_Enable = cursor dynamic for select NAME from MSDB.DBO.SYSJOBS where NAME like 'absev%' and ENABLED <> @isEnable order by NAME
			  open @cur_Evt_Enable
			  fetch next from @cur_Evt_Enable INTO @Job_Name
			  while @@FETCH_STATUS = 0
				  begin
					 set @sql = 'msdb.dbo.sp_update_job 	@job_name = N''' + @Job_Name +''', @enabled = ' + Ltrim(Rtrim(Str(@strEnable)))
					 print  @sql
					 execute(@sql)
					 fetch next from @cur_Evt_Enable into @Job_Name
				  end
			  close @cur_Evt_Enable
		      deallocate @cur_Evt_Enable

	      print  @strYN
		if exists(select 1 from sysobjects where name = 'absp_Util_Sleep' and type = 'P')
		  begin
			 Print 'Sleeping'
			 execute absp_Util_Sleep 500
		  end
		  
		-- Check if events have been enabled or disabled completely
		-- If not, goto tryagain:
		  if exists(select 1 from msdb.dbo.SYSJOBS where NAME like 'absev%' and enabled = @strYN)
			  begin
				 print 'Events are busy, trying again'
				 set @bDone = 0
			  end
		  else
			  begin
				 set @bDone = 1
			  end
	   end
	commit transaction
end try

begin catch
	select Error_Line() As Line_No,  Error_Message() As Description,  Error_Number() As Error_No
	rollback tran
end catch
end