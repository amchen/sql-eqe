if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DetachDB') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DetachDB;
end
go

create procedure absp_Util_DetachDB @dbName varchar(255), @deleteLogFile int = 1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:		This procedure will detach the given database from the server and then delete the log file
				depending on the second parameter. Default is 1 which will delete it else keep the file.

Returns:        Returns 1 for success, 0 for failure.
====================================================================================================
</pre>
</font>
##BD_END

##PD	@dbName			^^  The name of the database to be detached.
##PD	@deleteLogFile	^^  Flag which says delete the log file after detaching the database from the server.
							1 for Delete else keep the file.
##RD	@ret_status		^^  Returns 1 for success, 0 for failure.

*/
as
begin

	set nocount on;

	declare @sql nvarchar(MAX);
	declare @fileName varchar(255);
	declare @mdfPath varchar(1000);
	declare @logPath varchar(1000);
	declare @mdfDir varchar(1000);
	declare @logDir varchar(1000);
	declare @ret_status int;
	declare @cmd varchar(1000);
	declare @longName varchar(255);
	declare @sourcedbName varchar(255);
	declare @rc varchar(255);
	declare @dbRefKey int;
	declare @xp_cmdshell_enabled int;
	declare @dbType char(3);

	set @ret_status = 0;
	set implicit_transactions off;

	if @dbName != ''
	begin try
		--Delete TaskInfo and DownloadInfo entries for the database--

		--DBRefKey saved in DownloadInfo and TaskInfo is actually the databaseID of the RDB--
		select @dbRefKey = SDB.database_id from sys.databases SDB inner join sys.master_files SMF on SDB.database_id = SMF.database_id  where SMF.file_id = 1 and SDB.state_desc = 'online' and SDB.name = @dbname;
		delete from commondb.dbo.DownloadInfo where DbRefKey = @dbRefKey;
		delete from commondb.dbo.TaskInfo where DBRefKey = @dbRefKey;

		-- get the mdf file name and fully qualified path so that after detaching the DB we can delete it
		set @sql = 'select @mdfPath = physical_name from [' + @dbName + '].sys.database_files where type = 0';
		exec sp_executesql @sql, N'@mdfPath varchar(1000) output', @mdfPath output;
		SELECT @mdfDir = substring(@mdfPath, 0, LEN(@mdfPath) - CHARINDEX('\', REVERSE(@mdfPath)) + 1);

		-- get the log file name and fully qualified path so that after detaching the DB we can delete it
		set @sql = 'select @fileName = name, @logPath = physical_name from [' + @dbName + '].sys.database_files where type = 1';
		exec sp_executesql @sql, N'@fileName varchar(255) output, @logPath varchar(1000) output', @fileName output, @logPath output;
		SELECT @logDir = substring(@logPath, 0, LEN(@logPath) - CHARINDEX('\', REVERSE(@logPath)) + 1);

		set @sql = 'select @dbType = DbType from [' + @dbName + '].dbo.RQEVersion';
		exec sp_executesql @sql, N'@dbType char(3) output', @dbType output;

		if (@dbType = 'RDB')
		begin
			set @sql = 'select @longName = LongName, @sourcedbName = SourceDatabaseName from [' + @dbName + '].dbo.RdbInfo where NodeType = 101';
			exec sp_executesql @sql, N'@longName varchar(255) output, @sourcedbName varchar(255) output', @longName output, @sourcedbName output;
		end
		else
		begin
			select @longName = LongName from commondb..CFldrInfo where DB_NAME = @dbName;
			set @sourcedbName = @dbName;
		end

		-- there is a database rename
		if (@sourcedbName is not null) and (@sourcedbName <> '') and ltrim(rtrim(@longName)) != ltrim(rtrim(@sourcedbName))
		begin
			if (@dbType = 'RDB')
				exec commondb.dbo.absp_Util_RenameRDB @sourcedbName, @longName, @mdfDir, @logDir;
			else
				exec systemdb.dbo.absp_Util_RenameDatabase @sourcedbName, @longName, @mdfDir, @logDir;

			set @dbName = @longName;
			set @mdfPath = @mdfDir + '\' + @dbname + '.mdf';
			set @logPath = @logDir + '\' + @dbname + '_log.ldf';
			set @fileName = @dbname + '_log';
		end

		set @sql = 'USE [' + @dbName + '] ';

		set @sql = @sql + 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE ';

		-- Shrink the truncated log file to 1 MB.
		if (@deleteLogFile <> 1)
			set @sql = @sql + 'DBCC SHRINKFILE ([' + @fileName + '], 1) WITH NO_INFOMSGS;';

		exec sp_executesql @sql;

		-- Now detach the Database from SQL Server.
		if exists ( select 1 from sys.databases where name = @dbName )
		begin
			exec sp_detach_db @dbName;

			exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;
			--Skip executing icacls.exe if xp_cmdshell is not enabled--
			if (@xp_cmdshell_enabled = 1)
			begin
				if exists (select 1 from commondb..BkProp where Bk_Key='GrantPermissionToDB' and Bk_Value='True')
				begin
					set @cmd = 'icacls "' + @mdfPath + '\*.*" /grant Everyone:F';
					exec xp_cmdshell @cmd, no_output;
					set @cmd = 'icacls "' + @logPath + '\*.*" /grant Everyone:F';
					exec xp_cmdshell @cmd, no_output;
				end
			end
		end

		-- Now delete the log file when all things go well.
		if (@deleteLogFile = 1)
			exec absp_Util_DeleteFile @logPath;

		set @ret_status = 1;

		return @ret_status;
	end try

	begin catch
		set @ret_status = 2;
		set @rc = 'absp_Util_DetachDB: Error detaching and renaming ' + @dbName + ': ' + ERROR_MESSAGE();
		return @ret_status;
	end catch
end
