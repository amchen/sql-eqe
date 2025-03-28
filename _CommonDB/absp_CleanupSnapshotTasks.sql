if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_CleanupSnapshotTasks') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CleanupSnapshotTasks;
end
go

create procedure absp_CleanupSnapshotTasks

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will and clean up incomplete user snapshots and mark incomplete snapshot 
			generation tasks as FAILED during server startup
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD

*/

as

begin
	set nocount on

	declare @sql nvarchar(max)
	declare @sql2 nvarchar(max)
	declare @dbname varchar(120)

	-- mark tasks as failed
	update TaskStepInfo set[Status] ='FAILED' from 
	TaskStepInfo join TaskInfo on TaskStepInfo.TaskKey=TaskInfo.TaskKey 
	and TaskTypeID = 6 and Taskinfo.[Status] not in ('Completed', 'CANCELLED', 'FAILED') and TaskStepInfo.[Status] not in ('Completed', 'CANCELLED', 'FAILED')
		
	update TaskInfo set [Status] ='FAILED' where TaskTypeID = 6 and Taskinfo.[Status] not in ('Completed', 'CANCELLED', 'FAILED')

	-- clean up incomplete user snapshots	
	set @sql ='use [@databaseName]  ' +
		'declare @snapshotKey int ' +
		'declare @sql nvarchar(max) ' +
		'if OBJECT_ID(N''' + '[@databaseName].dbo.SnapshotInfo'', N''U'') is not NULL ' + 
		'BEGIN ' +
		'declare sscurs cursor fast_forward for ' +
		'select si.snapshotKey from SnapshotInfo si join SnapshotMap sm on si.SnapshotKey = sm.SnapshotKey where [Status] = ''InProgress'' ' +
		'open sscurs ' +
		'fetch next from sscurs into @snapshotKey ' +
		'while @@fetch_status = 0 ' +
		'begin ' +
		'	set @sql = ''exec [@databaseName]..absp_CleanUpUserSnapshot '' + cast(@snapshotKey as varchar(10)) ' +
		'	execute (@sql) ' +
		'	fetch next from sscurs into @snapshotKey ' +    
		'end ' +
		'close sscurs ' +
		'deallocate sscurs ' +
		'END' 
    
	declare dbcurs  cursor fast_forward for select distinct DB_NAME from CFLDRINFO
	open dbcurs
	fetch next from dbcurs into @dbname
	while @@fetch_status = 0
	begin
		set @sql2 = replace(@sql, '@databaseName', @dbName)
		--print @sql2		
		-- clean up incomplete user snapshots
		execute (@sql2)
		fetch next from dbcurs into @dbname     
	end
	close dbcurs
	deallocate dbcurs
end