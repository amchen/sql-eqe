if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateByAportKey') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateByAportKey
end
go

create  procedure absp_InvalidateByAportKey  
	@NodeKey int, 
	@invalidateIR int, 
	@invalidateExposureReport int,
	@taskKey int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:  The procedures will invalidate By AportKey.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END
	@NodeKey= NodeKey passed in by absp_InvalidateResults. 
	@NodeType NodeKey passed in by absp_InvalidateResults. 
	@invalidateIR: Always set to 1 for Aport.
	@invalidateExposureReport: If the invalidate is due to a change in Exposure Set information then we need to invalidate the Exposure Report tables 
		otherwise do not invalidate those tables.

 */
as
BEGIN TRY
	set nocount on

	declare @sqlQuery varchar(max)
	declare @curs_TblName varchar(max)
	declare @newNegKey int
	declare @dbName varchar(max)
	declare @irDBName varchar(max)
	declare @KeyField varchar(max)
	declare @WhereNodeType varchar(130)
	declare @taskProgressMsg varchar(max);
	declare @procID int;
   	
	-- Get the Procedure ID and the TaskKey since we need to add entries to TaskProgress
	set @procID = @@PROCID;
	
	-- Add a task progress message
	set @taskProgressMsg = 'Invalidation started.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	set @dbName =DB_NAME();
	exec absp_getDBName  @dbName out, @dbName, 0; -- Enclose within brackets--

	if RIGHT(rtrim(@dbName),4) != '_IR]'
		exec absp_getDBName  @irDBName out, @dbName, 1;
	else
		set @irDBName = @dbName;
		   
	  --Remove Aport results		   
	declare curs cursor fast_forward for
        	select TABLENAME from dbo.absp_Util_GetTableList('Inv.Aport.Res')
	open curs
	fetch next from curs into @curs_TblName
	while @@fetch_status = 0
	begin
	if (@curs_TblName in('ExposureSummaryReport','ExposedLimitsReport')) begin set @KeyField='NodeKey' set @WhereNodeType='and NodeType=1' end else begin set @KeyField='APORT_KEY' set @WhereNodeType='' end
		
		-- Add a task progress message
		set @taskProgressMsg = 'Invalidating table: ' + rtrim(ltrim(@curs_TblName));
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
		
		set @sqlQuery = 'delete from '+rtrim(ltrim(@curs_TblName))+'  where '+@KeyField+' = '+dbo.trim(cast(@NodeKey as varchar(10)))+ @WhereNodeType
		execute dbo.absp_Util_ExecSqlInChunks @sqlQuery
		fetch next from curs into @curs_TblName
	end
	close curs
	deallocate curs 
      
	-- **BEGIN DROP TABLES** --
	declare curs cursor fast_forward for
		select TABLENAME from dbo.absp_Util_GetTableList('Inv.Aport.Res.Drop')
	open curs
	fetch next from curs into @curs_TblName
	while @@fetch_status = 0
		begin
			
			-- Add a task progress message
			set @taskProgressMsg = 'Droping table: ' + rtrim(ltrim(@curs_TblName));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
			
			set @sqlQuery='if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'''+@curs_TblName+'_'+dbo.trim(str(@NodeKey))
			+''') and xtype=''U'') drop table '+@curs_TblName+'_'+dbo.trim(str(@NodeKey))
			execute (@sqlQuery)
		fetch next from curs into @curs_TblName
		end
	close curs
	deallocate curs 

	declare MyCursor cursor fast_forward for
		select TABLENAME from dbo.absp_Util_GetTableList('Inv.Aport.IR.Res.Drop')
	open MyCursor
	fetch next from MyCursor into @curs_TblName
	while @@fetch_status = 0
			begin
				-- Add a task progress message
				set @taskProgressMsg = 'Calling blob discard for table: ' + rtrim(ltrim(@curs_TblName));
				exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
				
				exec absp_BlobDiscard  @curs_TblName, @NodeKey
			fetch next from MyCursor into @curs_TblName
			end
	close MyCursor
	deallocate MyCursor	
	-- **END DROP TABLES** --		
	
	execute absp_InvalidateCommonTables @NodeKey, 1, @invalidateExposureReport,@taskKey;
	
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH

-- Add a task progress message
set @taskProgressMsg = 'Invalidation of accumulation portfolios completed successfully.';
exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	

