-- NOTE: This procedure calls and depends on absp_Util_GenInListString being available

if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_InsertNewColumn') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_InsertNewColumn;
end
go

create procedure absp_Migr_InsertNewColumn
	@tableName varchar(130),
	@columnList varchar(max)
as

begin

	declare @cnt1 int;
	declare @cnt2 int;
	declare @sql nvarchar(max);
	declare @sql2 varchar(max);
	declare @msg varchar(max);
	declare @backupTable varchar(150);
	declare @fieldnames varchar(max);
	declare @hasIdentity int;
	declare @objName nvarchar(2000);
	declare @newName nvarchar(2000);
	declare @colCnt int;
	declare @newColCnt int;

	set nocount on;

	begin try

			--Check if table exists --
			if not exists(select 1 from sys.objects where object_name(object_id)= @tableName)
				return;

			--Count number of new columns--
			set @newColCnt = LEN(@columnList) - LEN(REPLACE(@columnList, ',', ''))+1;

			--create in list--
			set @columnList = ''''+REPLACE(@columnList,',',''',''')+'''';

			--check if new columns exists--
			set @sql = 'select @colCnt = count(*) from sys.columns where object_name(object_id) = ''' + @tableName + ''' and name in (' + @columnList +') ';
			exec sp_executesql @sql,N'@colCnt int out',@colCnt out;

			--return if all new columns exists
			if (@colCnt = @newColCnt)
				return;

			--Check if the table hasIdentity column
			select @HasIdentity = isnull(objectproperty ( object_id(@tableName) , 'TableHasIdentity' ) , -1);

			--Get column list--
			set @sql = 'select name from sys.columns where object_id = object_id(''dbo.' + @tableName + ''') order by column_id';
			exec absp_Util_GenInListString @fieldNames output, @sql, 'S';
			set @fieldNames = replace(@fieldNames, '''','');
			set @backupTable = @tableName + '_Backup';

			--create backup--
			if exists(select 1 from sys.tables where name = @backupTable)
				exec('drop table '+ @backupTable);

			SELECT top(1) @cnt1 = rows FROM sys.partitions WHERE object_name(object_id) = @tableName and index_id < 2 order by rows desc;

			exec sp_rename @tableName,@backupTable;

			--rename primaryKey if any--
			set @objName = '';
			select top(1) @objName = name from sys.indexes where OBJECT_NAME(object_id)=@backupTable and name like '%[_]PK';

			if (@objName <> '')
			begin
				set @newName = dbo.trim(@backupTable) + '_PK';
				exec sp_rename @objName, @newName, N'OBJECT';
			end
			print 'backup created';

			--create table with indexes--
			exec systemdb..absp_Util_CreateTableScript @sql out, @tableName,'','',1;
			exec (@sql);
			print 'table created';

			--transfer table data--
			set @sql = '';
			if (@hasIdentity = 1)
				set @sql = 'set identity_insert ' + @tableName + ' on; ';
			set @sql =  @sql + 'insert into ' + @tableName + '(' + @fieldnames + ') select ' + @fieldnames + ' from ' + @backupTable;
			if (@hasIdentity = 1)
				set @sql = @sql + '; set identity_insert ' + @tableName + ' off;';
			print @sql;
			exec (@sql);
			print 'rows inserted';

			SELECT top(1) @cnt2 = rows FROM sys.partitions WHERE object_name(object_id) = @tableName and index_id < 2 order by rows desc;

			if (@cnt1 <> @cnt2)
				raiserror ('Error in absp_Migr_InsertNewColumn: Row count mismatch',16,1);

		end try

		begin catch
			set @msg = Error_Message();
			print @msg;
			raiserror (@msg,16,1);
			return;
		end catch

		print 'drop backup';

		--drop backup--
		if exists(select 1 from sys.objects where name=@backupTable)
			exec ('drop table ' + @backupTable);

	return 0;

end
