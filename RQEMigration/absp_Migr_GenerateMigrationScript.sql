if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_GenerateMigrationScript') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_GenerateMigrationScript;
end
go

create procedure absp_Migr_GenerateMigrationScript
	@scriptFileName varchar(255),
	@sourceRQEVersion varchar(25),
	@dbType varchar(3)='',
	@debug int=0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure generates the instructions from MigrationScript table filtered on script options.
		The script is output to a script.sql file and provided to clients with an external DBMS.
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
	declare @RQEVersion varchar(25);
	declare @Build varchar(25);
	declare @scriptInfo varchar(200);
	declare @scriptText varchar(max);
	declare @finalScript varchar(max);
	declare @msg varchar(1000);
	declare @dt varchar(8);
	declare @seqNum int;
	declare @strClause varchar(500);
	declare @tablename varchar(120);
	declare @comdb char(1);
	declare @edb char(1);
	declare @rdb char(1);
	declare @msgText varchar(100);
	declare @crlf char(2);
	declare @tab char(1);
	declare @loop1 varchar(1000);
	declare @loop2 varchar(1000);
	declare @attrib int;

	set @crlf = char(10) + char(13);
	set @tab  = char(9);

	--Delete file if exists--
	exec absp_Util_DeleteFile @scriptFileName;

	--create temporary table to hold script to write to file--
	if OBJECT_ID('tempdb..##MIGR_SCRIPT','u') is not null drop table ##MIGR_SCRIPT;
	create table ##MIGR_SCRIPT (line_no int identity not null,line varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS);

	insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');
	insert into ##MIGR_SCRIPT values('-- RQE Database Migration Script');
	insert into ##MIGR_SCRIPT values('-- Date Created: ' + cast(getdate() as varchar(30)) );
	insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------' + @crlf);

	set @sql = 'if not exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME=''MigrationProgress'') begin';
	insert into ##MIGR_SCRIPT values(@sql);
	set @sql = @tab + 'SET ANSI_PADDING OFF;SET ANSI_NULL_DFLT_ON ON;SET ANSI_NULLS ON; create table MigrationProgress (RQEVersion VARCHAR (25) DEFAULT '''', Build VARCHAR (25) DEFAULT '''', SeqNum INT DEFAULT 0, Status CHAR (1) DEFAULT '''');';
	insert into ##MIGR_SCRIPT values(@sql);
	set @sql = @tab + 'CREATE UNIQUE CLUSTERED INDEX MigrationProgress_I1 ON MigrationProgress ( RQEVersion,Build,SeqNum,Status ); end;';
	insert into ##MIGR_SCRIPT values(@sql + @crlf);

	insert into ##MIGR_SCRIPT values('declare @errorlevel int;');
	insert into ##MIGR_SCRIPT values('declare @sourceRQEVersion varchar(25);');
	insert into ##MIGR_SCRIPT values('declare @dbType varchar(3);');
	insert into ##MIGR_SCRIPT values('declare @dbName varchar(200);' + @crlf + @crlf);
	insert into ##MIGR_SCRIPT values('set @errorlevel = 0;');
	insert into ##MIGR_SCRIPT values('select @sourceRQEVersion = rtrim(max(RQEVersion)) from RQEVersion;' + @crlf + @crlf);

	if (@dbType='COM')
	begin
		set @loop1 = 'select distinct RQEVersion from systemdb.dbo.MigrationScript where RQEVersion > ''@sourceRQEVersion'' and IsDisabled <> ''Y'' order by RQEVersion';
	end
	else
	begin
		set @loop1 = 'select distinct RQEVersion from systemdb.dbo.MigrationScript where RQEVersion > ''@sourceRQEVersion'' and HotfixVersion = '''' and IsDisabled <> ''Y'' order by RQEVersion';
	end

	set @loop1 = replace(@loop1,'@sourceRQEVersion',@sourceRQEVersion);

	--Loop for each RQEVersion--
	execute('declare curs1 cursor forward_only global for ' + @loop1);
	open curs1;
	fetch curs1 into @RQEVersion;
	while @@FETCH_STATUS=0
	begin

		print '-- Generating Script for RQE Version ' + @RQEVersion;
		insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');
		insert into ##MIGR_SCRIPT values('-- RQE Version ' + @sourceRQEVersion + ' to ' + @RQEVersion);
		insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------' + @crlf + @crlf);
		insert into ##MIGR_SCRIPT values('if ((select max(RQEVersion) from RQEVersion) < ''' + @RQEVersion + ''') begin' + @crlf);
		if (@dbType='COM')
			insert into ##MIGR_SCRIPT values('print ''*** Migrating commondb database to version ' + @RQEVersion + ' ***'';' + @crlf);
		else
			insert into ##MIGR_SCRIPT values('print ''*** Migrating User database to version ' + @RQEVersion + ' ***'';' + @crlf);
		insert into ##MIGR_SCRIPT values('begin tran;' + @crlf);
		insert into ##MIGR_SCRIPT values('set @dbName = DB_NAME();');
		insert into ##MIGR_SCRIPT values('select top 1 @dbType = dbType from RQEVersion;' + @crlf);

		if (@dbType='COM')
		begin
			set @loop2 = 'select SeqNum,TableName,ScriptText,ScriptInfo,Attrib,Build from systemdb.dbo.MigrationScript where RQEVersion=''@RQEVersion'' and IsDisabled='''' and IsExternal<>''N'' and (@strClause) order by SeqNum';
   			set @strClause = 'TableName in (select TableName from DictTbl where Com_DB in (''Y'',''L'') union select ''COM'')';
   		end
		else
		begin
			set @loop2 = 'select SeqNum,TableName,ScriptText,ScriptInfo,Attrib,Build from systemdb.dbo.MigrationScript where RQEVersion=''@RQEVersion'' and IsDisabled='''' and IsExternal<>''N'' and HotfixVersion='''' and (@strClause) order by SeqNum';
   			set @strClause = 'TableName <> ''COM'' and TableName in (select TableName from DictTbl where Cf_DB in (''Y'',''L'') union select TableName from DictTbl where RDB in (''Y'',''L'') union select ''EDB'' union select '''' union select ''RDB'')';
   		end

		--Inner loop 2: Loop each step for the build
		set @loop2 = replace(@loop2,'@RQEVersion',@RQEVersion);
		set @loop2 = replace(@loop2,'@strClause',@strClause);

   		execute('declare curs2 cursor forward_only global for ' + @loop2);
		open curs2;
		fetch curs2 into @seqNum,@tableName,@scriptText,@scriptInfo,@attrib,@build;
		while @@FETCH_STATUS =0
		begin

			insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');
			set @sql='-- ' + @scriptInfo;
			insert into ##MIGR_SCRIPT values(@sql);
			insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');

			--If TableName is empty, the step is for all user databases.
			if @tableName <> ''
			begin
				if @tableName in ('EDB','IDB')
				begin
					set @sql='if (@dbType in (''EDB'',''IDB''))';
					insert into ##MIGR_SCRIPT values(@sql);
				end
				else if @tableName in ('RDB')
				begin
					set @sql='if (@dbType in (''RDB''))';
					insert into ##MIGR_SCRIPT values(@sql);
				end
				else if @tableName in ('COM')
				begin
					set @sql='if (@dbType in (''COM''))';
					insert into ##MIGR_SCRIPT values(@sql);
				end
				else
				begin
					if exists (select 1 from systemdb.dbo.DictTbl where TABLENAME=@tableName)
					begin
						set @sql='if (@dbType in (@comdb@edb@rdb@@))';

						-- Determine if tableName belongs in this database
						select @comdb=Com_DB,@edb=CF_DB,@rdb=RDB from systemdb.dbo.DictTbl where TABLENAME=@tableName;

						if (@comdb in ('Y','L'))
							set @sql = replace(@sql,'@comdb','''COM'',');
						else
							set @sql = replace(@sql,'@comdb','');

						if (@edb in ('Y','L'))
							set @sql = replace(@sql,'@edb','''EDB'',''IDB'',');
						else
							set @sql = replace(@sql,'@edb','');

						if (@rdb in ('Y','L'))
							set @sql = replace(@sql,'@rdb','''RDB'',');
						else
							set @sql = replace(@sql,'@rdb','');

						-- remove last comma
						set @sql = replace(@sql,',@@','');

						insert into ##MIGR_SCRIPT values(@sql);
					end
				end
			end

			begin
				--Translate if the Script has annotations--
				exec absp_Migr_AnnotationHelper @finalScript out, @scriptText, @tableName, @RQEVersion;

				--Insert script--
				if (@finalScript <> '')
				begin
					--Add try catch block to script file--
					insert into ##MIGR_SCRIPT values('begin try');

					--Insert script to add row in MigrationProgress--
					--delete if exists to avoid constraint violation--
					if (@tableName <> 'MigrationProgress')
					begin
						set @sql = @tab + 'delete from MigrationProgress where RQEVersion=''' + @RQEVersion + ''' and Build=''' + @build + ''' and SeqNum=' + dbo.trim(cast(@seqNum as varchar(10))) + ';';
						insert into ##MIGR_SCRIPT values(@sql);
						set @sql = @tab + 'insert into MigrationProgress values(''' + @RQEVersion + ''',''' + @build + ''',' + dbo.trim(cast(@seqNum as varchar(10))) + ',''F'');';
						insert into ##MIGR_SCRIPT values(@sql);
					end

					-- escape single quotes
					set @scriptInfo = replace(@scriptInfo,'''','''''');

					set @sql = @tab + 'if exists (select 1 from sys.objects where name = ''absp_Migr_LogIt'' and type=''P'')' + @crlf + @tab + @tab + 'exec absp_Migr_LogIt ''@scriptInfo'';' + @crlf;
					set @sql = replace(@sql,'@scriptInfo',@scriptInfo);
					insert into ##MIGR_SCRIPT values(@sql);

					if (@attrib = 1)
					begin
						-- Use exec() command
						set @sql = replace(@finalScript,'''','''''');
						set @sql = @tab + 'exec (''' + @sql + ''')';
					end
					else
					begin
						set @sql = @tab + @finalScript;
					end

					insert into ##MIGR_SCRIPT values(@sql);

					if (@tableName <> 'MigrationProgress')
					begin
						--Insert script to update MigrationProgress table--
						set @sql = @tab + 'update MigrationProgress set Status=''S'' where RQEVersion=''' + @RQEVersion + ''' and Build=''' + @build + ''' and SeqNum=' + dbo.trim(cast(@seqNum as varchar(10))) + ';';
						insert into ##MIGR_SCRIPT values(@sql);
					end

					--Add end..try to script file--
					insert into ##MIGR_SCRIPT values('end try');

					insert into ##MIGR_SCRIPT values('begin catch');

					insert into ##MIGR_SCRIPT values(@tab + 'set @errorlevel = @errorlevel + 1;');
					set @msg = 'raiserror (''Migration Failed: ' + @scriptInfo + ''', 16, 1);';
					set @sql = @tab + @msg;
					insert into ##MIGR_SCRIPT values(@sql);

					insert into ##MIGR_SCRIPT values('end catch;' + @crlf);
				end
			end
			fetch curs2 into @seqNum,@tableName,@scriptText,@scriptInfo,@attrib,@build;
		end
		close curs2
		deallocate curs2

		--Add insert version to script file--
		insert into ##MIGR_SCRIPT values(@crlf + '-------------------------------------------------------------------------------');
		insert into ##MIGR_SCRIPT values('-------------- Update RQEVersion ----------------------------------------------');
		insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');

		set @sql = 'if not exists (select 1 from RQEVersion where RQEVersion=''@RQEVersion'')';
		set @sql = replace(@sql,'@RQEVersion',@RQEVersion);
		insert into ##MIGR_SCRIPT values(@sql);

		set @sql = @tab + 'insert into RQEVersion ' +
			'select top(1) @dbType,SchemaVersion,RQEVersion,FlCertificationVersion,cast(year(GetDate()) as varchar(4))+right(''0''+cast(month(GetDate()) as varchar(2)),2)+right(''0''+cast(day(GetDate()) as varchar(2)),2),Build,'''','''',''Migrated DB from Script'' ' +
			'from systemdb.dbo.RQEVersion where RQEVersion=''' + @RQEVersion + ''' order by RQEVersionKey desc;';

		insert into ##MIGR_SCRIPT values(@sql);

		insert into ##MIGR_SCRIPT values(@crlf + 'if @errorlevel = 0 commit tran; else rollback tran;');
		insert into ##MIGR_SCRIPT values(@crlf + 'end;' + @crlf);

		set @sourceRQEVersion = @RQEVersion;

		fetch curs1 into @RQEVersion;
	end
	close curs1
	deallocate curs1

	insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');
	insert into ##MIGR_SCRIPT values('---------------- End of Script ------------------------------------------------');
	insert into ##MIGR_SCRIPT values('-------------------------------------------------------------------------------');

	--Write to file
	exec absp_Util_UnloadData 'Q','select line from ##MIGR_SCRIPT order by line_no', @scriptFileName;

	if OBJECT_ID('tempdb..##MIGR_SCRIPT','u') is not null drop table ##MIGR_SCRIPT;
end
