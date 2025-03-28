if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachDatabase;
end
go

create procedure absp_Util_AttachDatabase
    @rc varchar(255) output,
    @databaseName varchar(255),
	@dbPath varchar(254) = 'C:\WCeDB\Currency\Primary',
	@dbLogPath varchar(254) = 'C:\WCeDB\Currency\Primary',
	@attachNoLog int = 0

/*
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure attachs a database file located in $\WceDB\Currency

Returns:      successful or error messages
====================================================================================================

##PD  @databaseName ^^  database name
##PD  @dbPath ^^  full datase path excluding the database name

##RD  @rc ^^ successful or error messages.
*/
AS
begin

	set nocount on;

	declare @fileName varchar(255);
	declare @fileName_log varchar(255);
	declare @folderName varchar(255);
	declare @cmd varchar(1000);
	declare @cmd2 varchar(1000);
	declare @status integer;
	declare @file_exists int;
	declare @logfileName varchar(255);
	declare @logicalDBName  varchar(255);
	declare @version varchar(255);
	declare @dbtype varchar(255);
	declare @sqlString nvarchar(1000);
	declare @srcFile varchar(255)
	declare @tgtFile varchar(255);
	declare @xp_cmdshell_enabled int;

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;

	select @dbPath = replace(@dbPath,'/','\');
	select @dbLogPath = replace(@dbLogPath,'/','\');
	set @rc = '';
	set @status = 0; -- 0 == success, -1 == no such mdf, -2 == any other error

	set @logfileName = @databaseName + '_log.ldf';
	set @folderName = rtrim(@dbPath);
	set @fileName = @folderName + '\' + @databaseName + '.mdf';
	set @folderName = rtrim(@dbLogPath);
	set @fileName_log = @folderName + '\' + @logfileName

	-- if mdf file not there return news to caller
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'dir "' + @fileName + '"';
		exec @file_exists = xp_cmdshell @cmd, no_output;
	end
	else
	begin
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName);
		if @file_exists=0 set @file_exists=1 else set @file_exists=0;
	end

	if @file_exists <> 0
	begin
		set @status = -1;
		set @rc = 'Error: Database ' + @databaseName + ' does not exist.';
		return @status;
	end

	-- if ldf file not there, set attachNoLog flag to true
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'dir "' + @fileName_log + '"';
		exec @file_exists = xp_cmdshell @cmd, no_output;
	end
	else
	begin
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName_log);
		if @file_exists=0 set @file_exists=1 else set @file_exists=0;
	end

	if @file_exists <> 0
	begin
		set @attachNoLog = 1;
	end


	-- force mdf to writable
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'attrib -r "' + ltrim(rtrim(@fileName)) + '"';
		exec xp_cmdshell @cmd, no_output;
	end
	else
	begin
		exec @status = systemdb.dbo.clr_Util_FileSetAttributes @fileName, 'R',1
	end

	-- force ldf to writable if we have one
	if @attachNoLog != 1
	begin
		if (@xp_cmdshell_enabled = 1)
		begin
			set @cmd = 'attrib -r "' + ltrim(rtrim(@fileName_log)) + '"';
			exec xp_cmdshell @cmd, no_output;
		end
		else
		begin
			exec @status = systemdb.dbo.clr_Util_FileSetAttributes @fileName_log, 'R',1
		end
	end

	begin try
        if not exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@databaseName)))
		begin
			if @attachNoLog = 1 -- attach but without log file
			begin
				set @cmd = 'CREATE DATABASE [' + ltrim(rtrim(@databaseName))  + '] ON' +
					' (FILENAME = ''' + ltrim(rtrim(@fileName)) + ''')' +
					' FOR ATTACH';
				print @cmd;
				EXEC (@cmd);

				--If physical filename and logical db name differs, fix it--
				select @logicalDBName = name FROM sys.master_files
					where file_id = 1  and database_id =
       					 ( select database_id from sys.databases where name = ltrim(rtrim(@databaseName)) );

				if (@logicalDBName <> @databaseName)
				begin
					set @cmd2 = 'alter database [' + ltrim(rtrim(@databaseName)) + '] ' +
						'modify file (name = ''' +  ltrim(rtrim(@logicalDBName)) + ''',' +
						'newname = ''' +  ltrim(rtrim(@databaseName)) + ''')';
					print @cmd2;
					exec (@cmd2);

					set @cmd2 = 'alter database [' + ltrim(rtrim(@databaseName)) + '] ' +
						'modify file (name = ''' +  ltrim(rtrim(@logicalDBName))+ '_log'',' +
						'newname = ''' +  ltrim(rtrim(@databaseName))+ '_log'')';
					print @cmd2;
					exec (@cmd2);
				end

				if (@dbPath <> @dbLogPath)
				begin
					-- do alter database change log file location
					set @cmd2 = 'alter database [' + ltrim(rtrim(@databaseName)) + '] ' +
						'modify file (name = ''' +  ltrim(rtrim(@databaseName)) + '_log'',' +
						'filename = ''' +  ltrim(rtrim(@fileName_log)) + ''')';
					print @cmd2;
					EXEC (@cmd2);

					-- detach db
					exec absp_Util_DetachDB @databaseName, 0;

					-- move log file from default location to proper location
					if (@xp_cmdshell_enabled = 1)
					begin
						set @cmd2 = 'move "' + rtrim(@dbPath) + '\' + @logfileName + '"  "' + rtrim(@dbLogPath) + '\' + @logfileName + '"';
						exec xp_cmdshell @cmd2, no_output;
					end
					else
					begin
						set @srcFile=rtrim(@dbPath) + '\' + @logfileName;
						set @tgtFile=rtrim(@dbLogPath) + '\' + @logfileName;
						exec systemdb.dbo.clr_Util_FileMove @srcFile, @tgtFile;
					end

					-- attach again
					EXEC (@cmd);
				end
			end
			else
			begin
				set @cmd = 'CREATE DATABASE [' + ltrim(rtrim(@databaseName))  + '] ON' +
					' (FILENAME = ''' + ltrim(rtrim(@fileName)) + '''),' +
	 				' (FILENAME = ''' + ltrim(rtrim(@fileName_log)) + ''')' +
					' FOR ATTACH';
				print @cmd;
				exec (@cmd);

				--If physical filename and logical  db name differs, fix it--
				select @logicalDBName = name FROM sys.master_files
				 	where file_id = 1  and database_id =
					 ( select database_id from sys.databases where name = ltrim(rtrim(@databaseName)) );

				if (@logicalDBName <> @databaseName)
				begin
					set @cmd = 'alter database [' + ltrim(rtrim(@databaseName)) + '] ' +
				 		'modify file (name = ''' +  ltrim(rtrim(@logicalDBName))+ '_log'',' +
						'newname = ''' +  ltrim(rtrim(@databaseName))+ '_log'')';
					print @cmd;
					exec (@cmd);
				end
			end
			set @rc = @rc + 'Attached database ' + @databaseName + '.' + '|';
		end
		-- if offline, make it online
		else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@databaseName)) and state_desc = 'offline')
		begin
			set @cmd = 'ALTER DATABASE [' + ltrim(rtrim(@databaseName)) + '] SET ONLINE WITH ROLLBACK IMMEDIATE';
			print @cmd;
			EXEC (@cmd);
			set @rc = @rc + 'Brought database' + @databaseName + ' ONLINE.' + '|';
		end
        else -- already attached
		begin
			set @rc = @rc + @databaseName + ' is already attached.' + '|';
		end

		--Mantis 929 - Ensure that it has the collation we need
		set @cmd = 'ALTER DATABASE [' + ltrim(rtrim(@databaseName)) + '] COLLATE SQL_Latin1_General_CP1_CI_AS';
		print @cmd;
		EXEC (@cmd);
		set @rc = @rc + 'Set collation for [' + @databaseName + '] to SQL_Latin1_General_CP1_CI_AS|';

		exec absp_Util_setDBCmptLevel @databaseName;

		-- validate database by querying RQEVersion -- if no RQEVersion table exception will be thrown
		set @sqlString = N'select @versionOUT = RQEVersion, @dbtypeOUT = DbType from [' + @databaseName + '].dbo.RQEVersion';
		execute sp_executesql @sqlString, N'@versionOUT varchar(255) OUTPUT, @dbtypeOUT varchar(20) OUTPUT', @versionOUT=@version OUTPUT, @dbtypeOUT=@dbtype OUTPUT;

		if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
			drop synonym MigrateLookupID;

	end try

	begin catch
		set @status = -2;
		set @rc = 'Error attaching ' + @databaseName + ': ' + ERROR_MESSAGE();
		if exists ( select 1 from sys.databases where name = @databaseName )
		begin
			exec sp_detach_db @databaseName;
		end
	end catch

	return @status;

end
