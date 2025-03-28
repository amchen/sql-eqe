if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_DropProcedure') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_DropProcedure;
end
go

create procedure absp_Migr_DropProcedure
	@DatabaseName varchar(130),
	@RQEVersion varchar(25),
	@debug int=0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will drop obsolete procedures from the target database for a specific RQE version.
Returns:	Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @DatabaseName ^^ The database where the procedure is to be loaded
##PD  @RQEVersion ^^ The RQE version
##PD  @debug ^^ The debug flag
*/

as

begin
	set nocount on;

	declare @pName varchar(100);
	declare @sql nvarchar(max);
	declare @sSql varchar(max);
	declare @whereClause varchar(1000);
	declare @dbType varchar(3);
 	declare @ProcType varchar(100);
 	declare @ProcGroup varchar(100);

	--Get current database name
	if (@DatabaseName = 'DB_NAME()')
	begin
		set @DatabaseName = DB_NAME();
	end

	--Get dbType--
	set @sql = 'select top(1) @dbType=DbType from ' + quotename(@DatabaseName) + '.dbo.RQEVersion';
	execute sp_executesql @sql,N'@dbType varchar(3) output',@dbType output;

	if @dbType='SYS'
		set @ProcGroup='=''_SystemDB''';
	else if @dbType='COM'
		set @ProcGroup='=''_CommonDB''';
	else if @dbType='RDB'
		set @ProcGroup='=''_RDB''';
	else
		set @ProcGroup='not in (''_SystemDB'',''_CommonDB'',''_RDB'')';

	-- Drop all deleted procedures

	set @ProcType = 'in (''P'')';
	set @whereClause = '';
	set @whereClause = @whereClause + ' and ProcGroup ' + @ProcGroup;
	set @whereClause = @whereClause + ' and ProcType ' + @ProcType;

	set @sSql = 'declare dropProcCurs cursor global for
					select name from @DatabaseName.sys.objects where type in (''P'') and schema_id=1
					and name not in (select ProcName from systemdb.dbo.MigrationProc where ProcGroup =''RQEMigration'')
					and name not in (select ProcName from systemdb.dbo.MigrationProc where RQEVersion=''@RQEVersion'' @whereClause)
					and name not like ''%LogIt%''
					order by name';

	set @sSql = replace(@sSql,'@DatabaseName',quotename(@DatabaseName));
	set @sSql = replace(@sSql,'@RQEVersion',@RQEVersion);
	set @sSql = replace(@sSql,'@whereClause',@whereClause);

	if @debug=1 print @sSql;

	exec(@sSql);
	open dropProcCurs;
	fetch dropProcCurs into @pName;
	while @@FETCH_STATUS=0
	begin

		set @sql = 'drop procedure ' + rtrim(@pName) + ';'
		set @sql = 'exec ' + quotename(@DatabaseName) + '..sp_executesql N''' + replace(@sql, '''', '''''') + '''';
		if @debug=1 print @sql;

		execute(@sql);

		fetch dropProcCurs into @pName;
	end
	close dropProcCurs;
	deallocate dropProcCurs;

	-- Drop all deleted functions

	set @ProcType = 'in (''F'')';
	set @whereClause = '';
	set @whereClause = @whereClause + ' and ProcGroup ' + @ProcGroup;
	set @whereClause = @whereClause + ' and ProcType ' + @ProcType;

	set @sSql = 'declare dropFuncCurs cursor global for
					select name from @DatabaseName.sys.objects where type in (''FN'', ''IF'', ''TF'', ''FS'', ''FT'') and schema_id=1
					and name not in (select ProcName from systemdb.dbo.MigrationProc where ProcGroup =''RQEMigration'')
					and name not in (select ProcName from systemdb.dbo.MigrationProc where RQEVersion=''@RQEVersion'' @whereClause)
					and name not like ''%LogIt%''
					order by name';

	set @sSql = replace(@sSql,'@DatabaseName',quotename(@DatabaseName));
	set @sSql = replace(@sSql,'@RQEVersion',@RQEVersion);
	set @sSql = replace(@sSql,'@whereClause',@whereClause);

	if @debug=1 print @sSql;

	exec(@sSql);
	open dropFuncCurs;
	fetch dropFuncCurs into @pName;
	while @@FETCH_STATUS=0
	begin

		set @sql = 'drop function ' + rtrim(@pName) + ';'
		set @sql = 'exec ' + quotename(@DatabaseName) + '..sp_executesql N''' + replace(@sql, '''', '''''') + '''';
		if @debug=1 print @sql;

		execute(@sql);

		fetch dropFuncCurs into @pName;
	end
	close dropFuncCurs;
	deallocate dropFuncCurs;

end

--exec absp_Migr_DropProcedure 'Base_CurrencyFolder','14.00.00',1;
