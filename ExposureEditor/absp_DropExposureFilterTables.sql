if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DropExposureFilterTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DropExposureFilterTables
end
 go

create procedure absp_DropExposureFilterTables @nodeKey int, @nodeType int 
as
begin
	set nocount on
	
	declare @filterTableName varchar(130);
	declare @sql varchar(max);
	declare @tableName varchar(120);
	
	create table #ExpTbls (TableName varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS);
	insert into #ExpTbls values('Account');
	insert into #ExpTbls values('Policy');
	insert into #ExpTbls values('PolicyFilter');
	insert into #ExpTbls values('PolicyCondition');
	insert into #ExpTbls values('AccountReinsurance');
	insert into #ExpTbls values('PolicyReinsurance');
	insert into #ExpTbls values('SiteReinsurance');
	insert into #ExpTbls values('SiteCondition');
	insert into #ExpTbls values('StructureCondition');
	insert into #ExpTbls values('Structure');	
	insert into #ExpTbls values('StructureCoverage');	
	insert into #ExpTbls values('StructureFeature');
	
	declare c1 cursor for select TableName from #ExpTbls
	open c1
	fetch c1 into @tableName
	while @@fetch_status=0
	begin
	
		exec absp_GetFilteredTableName @filterTableName out, @tableName,@nodeKey,@nodeType,1
		
		set @sql = 'if exists (select 1 from sys.tables where name = ''' + @filterTableName + ''') drop table ' + @filterTableName;
		exec absp_MessageEx @sql
		exec(@sql)
	
		fetch c1 into @tableName
	end;
	close c1
	deallocate c1

	
	delete from FilteredStatReport where NodeKey=@nodeKey and NodeType =@nodeType;
	delete from ExposureDataFilterInfo where NodeKey=@nodeKey and NodeType =@nodeType;
	delete from ExposureDataSortInfo where NodeKey=@nodeKey and NodeType =@nodeType;
end
