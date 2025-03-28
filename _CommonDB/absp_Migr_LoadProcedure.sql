if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_LoadProcedure') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_LoadProcedure;
end
go

create procedure absp_Migr_LoadProcedure
 	@DatabaseName varchar(130),
 	@RQEVersion varchar(25),
 	@ProcType varchar(1) = '',
 	@ProcGroup varchar(100) = '',
 	@ProcName varchar(100) = '',
	@debug int =0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will drop and load procedures from systemdb..MigrationProc table into a target database.
Returns:	0 if all procedures are loaded successfully,
		1 if load procedure fails.
		-1 if no procedures are loaded
====================================================================================================
</pre>
</font>
##BD_END

##PD  @DatabaseName ^^ The database where the procedure is to be loaded
##PD  @RQEVersion ^^ The RQE version
##PD  @ProcType ^^ The procedure type
##PD  @ProcGroup ^^ The procedure group
##PD  @ProcName ^^ The procedure to be loaded
##PD  @debug ^^ The debug flag
*/

as

begin
	set nocount on;

	declare @pName varchar(100);
	declare @pText varchar(max);
	declare @pType char(1);
	declare @loadProcFailed int;
	declare @sql nvarchar(max);
	declare @sSql varchar(max);
	declare @whereClause varchar(1000);
	declare @dbType varchar(3);
	declare @dropCreateProc int;
 	declare @currentDBName varchar(130);

	set @loadProcFailed=-1;
	set @whereClause='';

	--Get current database name
	set @currentDBName = DB_NAME();
	if (@DatabaseName = 'DB_NAME()')
	begin
		set @DatabaseName = DB_NAME();
	end

	--Create where clause--
	if @ProcGroup=''
	begin
		--Get dbType--
		set @sql='select top(1) @dbType=DbType from ' + quotename(@DatabaseName) + '..RQEVersion';
		execute sp_executesql @sql,N'@dbType varchar(3) output',@dbType output;

		if @dbType='SYS'
			set @ProcGroup='=''_SystemDB''';
		else if @dbType='COM'
			set @ProcGroup='=''_CommonDB''';
		else if @dbType='RDB'
			set @ProcGroup='=''_RDB''';
		else
			set @ProcGroup='not in (''_SystemDB'',''_CommonDB'',''_RDB'')';
	end
	else
	begin
		set @ProcGroup='=''' + @ProcGroup + '''';
	end

	set @whereClause = @whereClause + ' and ProcGroup ' + @ProcGroup;

	if @ProcType<>''
		set @whereClause = @whereClause + ' and ProcType =''' + @ProcType + '''';

	if @ProcName<>''
		set @whereClause = @whereClause + ' and ProcName =''' + @ProcName + '''';

	if @debug=1 print @whereClause;
	----

	set @sSql = ' declare LoadProcCurs cursor global for
			select ProcType,ProcName,ProcText from systemdb.dbo.MigrationProc where RQEVersion = ''' + @RQEVersion + '''' + @whereClause + ' order by ProcGroup,ProcName';

	if @debug=1 print @sSql;
	if exists(select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @sSql;

	exec(@sSql);
	open LoadProcCurs;
	fetch LoadProcCurs into @pType,@pName,@pText;
	while @@FETCH_STATUS =0
	begin
		-- First time --
		if @loadProcFailed=-1 set @loadProcFailed=0

		-- If this procedure is running from a database that is different than the target database, always drop the procedures
		-- If the @ProcName parameter is provided, always drop it
		if (@currentDBName <> @DatabaseName or @ProcName <> '')
		begin
			set @dropCreateProc = 1;
		end
		else
		begin
			--When this procedure is run from the current db, do nothing if exists
			set @dropCreateProc=1;
			set @sql=' if ''' + @pName + ''' in (''absp_Migr_LoadProcedure'',''absp_Migr_ExecuteMigrationScript'',''absp_Migr_AnnotationHelper'',''absp_Migr_LogIt'',''absp_Migr_ApplyUpdate'')
				and exists(select 1 from ' + quotename(@DatabaseName) + '.sys.objects where name = ''' + rtrim(@pName) + ''' and type=''P'')
				set @dropCreateProc=0';
			exec sp_executesql  @sql, N'@dropCreateProc int OUTPUT', @dropCreateProc OUTPUT;
		end

		if @dropCreateProc=1
		begin
			-- drop the object if exists --
			if (@pType='P')
			begin
				set @sql=' if exists(select 1 from sys.objects where name = ''' + rtrim(@pName) + ''' and type=''P'') ';
				set @sql=@sql + ' drop procedure ' + rtrim(@pName) + ';'
			end
			else if (@pType='V')
			begin
				set @sql=' if exists(select 1 from sys.objects where name = ''' + rtrim(@pName) + ''' and type=''V'') ';
				set @sql=@sql + ' drop view ' + rtrim(@pName) + ';'
			end
			else if (@pType='F')
			begin
				set @sql=' if exists(select 1 from sys.objects where name = ''' + rtrim(@pName) + ''' and type in (''FN'',''TF'')) ';
				set @sql=@sql + ' drop function ' + rtrim(@pName) + ';'
			end
			else if (@pType='T')
			begin
				set @sql=' if exists(select 1 from sys.objects where name = ''' + rtrim(@pName) + ''' and type=''TR'') ';
				set @sql=@sql + ' drop trigger ' + rtrim(@pName) + ';'
			end
			else
			begin
				raiserror ('Unknown procedure type, error in MigrationProc table during database build.', 16, 1);
			end

			set @sql = N'exec ' + quotename(@DatabaseName) + '..sp_executesql N''' + replace(@sql, '''', '''''') + '''';
			execute(@sql);

			-- Execute create object --
			begin try
				-- replace GO keyword since it is not T-SQL
				set @pText = replace(@pText, char(13)+char(10)+'GO', char(13)+char(10)+';');

				if @debug=1 print @pText;
				set @sql = N'exec ' + quotename(@DatabaseName) + '..sp_executesql N''' + replace(@pText, '''', '''''') + '''';
				execute(@sql);

				set @sql = 'Load script @pName into [@DatabaseName], Version=@RQEVersion';
				set @sql = replace(@sql, '@pName', @pName);
				set @sql = replace(@sql, '@DatabaseName', @DatabaseName);
				set @sql = replace(@sql, '@RQEVersion', @RQEVersion);

				if exists(select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @sql;
				print @sql;
			end try
			begin catch
				if ERROR_NUMBER()=207 and charindex('absp_',ERROR_MESSAGE())>0
					set @loadProcFailed=0;
				else
					set @loadProcFailed=1;

				declare @PrName varchar(100),
				@msg as varchar(1000),
				@module as varchar(100),
				@ErrorMessage varchar(4000);

				select @PrName = object_name(@@procid);
				select	@module = isnull(ERROR_PROCEDURE(),@PrName),
					@msg='"'+ERROR_MESSAGE()+'"'+
					'  Line: '+cast(ERROR_LINE() as varchar(10))+
					'  No: '+cast(ERROR_NUMBER() as varchar(10))+
					'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
					'  State: '+cast(ERROR_STATE() as varchar(10)),
					@ErrorMessage='Exception: Top Level '+@PrName+'. Occurred in '+@module+'. Error: '+@msg;

					if exists(select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @ErrorMessage;
					print @ErrorMessage;
			end catch
		end
		else
		begin
			set @sql = 'Skipping script ' + @pName;
			if exists(select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @sql;
			print @sql;
		end

		fetch LoadProcCurs into @pType,@pName,@pText;
	end
	close LoadProcCurs;
	deallocate LoadProcCurs;

	--Display proc load status--
	if @loadProcFailed=1
	begin
		print 'Failed to load procedures';
		raiserror ('Failed to load procedures..', 16, 1);
	end
	else if @loadProcFailed=0
		print 'Loaded procedures successfully';
	else
		print 'No procedure have been loaded';
	----

	return @loadProcFailed;
end

--exec absp_Migr_LoadProcedure 'Base_CurrencyFolder','14.00.00','','','',1;
