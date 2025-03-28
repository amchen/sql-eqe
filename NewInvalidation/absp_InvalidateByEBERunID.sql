if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateByEBERunID') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateByEBERunID
end
go

create  procedure absp_InvalidateByEBERunID
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
Purpose:  The procedures will invalidate By EBERunID.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END
	@NodeKey= NodeKey passed in by absp_InvalidateResults. 
	@NodeType NodeKey passed in by absp_InvalidateResults. 
	@invalidateIR: Always set to 1 for EBERunID.
	@invalidateExposureReport: If the invalidate is due to a change in Exposure Set information then we need to invalidate the Exposure Report tables 
		otherwise do not invalidate those tables.

 */
as
BEGIN TRY
	set nocount on

	declare @sqlQuery varchar(max)
	declare @curs_TblName varchar(max)
	declare @ExposureKey int
	declare @taskProgressMsg varchar(max);
	declare @procID int;
               	
   	-- Get the Procedure ID and the TaskKey since we need to add entries to TaskProgress
   	set @procID = @@PROCID;
            
   	-- Add a task progress message
   	set @taskProgressMsg = 'Invalidation started.';
   	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	declare curs cursor fast_forward for
	select TABLENAME from dbo.absp_Util_GetTableList('Inv.ELT.Res')
	open curs
	fetch next from curs into @curs_TblName
	while @@fetch_status = 0
	begin
		-- Add a task progress message
		set @taskProgressMsg = 'Invalidating table: ' + rtrim(ltrim(@curs_TblName));
		exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;
	
		set @sqlQuery='Update '+@curs_TblName+' set STATUS = ''DELETED'' where EBERunID = '+dbo.trim(str(@NodeKey));
		execute (@sqlQuery)
	 fetch next from curs into @curs_TblName
	end
	close curs
	deallocate curs 
	
	-- Add a task progress message
	set @taskProgressMsg = 'Invalidation completed successfully.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
go

