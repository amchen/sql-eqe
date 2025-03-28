if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ExecuteMigrationScript') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_ExecuteMigrationScript;
end
go

create procedure absp_Migr_ExecuteMigrationScript
	@batchJobKey int,
	@dbType varchar(3),
	@debug int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure executes the instructions from MigrationScript table on the target database.
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @batchJobKey ^^ The batchJobKey
##PD  @debug ^^ The debug flag
*/

as

begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @sourceRQEVersion varchar(25);
	declare @sourceBuild varchar(25);
	declare @RQEVersion varchar(25);
	declare @buildVersion varchar(25);
	declare @Build varchar(25);
	declare @scriptInfo varchar(200);
	declare @scriptText varchar(max);
	declare @finalScript varchar(max);
	declare @dt varchar(8);
	declare @seqNum int;
	declare @str varchar(8000);
	declare @tablename varchar(120);
	declare @edb char(1);
	declare @rdb char(1);
	declare @dbName varchar(255);
	declare @msgText varchar(100);
	declare @migrationFailed int;
	declare @isCritical char(1);
	declare @runScriptinDB int;
	declare @runExternalScripts char(1);
	declare @crlf char(2);
	declare @tab char(1);
	declare @com char(1);
	declare @btb char(1);

	set @crlf = char(10) + char(13);
	set @tab  = char(9);

	set @runExternalScripts ='Y';
	set @migrationFailed=0;

	--Get the current RQEVersion, Build--
	select @sourceRQEVersion=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Source.RQEVersion';
	select @sourceBuild=KeyValue      from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='Source.Build';
	select @dbName=KeyValue           from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='DBName';

	set @btb = '';
	set @buildVersion = '';
	if exists (select 1 from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='BtB.Migration' and KeyValue='True')
	begin
		set @btb = 'S';
		select @buildVersion=KeyValue from commondb.dbo.MigrationProperties where BatchJobKey=@batchjobKey and KeyName='BtB.Target.RQEVersion';
	end

	if (@dbType = 'IDB')
	begin
		select @dbName = @dbName + '_IR';
	end

	set @sourceBuild=isnull(@sourceBuild,0);

	-- if not exists, create MigrationProgress
	if not exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME='MigrationProgress')
	begin
		CREATE TABLE MigrationProgress (
			RQEVersion VARCHAR (25) NOT NULL DEFAULT '',
			Build VARCHAR (25) NOT NULL DEFAULT '',
			SeqNum INTEGER NOT NULL DEFAULT 0,
			Status CHAR (1) NOT NULL DEFAULT ''
		);
		CREATE UNIQUE CLUSTERED INDEX MigrationProgress_I1 ON MigrationProgress (RQEVersion,Build,SeqNum,Status);
	end

	--Loop for each RQEVersion--
	declare curs1 cursor for
		select distinct RQEVersion from systemdb.dbo.MigrationScript
			where RQEVersion >= @sourceRQEVersion and IsDisabled = '' and IsExternal <> 'Y' and TableName <> 'COM' and HotfixVersion = ''
			order by RQEVersion;

	open curs1;
	fetch curs1 into @RQEVersion;
	while @@FETCH_STATUS = 0
	begin
		set @msgText = '-- Begin absp_Migr_ExecuteMigrationScript: Migrating to RQE Version ' + @RQEVersion;
		exec absp_Migr_LogIt @msgText;
		print @msgText;

		--Inner loop 2: Loop each step for the build
		declare curs2 cursor for
			select SeqNum,IsCritical,TableName,ScriptText,ScriptInfo from systemdb.dbo.MigrationScript
				where RQEVersion = @RQEVersion and IsDisabled = '' and IsExternal <> 'Y' and HotfixVersion = ''
				  and SeqNum not in (select SeqNum from MigrationProgress where RQEVersion = @RQEVersion and Status = @btb)
				order by SeqNum;
		open curs2;
		fetch curs2 into @seqNum,@isCritical,@tableName,@scriptText,@scriptInfo;
		while @@FETCH_STATUS = 0
		begin
			--Run external scripts only if required--
			set @runScriptinDB=0;

			--If TableName is empty, the step is for all databases.
			if @tableName=''
				set @runScriptinDB=1;
			else
			begin
				--For migration steps that do not pertain to a specific table, the TableName column will contain the DBType (EDB/RDB/COM)
				if @tableName in ('EDB', 'IDB', 'RDB', 'COM')
				begin
					if (@dbType = @tableName)
					begin
						set @runScriptinDB=1;
					end
				end
				else
				begin
					if exists (select 1 from systemdb.dbo.DictTbl where TABLENAME=@tableName)
					begin
						select @edb=CF_DB,@rdb=RDB ,@com=COM_DB from systemdb.dbo.DictTbl where TABLENAME=@tableName;
						if (@edb in ('Y','L') and @dbType in ('EDB','IDB')) set @runScriptinDB=1;
						if (@rdb in ('Y','L') and @dbType='RDB') set @runScriptinDB=1;
						if (@com in ('Y','L') and @dbType='COM') set @runScriptinDB=1;
					end
					else
					begin
						-- Deleted tables are no longer in DictTbl so always execute @DropTable command
						if (@scriptText='@DropTable') set @runScriptinDB=1;
					end
				end
			end

			if @runScriptinDB=1
			begin
				--Translate if the Script has annotations--
				exec absp_Migr_AnnotationHelper @finalScript out, @scriptText, @tableName, @RQEVersion;

				--Insert row in MigrationProgress--
				--delete if exists to aviod constraint violation--
				if (@tableName <> 'MigrationProgress' and @dbType <> 'COM')
				begin
					if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME='MigrationProgress')
					begin
						delete from MigrationProgress where RQEVersion=@RQEVersion and SeqNum=@seqNum;
						insert into MigrationProgress values(@RQEVersion,@buildVersion,@seqNum,'');
					end
				end

				if len(@finalScript) > 0
				begin
					begin try
						if @debug=1 exec absp_MessageEx @finalScript;
						if exists (select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @scriptInfo;

						execute (@finalScript);

						if (@tableName <> 'MigrationProgress' and @dbType <> 'COM')
						begin
							if (@isCritical <> 'Y')
							begin
								if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME='MigrationProgress')
									update MigrationProgress set Status='S' where RQEVersion=@RQEVersion and seqNum=@seqNum;
							end
						end
					end try
					begin catch

						if (@tableName <> 'MigrationProgress' and @dbType <> 'COM')
						begin
							if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME='MigrationProgress')
								update MigrationProgress set Status='F' where RQEVersion=@RQEVersion and seqNum=@seqNum;
						end

						set @migrationFailed=1;

						declare @PrName varchar(100),
						@msg as varchar(1000),
						@module as varchar(100),
						@ErrorMessage varchar(4000);

						select @PrName = object_name(@@procid);
						select
							@module = isnull(ERROR_PROCEDURE(),@PrName),
							@msg='"'+ERROR_MESSAGE()+'"'+
						        '  Line: '+cast(ERROR_LINE() as varchar(10))+
							'  No: '+cast(ERROR_NUMBER() as varchar(10))+
							'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
						        '  State: '+cast(ERROR_STATE() as varchar(10)),
							@ErrorMessage='Exception: Top Level '+@PrName+'. Occurred in '+@module+'. Error: '+@msg;

						if exists(select 1 from sys.objects where name = 'absp_Migr_LogIt' and type='P') exec absp_Migr_LogIt @ErrorMessage;

						break;
					end catch
				end
				else
				begin
					if (@tableName <> 'MigrationProgress' and @dbType <> 'COM')
					begin
						if (@isCritical <> 'Y')
							if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME='MigrationProgress')
								update MigrationProgress set Status='S' where RQEVersion=@RQEVersion and seqNum=@seqNum;
					end
				end
			end

			fetch curs2 into @seqNum,@isCritical,@tableName,@scriptText,@scriptInfo;
		end
		close curs2
		deallocate curs2

		if @migrationFailed=1
		begin
			set @msgText = '-- Error absp_Migr_ExecuteMigrationScript: Failed';
			exec absp_Migr_LogIt @msgText;
			if (@debug = 1) print @msgText;;
			break;
		end

		else

		begin
			--Add insert version to script file--
			exec absp_Util_GetDateString @dt output,'yyyymmdd';

			set @sql = 'insert into RQEVersion ' +
					'select top(1) ''' + @dbType + ''',SchemaVersion,RQEVersion,FlCertificationVersion,''@dt'',Build,'''','''',''Migrated DB from RQE'' from systemdb.dbo.RQEVersion where RQEVersion=''' + @RQEVersion + ''' order by RQEVersionKey desc;';
			set @sql = replace(@sql, '@dt', @dt);

			if (@debug = 1) print @sql;

			exec (@sql);

			set @msgText = '-- absp_Migr_ExecuteMigrationScript: Updated RQE Version to ' + @RQEVersion;
			exec absp_Migr_LogIt @msgText;

			-- Apply Hotfix if any
			exec absp_Migr_ApplyUpdate @dbType, @dbName, 1;
		end

		fetch curs1 into @RQEVersion;
	end
	close curs1
	deallocate curs1

	set @msgText = '-- End absp_Migr_ExecuteMigrationScript: Completed';
	exec absp_Migr_LogIt @msgText;

	return @migrationFailed;
end
