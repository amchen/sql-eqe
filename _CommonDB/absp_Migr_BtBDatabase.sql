if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_BtBDatabase') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_BtBDatabase;
end
go

create procedure absp_Migr_BtBDatabase @dbName varchar(255), @dbType as varchar(3)
as
/*
====================================================================================================
Purpose:	This procedure marks an given EDB/RDB for build to build migration if required.
Returns:	Nothing
====================================================================================================
*/
begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @rowCount int;

	print GetDate();
	print ': absp_Migr_BtBDatabase - Begin';

	if 1 = 1 --systemdb.dbo.absp_Util_IsBtBAvailable(@dbType) = 1
	begin
		print 'Available';
		print 'Database: '+@dbName;

		set @sql = 'select @rowCount = count(*) from ' + QuoteName(@dbName) + '.dbo.SYSOBJECTS where ID = object_id(N''' + QuoteName(@dbName) + '.dbo.absp_Util_IsBtBRequired'')'
		print @sql;
		exec sp_executesql @sql,N'@rowCount int out',@rowCount output;
		
		if @rowCount = 0
		begin
			exec absp_Migr_LoadProcedure @dbName, '16.00.00', 'F', 'Util', 'absp_Util_IsBtBRequired';
		end

		set @sql = 'select @rowCount = count(*) from ' + QuoteName(@dbName) + '.dbo.SYSOBJECTS where ID = object_id(N''' + QuoteName(@dbName) + '.dbo.absp_Util_GetFullDBVersion'')'
		exec sp_executesql @sql,N'@rowCount int out',@rowCount output;
		
		if @rowCount = 0
		begin
			exec absp_Migr_LoadProcedure @dbName, '16.00.00', 'F', 'Util', 'absp_Util_GetFullDBVersion';
		end

		DECLARE @isBtBRequired int;
		set @sql = 'select @isBtBRequired = ' + QuoteName(@dbName) + '.dbo.absp_Util_IsBtBRequired();';
		exec sp_executesql @sql,N'@isBtBRequired int out',@isBtBRequired output;

		if @isBtBRequired = 1
		begin
			print 'Required'+ QuoteName(@dbName);
			declare @infoKey int;
			if @dbType = 'RDB'
			begin
				print 'RDB'
				set @sql = 'select @infoKey = RdbInfoKey from ' + QuoteName(@dbName) + '.dbo.RDBINFO';
				exec sp_executesql @sql,N'@infoKey int out',@infoKey output;
				exec absp_InfoTableAttribSetRDBMigrationNeeded @infoKey, 1, @dbName;
			end
			else
			begin
				print 'EDB';
				select @infoKey = Cf_Ref_Key from CFLDRINFO where LongName = @dbName;
				exec absp_InfoTableAttribSetCurrencyMigrationNeeded @infoKey, 1, @dbName;
			end
		end
	end

	-- end of the views cursor
	print GetDate();
	print ': absp_Migr_BtBDatabase - End';
end
