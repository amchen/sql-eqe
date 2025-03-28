if exists(select * from SYSOBJECTS where ID = object_id(N'absp_007083_CreateNonExistingIndexForTable') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_007083_CreateNonExistingIndexForTable;
end
go

create procedure absp_007083_CreateNonExistingIndexForTable
	@tableName varchar(130)
as

begin
	declare @cnt1 int;
	declare @cnt2 int;
	declare @sql varchar(max);
	declare @sql2 varchar(max);
	declare @msg varchar(max);
	declare @backupTable varchar(150);
	declare @fieldnames varchar(max);
	declare @hasIdentity int;
	declare @objName nvarchar(2000);
	declare @newName nvarchar(2000);

	set nocount on;

	--7563: RQE 14 - Need to Drop and Rebuild Indices During Migration to RQE 14 for PolicyCondition and SiteCondition Tables
	begin try

		set @backupTable =@tableName + '_Backup';

		--Check if indexes are correct--
		exec systemdb..absp_Util_CreateTableScript @sql out, @tableName ,'','',1;
		exec absp_Util_CreateSysTableScript @sql2 out, @tableName ,'','',1;

		if @sql = @sql2 return 0; -- Indexes are same

		SELECT top(1) @cnt1 = rows FROM sys.partitions WHERE object_name(object_id) = @tableName and index_id < 2 order by rows desc;

		--create backup if it does not exist--
		if not exists(select 1 from sys.tables where name=@backupTable)
		begin
			exec sp_rename @tableName,@backupTable;

			--rename primaryKey if any--
			set @objName = '';
			select top(1) @objName= name from sys.indexes where OBJECT_NAME(object_id)=@backupTable and name like '%[_]PK';
			if (@objName <> '')
			begin
				set @newName = dbo.trim(@backupTable) + '_PK';
				exec sp_rename @objName, @newName, N'OBJECT';
			end
		end

		--create table with indexes--
		exec systemdb..absp_Util_CreateTableScript @sql out, @tableName,'','',1;
		exec (@sql);

		--transfer table data--
		--Check if the table hasIdentity column
      	select @HasIdentity = isnull(objectproperty ( object_id(@tableName) , 'TableHasIdentity' ) , -1);
		execute systemdb..absp_DataDictGetFields @fieldNames output, @tableName,0;

		set @sql = '';
		if @hasIdentity = 1 set @sql = 'set identity_insert ' + @tableName + ' on; ';
		set @sql =  @sql + 'insert into ' + @tableName + '(' + @fieldnames + ') select ' + @fieldnames + '  from ' + @backupTable;
		if @hasIdentity = 1 set @sql = @sql + '; set identity_insert ' + @tableName + ' off;';
		exec (@sql);

		SELECT top(1) @cnt1 = rows FROM sys.partitions WHERE object_name(object_id) = @tableName and index_id < 2 order by rows desc;

		if (@cnt1 <> @cnt2)
			raiserror ('Error in absp_007083_CreateNonExistingIndexForTable: Row count mismatch',16,1);

	end try

	begin catch
		set @msg=Error_Message();
		raiserror (@msg,16,1);
	end catch

	--drop backup--
	if exists(select 1 from sys.objects where name = @backupTable)
		exec ('drop table ' + @backupTable);

	return 0;

end;
