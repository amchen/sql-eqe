if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachWCeDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachWCeDatabase;
end
go

create procedure absp_Util_AttachWCeDatabase
	@rc varchar(255) output,
	@databaseName varchar(255),
	@groupKey int = 0,
	@userKey int = 1

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure attachs a database file located in $\WceDB\Currency

Returns:      successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@databaseName ^^  database name

##RD  @rc ^^ successful or error messages.
*/

AS
begin

	set nocount on;

	declare @cmd varchar(MAX);
	declare @status integer;
	declare @sqlString nvarchar(1000);
 	declare @tableName varchar(255);
 	declare @isFreshDB varchar(3);
 	declare @IRDBName varchar(255);
	declare @dbprop table (value varchar(3));
	declare @currentDatabase varchar(255);
	declare @createByColName varchar(10);
	declare @counter int;

	set @rc = 'Success';
	set @status = 0;
	set @isFreshDB = 'No';


	-- if not already logically attached to RQE
	if not exists(select 1 from commondb.dbo.CFLDRINFO where longname = @databaseName)
	begin

		set @cmd = 'update [' + @databaseName +'].dbo.fldrinfo set longname = ''' + @databaseName + ''' where curr_node = ''Y'''
		execute (@cmd)

		-- Check if it's a fresh database
		begin try
			set @sqlString = N'declare @dbprop table (value varchar(3));' ;
			set @sqlString = @sqlString + N' insert @dbprop exec [' + @databaseName + ']..absp_Util_GetDatabaseProperty ''IsNewRQEDatabase'';';
			set @sqlString = @sqlString + N' select top 1 @isFreshDBOUT=value from @dbprop;'
			--print @sqlString;
			execute sp_executesql @sqlString,N'@isFreshDBOUT varchar(3) OUTPUT', @isFreshDBOUT=@isFreshDB OUTPUT;
		end try
		begin catch
			-- @databaseName didn't have absp_Util_GetDatabaseProperty. Okay, must be an existing RQE 13 db.
			set @isFreshDB = 'No';
		end catch


		set @createByColName = 'Create_By';
		set @counter = 0;

		while @counter < 2
		begin
			set @sqlString = N'select tbl.TABLENAME from DICTTBL tbl, DICTCOL col, [' + @databaseName +'].sys.TABLES systbl where col.FIELDNAME = ''' + @createByColName + ''' and tbl.TABLENAME = col.TABLENAME  and tbl.TABLENAME = systbl.NAME'
			execute('declare cursTableList cursor global for '+@sqlString)

			open cursTableList
			fetch next from cursTableList into @tableName
			while @@fetch_status = 0
			begin
				set @cmd = ''

				if @userKey > 0
				begin
					if @isFreshDB = 'No'
						set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set ' + @createByColName + ' = ' + dbo.trim(str(@userKey)) +
							' where ' + @createByColName + ' not in (select USER_KEY from commondb.dbo.USERINFO)'
					else
						set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set ' + @createByColName + ' = ' + dbo.trim(str(@userKey))

					execute absp_MessageEx @cmd
					execute (@cmd)
				end

				-- older tables used the column name "GROUP_KEY"
				if exists (select 1 from DICTCOL where TABLENAME = @tableName and FIELDNAME = 'GROUP_KEY')
				begin
					set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set GROUP_KEY = ' + dbo.trim(str(@groupKey))

					execute absp_MessageEx @cmd
					execute (@cmd)
				end

				-- newer tables use the column name "GroupKey"
				if exists (select 1 from DICTCOL where TABLENAME = @tableName and FIELDNAME = 'GroupKey')
				begin
					set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set GroupKey = ' + dbo.trim(str(@groupKey))

					execute absp_MessageEx @cmd
					execute (@cmd)
				end

				fetch next from cursTableList into @tableName
			end
			close cursTableList
			deallocate cursTableList
			set @createByColName = 'CreatedBy';
			set @counter = @counter + 1;
		end -- while @counter

		-- now fix up any ModifiedBy columns

		set @sqlString = N'select tbl.TABLENAME from DICTTBL tbl, DICTCOL col, [' + @databaseName +'].sys.TABLES systbl where col.FIELDNAME = ''ModifiedBy'' and tbl.TABLENAME = col.TABLENAME  and tbl.TABLENAME = systbl.NAME'
		execute('declare cursTableList cursor global for '+@sqlString)

		open cursTableList
		fetch next from cursTableList into @tableName
		while @@fetch_status = 0
		begin
			set @cmd = ''

			if @userKey > 0
			begin
				if @isFreshDB = 'No'
					set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set ModifiedBy = ' + dbo.trim(str(@userKey)) +
						' where ModifiedBy not in (select USER_KEY from commondb.dbo.USERINFO)'
				else
					set @cmd = 'update [' + @databaseName +'].dbo.' + @tableName + ' set ModifiedBy = ' + dbo.trim(str(@userKey))

				execute absp_MessageEx @cmd
				execute (@cmd)
			end

			fetch next from cursTableList into @tableName
		end
		close cursTableList
		deallocate cursTableList

		set @IRDBName = dbo.trim(@databaseName) + '_IR';

		-- reset all attribute bits before attaching the database
		exec absp_InfoTableAttrib_ResetAll @databaseName,0;

		-- Apply Update to EDB
		exec absp_Migr_ApplyUpdate 'EDB', @databaseName;
		-- Apply Update to IDB
		exec absp_Migr_ApplyUpdate 'IDB', @IRDBName;

		-- add currency folder to tree view
		exec absp_Util_TreeviewAttachCurrencyFolderDB @databaseName;

	end

	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		drop synonym MigrateLookupID;

	-- Create Exposure.Report views to IDB because that is where they are now populated
	begin try
		declare @sql nvarchar(max);
		set @sql = N'exec ' + quotename(@databaseName) + '..absp_Util_CreateExposureViewsToIDB';
		execute(@sql);
	end try
	begin catch
		-- Catch error 2812: Could not find stored procedure
		-- A database that needs to be migrated may not have procedure absp_Util_CreateExposureViewsToIDB loaded until after migration is completed
		if (ERROR_NUMBER() <> 2812)
		begin
			declare @ProcName varchar(100);
			select @ProcName=object_name(@@procid);
			exec absp_Util_GetErrorInfo @ProcName;
		end
	end catch

	set @rc = 'Success';

	select @status = CF_REF_KEY from commondb.dbo.CFLDRINFO where DB_NAME = @databaseName;

	return @status;
end
