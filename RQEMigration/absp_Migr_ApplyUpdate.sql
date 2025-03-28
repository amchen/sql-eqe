if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ApplyUpdate') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_ApplyUpdate;
end
go

create procedure absp_Migr_ApplyUpdate
	@dbType varchar(3),
	@dbName varchar(120),
	@dropProc int =1,
	@debug int =0
/*
====================================================================================================
Purpose:	This procedure applies update instructions from PatchHotfixScript, based on the RQE database type and version.
Returns:	Nothing.
====================================================================================================
*/
as
begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @theRQEVersion varchar(25);
	declare @theVersion varchar(25);
	declare @patchVersion varchar(5);
	declare @hotfixVersion varchar(5);
	declare @currentPatchVersion varchar(5);
	declare @currentHotFixVersion varchar(5);
	declare @scriptName varchar(500);
	declare @scriptText varchar(max);
	declare @msg varchar(1000);
	declare @applyOnDB char(1);
	declare @dt varchar(8);
	declare @migrationFailed int;
	declare @stepNum int;

	set @migrationFailed=0;
	exec systemdb.dbo.absp_Util_GetDateString @dt output,'yyyymmdd';

	/* Get the current RQEVersion, PatchVersion, HotfixVersion from @dbName */
	set @sql = 'select top(1) @theRQEVersion=RQEVersion, @currentPatchVersion=PatchVersion,@currentHotfixVersion=HotfixVersion from ' + quotename(@dbName) +'.dbo.RQEVersion order by RQEVersionKey desc';
	if @debug=1 exec absp_MessageEx @sql;
	execute sp_executesql @sql,N'@theRQEVersion varchar(25) output,@currentPatchVersion varchar(5) output,@currentHotfixVersion varchar(5) output',@theRQEVersion output,@currentPatchVersion output,@currentHotfixVersion output;

	set @currentHotfixVersion = right(@theRQEVersion,2);

	/* This procedure only applies updates within the same RQEVersion (ie. 13.00) */
	/* Outer loop 1: Loop RQEVersion + PatchVersion */
	declare cursHotfix cursor for
		select distinct PatchVersion from commondb.dbo.PatchHotfixScript
			where left(RQEVersion,5) = left(@theRQEVersion,5) and PatchVersion >= @currentPatchVersion order by PatchVersion;
	open cursHotfix;
	fetch cursHotfix into @patchVersion;
	while @@FETCH_STATUS=0
	begin

		/* Inner loop 2: Loop HotfixVersion (within RQEVersion + PatchVersion) */
		declare cursHotfix2 cursor for
			select distinct HotfixVersion from commondb.dbo.PatchHotfixScript
				where left(RQEVersion,5) = left(@theRQEVersion,5) and PatchVersion = @patchVersion and HotfixVersion > @currentHotfixVersion order by HotfixVersion;
		open cursHotfix2;
		fetch cursHotfix2 into @hotfixVersion;
		while @@FETCH_STATUS=0
		begin
			/* Apply only if the hotfix is not applied */
			set @applyOnDB='Y';
			if @patchVersion = @currentPatchVersion and @hotFixVersion <= @currentHotfixVersion set @applyOnDB='N';

			if @applyonDB='Y'
			begin
				/* Get all scripts for this hotfix for the given db */
				declare cursHotfix3 cursor for
					select case
						when @dbType='Sys' then SysDB
						when @dbType='Com' then ComDB
						when @dbType='EDB' then EDB
						when @dbType='IDB' then IDB
						when @dbType='RDB' then RDB end, ScriptName, ScriptText, StepNum
					from commondb.dbo.PatchHotfixScript
					where left(RQEVersion,5) = left(@theRQEVersion,5) and PatchVersion=@patchVersion and HotfixVersion=@hotfixVersion order by StepNum;
				open cursHotfix3;
				fetch cursHotfix3 into @applyonDB,@scriptName,@scriptText,@stepNum;
				while @@FETCH_STATUS=0
				begin
					if (@applyonDB='Y' and @migrationFailed=0)
					begin
						begin try
							/* If ScriptName is not empty, drop the procedure */
							/* 8688: Migration from RQE 13 to RQE 14.10.00 failed with not finding procedure "absp_Migr_ExecuteMigrationScript" */
							if @scriptName not in ('', 'absp_Migr_LoadProcedure','absp_Migr_ExecuteMigrationScript','absp_Migr_AnnotationHelper','absp_Migr_LogIt')
							begin
								if (@dropProc=1)
								begin
									set @sql=' if exists(select 1 from sys.objects where name = ''' + dbo.trim(@scriptName) + ''' and type=''P'') ';
									set	@sql=@sql + ' drop procedure ' + dbo.trim(@scriptName) + ';';
									if @debug=1 exec absp_MessageEx  @sql;
									set @sql = N'exec ' + quotename(@dbName) + '..sp_executesql N''' + replace(@sql, '''', '''''') + '''';
									execute(@sql);
								end
							end

							/* Execute the ScriptText */
							if @scriptName not in ('absp_Migr_LoadProcedure','absp_Migr_ExecuteMigrationScript','absp_Migr_AnnotationHelper','absp_Migr_LogIt')
							begin
								set @scriptText = replace(@scriptText, 'DB_NAME()', @dbName);
								set @scriptText = replace(@scriptText, '@dbName', @dbName);
								if @debug=1 exec absp_MessageEx @scriptText;
								set @sql = N'exec ' + quotename(@dbName) + '..sp_executesql N''' + replace(@scriptText, '''', '''''') + '''';
								execute(@sql);
							end

							set @sql = 'Applied update @stepNum: @scriptName to '+ quotename(@dbName);
							set @sql = replace(@sql, '@stepNum', cast(@stepNum as varchar(30)));
							set @sql = replace(@sql, '@scriptName', @scriptName);
							print @sql;
						end try
						begin catch
							set @sql = 'ERROR: Step @stepNum - @scriptName to '+ quotename(@dbName);
							set @sql = replace(@sql, '@stepNum', cast(@stepNum as varchar(30)));
							set @sql = replace(@sql, '@scriptName', @scriptName);
							print @sql;
							exec absp_MessageEx  @sql;
							set @migrationFailed=1;
						end catch
					end

					fetch cursHotfix3 into @applyonDB,@scriptName,@scriptText,@stepNum;
				end

				close cursHotfix3;
				deallocate cursHotfix3;

				if @migrationFailed=0
				begin
					set @theVersion = left(@theRQEVersion,6) + @hotfixVersion;

					/* Update RQEVersion table to the HotfixVersion */
					set @sql = 'insert into ' + quotename(@dbName) + '.dbo.RQEVersion ' +
								'select top(1) ''@dbType'',SchemaVersion,RQEVersion,FlCertificationVersion,''@dt'',Build,''@patchVersion'',''@hotfixVersion'',''absp_Migr_ApplyUpdate'' from ' +
								'systemdb.dbo.RQEVersion where RQEVersion=''@theVersion'' order by RQEVersionKey desc';

					set @sql = replace(@sql, '@dbType', @dbType);
					set @sql = replace(@sql, '@dt', @dt);
					set @sql = replace(@sql, '@patchVersion', @patchVersion);
					set @sql = replace(@sql, '@hotfixVersion', @hotfixVersion);
					set @sql = replace(@sql, '@theVersion', @theVersion);

					if @debug=1 exec absp_MessageEx @sql;
					exec (@sql);
				end
			end

			fetch cursHotfix2 into @hotfixVersion;
		end

		close cursHotfix2;
		deallocate cursHotfix2;

		fetch cursHotfix into @patchVersion;
	end
	close cursHotfix;
	deallocate cursHotfix;

	if (@migrationFailed=0)
	begin
		set @msg = 'Successfully applied update to database: ' + @dbName;
		print @msg;
		exec absp_Migr_ApplyUpdateScript @dbType, @dbName, @dropProc, @debug;
	end
	else
	begin
		set @msg = 'Failed to apply update to database: ' + @dbName;
		raiserror (@msg, 16, 1);
	end
end
