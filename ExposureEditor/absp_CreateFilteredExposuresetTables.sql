if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CreateFilteredExposuresetTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateFilteredExposuresetTables
end
 go

create procedure absp_CreateFilteredExposuresetTables @nodeKey int, @nodeType int, @userKey int =1,@createIndex int=0
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql varchar(max);
	declare @filterTableName varchar(130)
	
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
		set @filterTableName='Filtered' + @tableName;
		set @tableName=@filterTableName + '_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))

		if @createIndex=0
		begin
			set @sql='if exists (select 1 from sys.tables where name =''' + @tableName+ ''') drop table ' + @tableName;
			exec (@sql);
			exec absp_Util_CreateTableScript @sql out, @filterTableName,@tableName,'',0;
		end
		else
			exec absp_Util_CreateTableScript @sql out, @filterTableName,@tableName,'',2;
		exec absp_MessageEx @sql;
		exec (@sql);

		fetch c1 into @tableName
	end;
	close c1
	deallocate c1
	
end
