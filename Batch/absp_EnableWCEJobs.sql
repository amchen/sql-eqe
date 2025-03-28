if exists(select * from SYSOBJECTS where ID = object_id(N'absp_EnableWCEJobs') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_EnableWCEJobs
end
go

create procedure absp_EnableWCEJobs
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQLServer

Purpose:		This procedure enables all WCE jobs in the database.

Returns:        Nothing.
====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin


-- we no longer have SQL Agent Jobs, just return
return


	set nocount on
	declare @run_value int
	declare @Job_Name varchar(255)
	declare @CUR_ENABLE_WCE_JOBS cursor
	declare @sql char(8000)

	set @CUR_ENABLE_WCE_JOBS = cursor fast_forward for select name from msdb.dbo.sysjobs where name like 'absev%' and enabled <> 1
	  open @CUR_ENABLE_WCE_JOBS
	  fetch next from @CUR_ENABLE_WCE_JOBS into @Job_Name
	  while @@FETCH_STATUS = 0
	  begin
		set @sql =  'msdb.dbo.sp_update_job	@job_name = N''' + @Job_Name +''', @enabled = 1'
 		execute(@sql)
		fetch next from @CUR_ENABLE_WCE_JOBS INTO @Job_Name
	  end
	  close @CUR_ENABLE_WCE_JOBS
	  deallocate @CUR_ENABLE_WCE_JOBS
	  execute absp_Util_Sleep 2000
end
