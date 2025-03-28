if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_SetPortAttributeAtStartUp') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_SetPortAttributeAtStartUp
end
go

create  procedure absp_SetPortAttributeAtStartUp
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose: 	The procedure will set the pport/program Invalidating attribute of all 
		attached databases to 0 during Server Startup.

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

*/
as
begin	
	set nocount on
	
	declare @pportkey int
	declare @progkey int
	declare @dbName varchar(130)
	declare @sql varchar(max)
	declare @sql1 varchar(max)
	
	--Get all databases--
	declare curs cursor for select db_Name from cfldrinfo
	open curs 
	fetch curs into @dbName
	while @@FETCH_STATUS =0
	begin
		--Loop through all pports and set Invalidating attribute to 0--
		set @sql='select pport_Key from [' + dbo.trim(@dbName)  +'].dbo.pprtinfo'
		execute('declare curs1 cursor forward_only global for '+@sql)
		open curs1 
		fetch curs1 into @pportkey
		while @@FETCH_STATUS =0
		begin
			set @sql1='exec  [' + dbo.trim(@dbName)  +'].dbo.absp_InfoTableAttribSetInvalidating 2, ' + cast(@pportkey as varchar(20)) + ',0'
			exec (@sql1)
			fetch curs1 into @pportkey
		end
		close curs1
		deallocate curs1
		
		--Loop through all programs and set Invalidating attribute to 0--
		set @sql='select prog_Key from [' + dbo.trim(@dbName)  +'].dbo.proginfo'
		execute('declare curs2 cursor forward_only global for '+@sql)
		open curs2 
		fetch curs2 into @progkey
		while @@FETCH_STATUS =0
		begin
			set @sql1='exec  [' + dbo.trim(@dbName)  +'].dbo.absp_InfoTableAttribSetInvalidating 27, ' + cast(@progkey as varchar(20)) + ',0'
			exec (@sql1)
			fetch curs2 into @progkey
		end
		close curs2
		deallocate curs2

		fetch curs into @dbName
	end
	close curs
	deallocate curs
end


