if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckIfSQLAgentRunning') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckIfSQLAgentRunning
end
go

create procedure absp_Util_CheckIfSQLAgentRunning
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQL2005

Purpose:		This procedure checks if the SQL Agent is running or not.

Returns:        Returns 1 if the agent is running, 0 if the agent is not running.
====================================================================================================
</pre>
</font>
##BD_END

##RD	@ret_status  ^^  Returns 1 if the agent is running, 0 if the agent is not running.
*/
as
begin

   set nocount on
   
	declare @ret_status int
	declare @doscommand Varchar(300)
	declare @status Varchar(100)
	declare @sidForAgent int;
	declare @sql nvarchar(2000)
	declare @instanceName varchar (256)
    	declare @machinename varchar (256)
	set @ret_status = 0;

	if exists (select * from tempdb..sysobjects where id = object_id('tempdb.dbo.#services'))
		drop table #services
	
	create table #services (sid int identity(1,1), services varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS)
	
	-- SDG__00022108
	-- Using host machine name instead of database server instance name
    	set @machinename = convert(varchar(256),SERVERPROPERTY('MachineName'))
	set @doscommand = 'sc \\'+ @machinename +' query type= service'
	
	insert into #services (services) exec master..xp_cmdshell @doscommand
	
	--SDG__00022093
	set @instanceName = isnull(convert(varchar(256), SERVERPROPERTY('InstanceName')), '')

	if(len(@instanceName) = 0)
	begin
		select @sidForAgent = sid from #services where services like 'DISPLAY_NAME: SQL Server Agent (MSSQLSERVER)';
	end
	else
	begin
		set @sql = N'select @sidForAgent = sid from #services where services like ''DISPLAY_NAME: SQL Server Agent (' + @instanceName +')''';
		exec sp_executeSQL @sql, N'@sidForAgent int output', @sidForAgent output
	end
	print @sidForAgent
	select @status = isNull(services, '') from #services where sid = @sidForAgent + 2 -- the STATE information is always the 3rd row after display.
	
	if (@status != '')
		set @ret_status = 1;
	
	return @ret_status;
end
go