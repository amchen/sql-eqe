if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_IsUserSnapshotDataCreated') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_IsUserSnapshotDataCreated
end
 go

create procedure absp_QA_IsUserSnapshotDataCreated @snapshotKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will test if the user snapshot data has been created successfully.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin
	set nocount on
	declare @sql nvarchar(max);
	declare @tableName varchar(120);
	declare @reportTableType int;
	declare @cnt int;
	declare @cnt1 int;
	declare @cnt2 int;
	declare @whereClause varchar(max);
	declare @exposureReport varchar(1);
	declare @probabilisticReport varchar(1);
	declare @ELTReport varchar(1);
	declare @nodeKey int;
	declare @nodeType int;
	declare @msgText varchar(100);
	declare @schemaname varchar(50);
	declare @inList varchar(max);
	declare @columnName varchar(120);
	declare @tableType varchar(20);
	declare @nType varchar(10)

	--create temporary table
	create table #SnapshotTblRowCnt (TableName varchar(120),TableType varchar(20),NodeType varchar(10),TotalCnt int,ActualCnt int,SchemaCnt int,MsgText varchar(100))
	
	--Get snapshotInfo--
	select @schemaName=SchemaName,@exposureReport=ExposureReports,@probabilisticReport=ProbabilisticReports,@ELTReport=ELTReports from SnapshotInfo where SnapshotKey=@snapshotKey;

	--Get nodeInfo--
	select @nodeKey = NodeKey,@nodeType=NodeType from SnapshotMap where SnapshotKey=@snapshotKey;
	set @inList=' in(-9999)';
	
	if @ELTReport = 'Y'
	begin
		set @sql='select EBERunID from eltSummary where NodeKey=' + cast(@nodeKey as varchar(30)) + ' and NodeType= ' + cast(@nodeType as varchar(30));
		exec absp_Util_GenInList @InList out,@sql	
	end
	if @probabilisticReport='Y'
	begin
		select @columnName = Case @nodeType
		when 1  then 'Aport_Key'
		when 2  then 'Pport_key'
		when 23 then 'RPort_Key'
		when 27 then 'Prog_Key'
		when 30 then 'Case_Key'
	else ''	end
	end
	
	declare SnapShotCurs cursor for select case when TableType='Reports (Exposure)' then 1 
				when TableType='Reports (Analysis)' then 2
				when TableType='Event Loss Tables' then 5 else 999 end,
				TableName from DictTbl where CF_DB in('Y','L') and AllowSnapShot='Y'  
				and not SYS_DB in('Y','L')

	open SnapShotCurs
	fetch SnapShotCurs into @reportTableType, @tablename
	while @@fetch_status=0
	begin
		set @nType=''
		if @reportTableType=1 
			set @tableType='Exposure Report'
		else if  @reportTableType=2 
			set @tableType='Analysis Report'
		else if  @reportTableType=5 
			set @tableType='ELT Report'
		else 
			set @tableType='Others'
		set @msgText='';
		set @whereClause=' where 1=0 ';
		
		if @reportTableType=5
		begin
			set  @whereClause = ' where EBERunID' + @inList 
		end
		else if @reportTableType=1
		begin
			set  @whereClause = ' where NodeKey = ' + cast(@nodeKey as varchar(30)) + ' and NodeType= ' + cast(@nodeType as varchar(30));
		end
		else if @reportTableType=2
		begin
			if exists(select 1 from DictCol where TableName=@tableName and FieldName=@columnName)
			begin
				set @ntype=replace(@columnName,'_Key','')
				set  @whereClause = ' where ' + @columnName + '=' + cast(@nodeKey as varchar(30)) ;
			end
		end
		else
		begin
			set @whereClause=''
	    end
		
		--Get total rows in table--
		set @sql = 'select @cnt=count(*) from ' + @tableName 
		exec sp_executesql @sql,N'@cnt int out',@cnt out
		
		--Get rows for the given node in the table--
		set @sql = 'select @cnt1=count(*) from ' + @tableName + @whereClause
		exec sp_executesql @sql,N'@cnt1 int out',@cnt1 out
		
		if not exists (select 1 from sys.tables where schema_name(schema_id)=@schemaName and name = @tableName)
		begin
			set @cnt2=0
			set @MsgText='Table does not exist in schema.'
		end
		else
		begin
			--Get rows in schema table--
			set @sql = 'select @cnt2=count(*) from ' + @schemaName + '.' + @tableName 
			exec sp_executesql @sql,N'@cnt2 int out',@cnt2 out
		end
		
		insert into #SnapshotTblRowCnt values (@tableName,@tableType,@nType,@cnt,@cnt1,@cnt2,@msgText);
		fetch SnapShotCurs into @reportTableType, @tablename
	end
	close SnapShotCurs
	deallocate SnapShotCurs
	select * from #SnapshotTblRowCnt order by 2,1
end
