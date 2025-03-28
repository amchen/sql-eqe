if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ApplyUpdateScript') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_ApplyUpdateScript;
end
go

create procedure absp_Migr_ApplyUpdateScript
	@dbType varchar(3),
	@dbName varchar(120),
	@dropProc int =1,
	@debug int =0
/*
====================================================================================================
Purpose:	This procedure applies update instructions from MigrationScript, based on the RQE database type and version.
Returns:	Nothing.
====================================================================================================
*/
as
begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @theRQEVersion varchar(25);
	declare @theVersion varchar(25);
	declare @hotfixVersion varchar(5);
	declare @currentPatchVersion varchar(5);
	declare @currentHotFixVersion varchar(5);
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


	/* Inner loop 2: Loop HotfixVersion (within RQEVersion + PatchVersion) */
	declare curScriptHotfix2 cursor for
		select distinct HotfixVersion from systemdb.dbo.MigrationScript
			where left(RQEVersion,5) = left(@theRQEVersion,5) and HotfixVersion > @currentHotfixVersion and IsDisabled='' order by HotfixVersion;
	open curScriptHotfix2;
	fetch curScriptHotfix2 into @hotfixVersion;
	while @@FETCH_STATUS=0
	begin
		/* Apply only if the hotfix is not applied */
		set @applyOnDB='Y';
		if @hotFixVersion <= @currentHotfixVersion set @applyOnDB='N';

		if @applyonDB='Y'
		begin
			/* Get all scripts for this hotfix for the given dbType */
			declare curScriptHotfix3 cursor for
				select 'Y', ScriptText, SeqNum
					from systemdb.dbo.MigrationScript
					where left(RQEVersion,5) = left(@theRQEVersion,5) and @dbType = TableName and HotfixVersion = @hotfixVersion and IsDisabled='' order by SeqNum;
			open curScriptHotfix3;
			fetch curScriptHotfix3 into @applyonDB,@scriptText,@stepNum;
			while @@FETCH_STATUS=0
			begin
				if (@applyonDB='Y' and @migrationFailed=0)
				begin
					begin try
						/* Execute the ScriptText */
						set @scriptText = replace(@scriptText, '@DatabaseName', @dbName);
						if @debug=1 exec absp_MessageEx @scriptText;
						set @sql = N'exec ' + quotename(@dbName) + '..sp_executesql N''' + replace(@scriptText, '''', '''''') + '''';
						execute(@sql);

						set @sql = 'Applied hotfix script step @SeqNum to '+ quotename(@dbName);
						set @sql = replace(@sql, '@SeqNum', cast(@stepNum as varchar(30)));
						print @sql;
					end try
					begin catch
						set @sql = 'ERROR: Applying hotfix script step @SeqNum to '+ quotename(@dbName);
						set @sql = replace(@sql, '@SeqNum', cast(@stepNum as varchar(30)));
						print @sql;
						exec absp_MessageEx @sql;
						set @migrationFailed=1;
					end catch
				end

				fetch curScriptHotfix3 into @applyonDB,@scriptText,@stepNum;
			end

			close curScriptHotfix3;
			deallocate curScriptHotfix3;

			if @migrationFailed=0
			begin
				set @theVersion = left(@theRQEVersion,6) + @hotfixVersion;

				/* Update RQEVersion table to the HotfixVersion */
				set @sql = 'insert into ' + quotename(@dbName) + '.dbo.RQEVersion ' +
							'select top(1) ''@dbType'',SchemaVersion,RQEVersion,FlCertificationVersion,''@dt'',Build,'''',''@hotfixVersion'',''absp_Migr_ApplyUpdateScript'' from ' +
							'systemdb.dbo.RQEVersion where RQEVersion=''@theVersion'' order by RQEVersionKey desc';

				set @sql = replace(@sql, '@dbType', @dbType);
				set @sql = replace(@sql, '@dt', @dt);
				set @sql = replace(@sql, '@hotfixVersion', @hotfixVersion);
				set @sql = replace(@sql, '@theVersion', @theVersion);

				if @debug=1 exec absp_MessageEx @sql;
				exec (@sql);
			end
		end

		fetch curScriptHotfix2 into @hotfixVersion;
	end

	close curScriptHotfix2;
	deallocate curScriptHotfix2;


	if (@migrationFailed=0)
	begin
		set @msg = 'Successfully applied update script to database: ' + @dbName;
		print @msg;
	end
	else
	begin
		set @msg = 'Failed to apply update script to database: ' + @dbName;
		raiserror (@msg, 16, 1);
	end
end
