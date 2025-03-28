if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanUpBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanUpBrowserData
end
 go

create procedure absp_CleanUpBrowserData @nodeKey int, @nodeType int, @userKey int=1,@debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure cleans up the browser data by dropping the filtered tables and cleaning up FilteredStatReport

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
	declare @taskKey int;
	declare @status varchar(20);
	delete from FilteredStatReport where NodeKey=@nodeKey and NodeType=@nodeType;
	
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
	
	--Set regenerate bit to on
	exec absp_InfoTableAttribSetBrowserDataRegenerate @nodeType,@nodeKey,1 
	
	--Update TaskStepInfo
	set @status='';
	if @nodeType=2
		select @taskKey=taskKey,@status=Status from taskinfo where taskTypeID =4 and PportKey=@nodeKey and nodeType=@nodeType and Status in('Failed','Cancelled')
	else
		select @taskKey=taskKey,@status=Status from taskinfo where taskTypeID =4 and ProgramKey=@nodeKey and nodeType=@nodeType and Status in('Failed','Cancelled')
	
	if @status in ('Failed','Cancelled')
		update TaskStepInfo set Status=@status where TaskKey=@taskKey and Status in ('Running','Waiting');
end
