if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateGenericViews') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateGenericViews;
end
go

create procedure absp_Util_CreateGenericViews
    @sourceDB varchar(255) = 'systemdb',
    @dropTables int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:

    This procedure automatically creates views in the User Database for all tables in the
    systemdb or Ecommondb database, with special handling for Lookup tables.

Returns:       None
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDB	     ^^source DB : either systemdb or commondb
##PD  @dropTables    ^^ flag to drop tables.
*/

AS
begin

    set nocount on;

    declare @tableName varchar(120);
    declare @columnList varchar(max);
    declare @dbBit varchar(6);
    declare @sql varchar(max);
    declare @userDb varchar(120);

    set @userDb = DB_NAME();
	set @dbBit = '';

	if @sourceDB = 'systemdb'
		set @dbBit = 'SYS_DB';
	else
	begin
		if @sourceDB = 'commondb'
			set @dbBit = 'COM_DB';
		else
			return;
	end

	set @sql='declare curs1 cursor fast_forward global for select rtrim(tablename) from ' +
		'systemdb.dbo.DICTTBL where len(' + @dbBit + ') = 1 and LOCATION in (''B'',''S'') and ' + @dbBit +
        ' in (''L'', ''Y'')  and CF_DB = ''N'' and CF_DB_IR = ''N''';

	--set @sql='declare curs1 cursor fast_forward global for select name from ' + @sourceDB + '.sys.tables ' + ' where type=''U'''
	exec(@sql);

	open curs1
	fetch next from curs1 into @tableName
	while @@fetch_status = 0
	begin

		IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME=@tableName)
		begin
			-- drop 'view' from the database if exists
			if exists (select 1 from SYSOBJECTS where id = OBJECT_ID(@tableName) and OBJECTPROPERTY(id, N'IsView') = 1)
			begin
				 set @sql = 'drop view ' + @tableName;
                 print @sql;
				 exec(@sql);
			end

			-- Get the column list for the table
			exec absp_Util_GetColumnList @columnList output, @tableName, ',';

			-- create the view for each table
			if OBJECT_ID(@sourceDB + '.dbo.' + @tableName, 'U') IS NOT NULL
			begin
				set @sql = 'create view ' + @tableName + ' as select ' + @columnList + ' from ' + @sourceDB + '.dbo.' + @tableName;
				print @sql;
				exec(@sql);
			end

            -- view for _S tables in commondb
			if @userDb = 'commondb' and  @sourceDB = 'systemdb'
			begin
				if OBJECT_ID(@sourceDB + '.dbo.' + rtrim(@tableName) + '_S', 'U') IS NOT NULL
				begin
                    -- drop view first if exists
                    if exists (select 1 from SYSOBJECTS where id = OBJECT_ID(rtrim(@tableName)) and OBJECTPROPERTY(id, N'IsView') = 1)
                    begin
                         set @sql = 'drop view ' + rtrim(@tableName);
                         print @sql;
                         exec(@sql);
                    end
                    -- create the view
					if not exists (select 1 from SYSOBJECTS where id = OBJECT_ID(rtrim(@tableName)) and OBJECTPROPERTY(id, N'IsView') = 1)
					begin
						set @sql = 'create view ' + rtrim(@tableName) + ' as select ' + @columnList + ' from ' + @sourceDB + '.dbo.' + rtrim(@tableName) + '_S';
                        print @sql;
						exec(@sql);
					end

                    -- drop _S view first if exists
                    if exists (select 1 from SYSOBJECTS where id = OBJECT_ID(rtrim(@tableName) + '_S') and OBJECTPROPERTY(id, N'IsView') = 1)
                    begin
                         set @sql = 'drop view ' + rtrim(@tableName) + '_S';
                         print @sql;
                         exec(@sql);
                    end
                    -- create the _S view
                    if not exists (select 1 from SYSOBJECTS where id = OBJECT_ID(rtrim(@tableName) + '_S') and OBJECTPROPERTY(id, N'IsView') = 1)
                    begin
                        set @sql = 'create view ' + rtrim(@tableName) + '_S as select ' + @columnList + ' from ' + @sourceDB + '.dbo.' + rtrim(@tableName) + '_S';
                        print @sql;
                        exec(@sql);
                    end
				end
			end
		end
		fetch next from curs1 into @tableName
	end
	close curs1
	deallocate curs1

	-- create system instead of trigger lookup views
	exec absp_Util_CreateNonAutoLookupView @dropTables;

	-- copy auto lookup tables from common to user database
	exec absp_Util_CreateAutoLookupTables @dropTables;

	-- copy the special lookup views
	if @sourceDB = 'systemdb'
	begin
		exec absp_Util_CreateDictViewViews;
	end
end

-- exec absp_Util_CreateGenericViews 'systemdb';
-- exec absp_Util_CreateGenericViews 'commondb';
