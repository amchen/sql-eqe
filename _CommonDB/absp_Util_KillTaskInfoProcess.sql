if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_KillTaskInfoProcess') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_KillTaskInfoProcess
end
go

create procedure absp_Util_KillTaskInfoProcess @taskKey int
as
begin try
	declare @TaskDBProcessID int, @SQL nvarchar(20)

	select @TaskDBProcessID=TaskDBProcessID from TASKINFO
		where TaskKey=@taskKey

	--No process to kill if  @TaskDBProcessID=0
	if  @TaskDBProcessID=0 return
	BEGIN
	 SET @SQL = 'KILL ' + CAST(@TaskDBProcessID as nvarchar(10))
	 --print @SQL
	EXEC sp_executeSQL @SQL
	end
end try
begin catch
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
end catch
