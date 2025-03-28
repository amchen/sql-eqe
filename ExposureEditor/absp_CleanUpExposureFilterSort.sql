if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanUpExposureFilterSort') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanUpExposureFilterSort
end
 go

create procedure absp_CleanUpExposureFilterSort @taskKey int, @nodeKey int, @nodeType int, @userKey int =1, @debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will be invoked if a Filter/Sort task is cancelled.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END


*/
as
begin
	set nocount on
	declare @tableName varchar(130);
	declare @filterTableName  varchar(130);
	declare @sql  varchar(max);
	declare @status varchar(20);
	declare @schemaName varchar(100);
	
	create table #ExpTbls (TableName varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS);
	insert into #ExpTbls values('Account');
	insert into #ExpTbls values('AccountReinsurance');
	insert into #ExpTbls values('Policy');
	insert into #ExpTbls values('PolicyCondition');
	insert into #ExpTbls values('PolicyReinsurance');
	insert into #ExpTbls values('SiteReinsurance');
	insert into #ExpTbls values('SiteCondition');
	insert into #ExpTbls values('StructureCondition');
	insert into #ExpTbls values('Structure');	
	insert into #ExpTbls values('StructureCoverage');	
	insert into #ExpTbls values('StructureFeature');
	insert into #ExpTbls values('PolicyFilter');	

	declare c1 cursor for select TableName from #ExpTbls
	open c1
	fetch c1 into @tableName
	while @@fetch_status=0
	begin
		set @filterTableName='Filtered' + @tableName;
		set @tableName=@filterTableName + '_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))

		set @sql='if exists (select 1 from sys.tables where name =''' + @tableName+ ''') drop table ' + @tableName;
		if @debug=1 print @sql
		
		exec (@sql);
		fetch c1 into @tableName
	end;

	close c1;
	deallocate c1;
	
	--Set an attrib bit 
	if @nodeType=2
		select @status=Status from TaskInfo where PportKey=@nodeKey and NodeType=@nodeType and TaskKey=@taskKey;
	else
		select @status=Status from TaskInfo where ProgramKey=@nodeKey and NodeType=@nodeType and TaskKey=@taskKey;
	
	if @status='Failed'
	begin
	    -- reset the BRW_DATA_REGENERATE bit before setting it to fail
	    exec absp_InfoTableAttrib_Set @nodeType, @nodeKey,'BRW_DATA_REGENERATE',0
		exec absp_InfoTableAttribSetBrowserFilterTaskFail @nodeType,@nodeKey,1 
	end
	else 
	begin
		-- reset the BRW_DATA_REGENERATE bit before setting it to cancel
		exec absp_InfoTableAttrib_Set @nodeType, @nodeKey,'BRW_DATA_REGENERATE',0
		exec absp_InfoTableAttribSetBrowserFilterTaskCancel @nodeType,@nodeKey,1
	end 
	
	-- clean up statistics
	delete from FilteredStatReport where NodeKey=@nodeKey and NodeType=@nodeType;
	
	--Update TaskStepInfo	
	if @status in ('Failed','Cancelled')
		update TaskStepInfo set Status=@status where TaskKey=@taskKey and Status in ('Running','Waiting');
		
	--Drop schema if exists--
	set @schemaName= 'FilterSchema_' + dbo.trim(cast(@nodeKey as varchar(10))) + '_' + dbo.trim(cast(@nodeType as varchar(10)))+'_'+dbo.trim(cast(@taskKey as varchar(10)));
	execute absp_Util_CleanupSchema @schemaName
end
