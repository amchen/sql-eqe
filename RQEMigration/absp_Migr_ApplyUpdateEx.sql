if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ApplyUpdateEx') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_ApplyUpdateEx;
end
go

create procedure absp_Migr_ApplyUpdateEx
	@dbType varchar(3),
	@dbName varchar(120),
	@dropProc int =1,
	@debug int =0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure applies update instructions, if any, based on the RQE database type and version.
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbType ^^ The dbType (SYS, COM, EDB, IDB, RDB)
##PD  @dbName ^^ The name of the database to apply the update
*/

as

begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @rqeVersion varchar(25);
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
	exec absp_Util_GetDateString @dt output,'yyyymmdd';

	--Get the current RQEVersion, PatchVersion, HotfixVersion from @dbName
	set @sql = 'select top(1) @rqeVersion=RQEVersion, @currentPatchVersion=PatchVersion, @currentHotfixVersion=HotfixVersion from ' + quotename(@dbName) +'.dbo.RQEVersion order by RQEVersionKey desc';
	if @debug=1 exec absp_MessageEx @sql;
	execute sp_executesql @sql,N'@rqeVersion varchar(25) output,@currentPatchVersion varchar(5) output,@currentHotfixVersion varchar(5) output',@rqeVersion output,@currentPatchVersion output,@currentHotfixVersion output;

	set @currentHotfixVersion = right(@rqeVersion,2);

	--This procedure only applies updates within the same RQEVersion (ie. 13.00)
	--Outer loop 1: Loop RQEVersion + PatchVersion
	declare cursHotfix cursor for
		select distinct PatchVersion from commondb.dbo.PatchHotfixScript
			where left(RQEVersion,5) = left(@rqeVersion,5) and PatchVersion >= @currentPatchVersion order by PatchVersion
	open cursHotfix;
	fetch cursHotfix into @patchVersion;
	while @@FETCH_STATUS =0
	begin

		--Inner loop 2: Loop HotfixVersion (within RQEVersion + PatchVersion)
		declare curs2 cursor for
			select distinct HotfixVersion from commondb.dbo.PatchHotfixScript
				where left(RQEVersion,5) = left(@rqeVersion,5) and PatchVersion = @patchVersion and HotfixVersion > @currentHotfixVersion order by HotfixVersion
		open curs2;
		fetch curs2 into @hotfixVersion
		while @@FETCH_STATUS =0
		begin
			--Apply only if the hotfix is not applied--
			set @applyOnDB='Y';
			if @patchVersion = @currentPatchVersion and @hotFixVersion <= @currentHotfixVersion set @applyOnDB='N';
			if @applyOnDB='Y'
			begin
				--Get all scripts for this hotfix for the given db --
				declare curs3 cursor for
				 select case when @dbType='Sys' then SysDB
						when @dbType='Com' then ComDB
						when @dbType='EDB' then EDB
						when @dbType='IDB' then IDB
						when @dbType='RDB' then RDB end,ScriptName, ScriptText, StepNum
					from commondb.dbo.PatchHotfixScript
					where left(RQEVersion,5) = left(@rqeVersion,5) and PatchVersion=@patchVersion and HotfixVersion=@hotfixVersion order by StepNum
		    		open curs3;
				fetch curs3 into @applyonDB,@scriptName,@scriptText,@stepNum;
				while @@FETCH_STATUS =0
				begin
					if @applyonDB='Y'
					begin
						begin try
							-- If ScriptName is not empty, drop the procedure
							-- 8688: Migration from RQE 13 to RQE 14.10.00 failed with not finding procedure "absp_Migr_ExecuteMigrationScript"
							if @scriptName not in ('', 'absp_Migr_LoadProcedure','absp_Migr_ExecuteMigrationScript','absp_Migr_AnnotationHelper','absp_Migr_LogIt')
							begin
								if (@dropProc=1)
								begin
									set @sql=' if exists(select 1 from sys.objects where name = ''' + dbo.trim(@scriptName) + ''' and type=''P'') '
									set	@sql=@sql + ' drop procedure ' + dbo.trim(@scriptName) + ';';
									if @debug=1 exec absp_MessageEx  @sql;
									set @sql = N'exec ' + quotename(@dbName) + '..sp_executesql N''' + replace(@sql, '''', '''''') + '''';
									execute(@sql);
								end
							end

							-- Execute the ScriptText
							if @scriptName not in ('absp_Migr_LoadProcedure','absp_Migr_ExecuteMigrationScript','absp_Migr_AnnotationHelper','absp_Migr_LogIt')
							begin
								if @debug=1 exec absp_MessageEx @scriptText;
								set @sql = N'exec ' + quotename(@dbName) + '..sp_executesql N''' + replace(@scriptText, '''', '''''') + '''';
								execute(@sql);
							end

							-- Display message for SSMS
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

					fetch curs3 into @applyonDB,@scriptName,@scriptText,@stepNum;
				end
				close curs3
				deallocate curs3

				if @migrationFailed=0
				begin
					--Update RQEVersion table to the HotfixVersion
					set @sql = 'insert into ' + quotename(@dbName) + '.dbo.RQEVersion ' +
								'select top(1) DbType,SchemaVersion,left(RQEVersion,6)+''@hotfixVersion'',FlCertificationVersion,''@dt'',Build,''@patchVersion'',''@hotfixVersion'',''absp_Migr_ApplyUpdateEx'' from ' +
								quotename(@dbName) + '.dbo.RQEVersion order by RQEVersionKey desc';
					set @sql = replace(@sql, '@dt', @dt);
					set @sql = replace(@sql, '@patchVersion', @patchVersion);
					set @sql = replace(@sql, '@hotfixVersion', @hotfixVersion);
					if @debug=1 exec absp_MessageEx @sql;
					exec (@sql);
				end
				else
					break --do not proceed if migration fails

				set @migrationFailed=0;
			end

			fetch curs2 into @hotfixVersion;
		end
		close curs2
		deallocate curs2

		fetch cursHotfix into @patchVersion;
	end
	close cursHotfix
	deallocate cursHotfix

end
