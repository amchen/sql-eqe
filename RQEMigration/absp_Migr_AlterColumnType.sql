if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_AlterColumnType') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_AlterColumnType;
end
go

create procedure absp_Migr_AlterColumnType
	@TableName varchar(130),
	@FieldName varchar(100),
	@FieldType varchar(100)
as

begin

	declare @cnt1 int;
	declare @cnt2 int;
	declare @sql nvarchar(max);
	declare @msg varchar(max);
	declare @backupTable varchar(150);
	declare @fieldnames varchar(max);
	declare @hasIdentity int;
	declare @objName nvarchar(2000);
	declare @newName nvarchar(2000);

	set nocount on;

	begin try

		-- Check table exists --
		if not exists(select 1 from sys.objects where object_name(object_id)= @TableName)
		begin
			print 'Table does not exist';
			return;
		end

		-- Check column type --
		if exists(select 1 from sys.columns c inner join sys.types t on c.system_type_id = t.system_type_id where c.object_id = OBJECT_ID(@TableName) and c.name = @FieldName and t.name = @FieldType)
		begin
			print 'FieldType is already migrated';
			return;
		end

		-- Get column list --
		set @sql = 'select name from sys.columns where object_name(object_id)=''' + @TableName + ''' order by column_id';
		exec absp_Util_GenInList @fieldNames out , @sql, 'S';
		set @fieldNames = replace(replace(replace(@fieldNames, ' ) ',''),'in ( ',''),'''','');

		-- Create backup --
		set @backupTable = @TableName + '_Backup';
		if exists(select 1 from sys.tables where name = @backupTable)
			exec('drop table '+ @backupTable);

		exec sp_rename @TableName, @backupTable;

		-- Rename primaryKey if exists --
		set @objName = '';
		select top(1) @objName = name from sys.indexes where object_name(object_id) = @backupTable and name like '%[_]PK';
		if (@objName <> '')
		begin
			set @newName = dbo.trim(@backupTable) + '_PK';
			exec sp_rename @objName, @newName, N'OBJECT';
		end
		print 'Backup table created';

		--create table with indexes--
		exec systemdb..absp_Util_CreateTableScript @sql out, @TableName, '', '', 1;
		exec (@sql);
		print 'Table created';

		--transfer table data--
		--Check if the table hasIdentity column
		select @HasIdentity = isnull(objectproperty(object_id(@TableName), 'TableHasIdentity'), -1);
		set @sql = '';
		if (@hasIdentity = 1) set @sql = 'set identity_insert ' + @TableName + ' on; ';
		set @sql = @sql + 'insert into ' + @TableName + '(' + @fieldnames + ') select ' + @fieldnames + '  from ' + @backupTable;
		if (@hasIdentity = 1) set @sql = @sql + '; set identity_insert ' + @TableName + ' off;';
		print @sql;
		exec (@sql);
		print 'Rows inserted';

		select top (1) @cnt2 = rowcnt from sys.sysindexes where object_name(id) = @backupTable and indid < 2 order by indid desc, rowcnt desc;

		if (@cnt1 <> @cnt2) raiserror ('Error transferring table data', 16, 1);

	end try
	begin catch
		set @msg = Error_Message();
		print @msg;
		raiserror (@msg, 16, 1);
		return;
	end catch

	print 'Drop backup table';

	--drop backup--
	if exists(select 1 from sys.objects where name=@backupTable)
		exec ('drop table ' + @backupTable);

	return 0;
end

-- exec absp_Migr_AlterColumnType @TableName='', @FieldName='',	@FieldType='int';
