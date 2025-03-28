if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_getTaskInfo') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getTaskInfo
end
go
 
create procedure absp_getTaskInfo @taskKey int = 0, @criteria varchar(1000) = ''
as 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the all entries (taskKey=0) or specific entry (given specific taskKey) 
			   from TaskInfo plus the task nodeType definition, node display name and database name. 
			   This procedure will be used by the Task service to get the Task Info from the TaskInfo table.

Returns:      TaskInfo + nodeType definition, node display name, dbName

====================================================================================================
</pre>
</font>
##BD_END
##PD  @taskKey   ^^  The key for the task.
##PD  @criteria  ^^  query criteria: where clause + order by clause as necessary
*/
begin
	set nocount on
	declare @nodeDispName varchar(1000) 
	declare @nodeTypeName varchar(80)
	declare @nodeType int
	declare @taskDbRefKey int
	declare @rdbInfoKey int
	declare @taskDbName varchar(120)
	declare @sql nvarchar(max)
	
    -- taskkey =0, meaning get all task entries in TaskInfo
	if @taskKey = 0
	begin
		-- create #TaskInfo_Temp table structure
		IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.#TaskInfo_Temp') AND type in (N'U'))
		DROP TABLE dbo.#TaskInfo_Temp

		CREATE TABLE dbo.#TaskInfo_Temp(
			TaskKey int NOT NULL PRIMARY KEY,
			TaskTypeID int NULL,UserKey int NULL,SessionID int NULL, NodeType int NULL, DBRefKey int NULL default(0),
			FolderKey int NULL default(0),AportKey int NULL default(0),PportKey int NULL default(0),ExposureKey int NULL default(0),AccountKey int NULL default(0), 
			PolicyKey int NULL default(0),SiteKey int NULL default(0),RportKey int NULL default(0),ProgramKey int NULL default(0),CaseKey int NULL default(0),
			StartDate varchar(14) NULL default(''),Status varchar(20) NULL  default(''),TaskOptions varchar(max) NULL  default(''),
			TaskDetailDescription varchar(max) NULL default(''),TaskDBProcessID int NULL default(0),RdbInfoKey int NULL default(0),DownloadKey int NULL default(0),
			NodeTypeName varchar(80) default(''), NodeDispName varchar(1000) default(''), TaskDbName varchar(120) default('') 
		)

		declare curs cursor for
		select TaskKey, DBRefKey, NodeType, RdbInfoKey from commondb..TaskInfo
		open curs
		fetch curs into @taskKey, @taskDbRefKey, @nodeType, @rdbInfoKey
		while @@fetch_status=0
		begin
			if @taskDbRefKey > 0
			begin
				if @rdbInfoKey > 0
					set @sql = 'select  @taskDbName = cast(SDB.name as varchar(120))from sys.databases SDB ' + 
					'inner join sys.master_files SMF on SDB.database_id = SMF.database_id where SMF.file_id = 1 ' +
					'and SDB.state_desc = ''online'' and SDB.database_id = ' + rtrim(str(@taskDbRefKey))
			else	
					set @sql = 'select @taskDbName = DB_NAME from cfldrInfo where cf_ref_key = ' + rtrim(str(@taskDbRefKey))
				
				execute sp_executesql @sql,N'@taskDbName varchar(120) output',@taskDbName  output;
			end
			else
			begin	
				set @taskDbName =  ltrim(rtrim(DB_NAME()))
			end
			
			--set @sql = 'select * from #TaskInfo_Temp '
			--execute sp_executesql @qry,N'@nodeDispName varchar(1000) output',@nodeDispName  output;
			-- Get the node display name for the current task
			exec absp_getNodeDisplayName @nodeDispName out, @taskDbName, 0, @taskKey
			select @nodeTypeName = node_Name from dbo.NodeDef where Node_Type = (select NodeType from TaskInfo where TaskKey = @taskKey)
			insert into #TaskInfo_Temp select dbo.TaskInfo.*, rtrim(isnull(@nodeTypeName, '')), rtrim(isnull(@nodeDispName, '')), rtrim(@taskDbName)	from TaskInfo with(nolock) where TaskKey = @taskKey
			
			fetch curs into @taskKey, @taskDbRefKey, @nodeType, @rdbInfoKey
		end
		close curs
		deallocate curs
		set @criteria = replace(@criteria, 'TaskInfo', '#TaskInfo_Temp');
		set @sql = 'select * from #TaskInfo_Temp ' + @criteria
		execute(@sql)
	end	
	-- by specific taskKey
	else
	begin
	    select @taskDbRefKey = DBRefKey from TaskInfo where TaskKey = @taskKey

		if @taskDbRefKey > 0
		begin
			if @rdbInfoKey > 0
				set @sql = 'select @taskDbName = cast(SDB.name as varchar(120))from sys.databases SDB ' + 
				'inner join sys.master_files SMF on SDB.database_id = SMF.database_id where SMF.file_id = 1 ' +
				'and SDB.state_desc = ''online'' and SDB.database_id = ' + rtrim(str(@taskDbRefKey))
			else
				set @sql = 'select @taskDbName = DB_NAME from cfldrInfo where cf_ref_key = ' + rtrim(str(@taskDbRefKey))
			
			execute sp_executesql @sql,N'@taskDbName varchar(120) output',@taskDbName  output;
		end
		else	
			set @taskDbName =  ltrim(rtrim(DB_NAME()))

			
		-- Get the node display name for the current task
		exec absp_getNodeDisplayName @nodeDispName out, @taskDbName, 0, @taskKey
		select @nodeTypeName = node_Name from dbo.NodeDef where Node_Type = (select NodeType from TaskInfo where TaskKey = @taskKey)
		set @sql = 'select dbo.TaskInfo.*, ''' + isnull(@nodeTypeName, '')+ ''' as NodeTypeName,''' +
					isnull(@nodeDispName, '') + ''' as NodeDispName,''' + isnull(@taskDbName, '') +  ''' as TaskDbName '+ 
				   ' from TaskInfo with(nolock) where TaskKey = ' + rtrim(str(@taskKey)) + ' ' +  @criteria
		execute(@sql)

	end
end
