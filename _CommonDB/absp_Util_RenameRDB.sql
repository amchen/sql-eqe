if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_RenameRDB') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_RenameRDB;
end
go

CREATE PROCEDURE absp_Util_RenameRDB
(
	@sourceName varchar(254) = 'Base_CurrencyFolder',
	@destName varchar(254), -- the new CF database name
	@destLocation varchar(254) = 'C:\WceDB\Currency\PRI',
	@destLogLocation varchar(254) = 'C:\WceDB\Currency\PRI'
)
/*
====================================================================================================
Purpose:

This procedure copies the base currency folder "Base_CurrencyFolder" or "Base_CurrencyFolder_IR" from
the "$\WCeDB\Base" folder to "$\WCeDB\Currency" and then rename their database names, logical names,
logical file names and physical file names to the ones of a new default currency folder name

Returns:       None.
====================================================================================================
*/
AS
BEGIN
	DECLARE @query varchar(2000);
	DECLARE @sourceDBName varchar(255);
	DECLARE @sourceDb_mdf varchar(400);
	DECLARE @sourceDb_ldf varchar(400);
	DECLARE @destDbName varchar(255);
	DECLARE @destDb_mdf varchar(400);
	DECLARE @destDb_ldf varchar(400);
	DECLARE @bkValue varchar(20);
	DECLARE @xp_cmdshell_enabled int;
	DECLARE @destDBNm varchar(255);

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;

	set @sourceDb_mdf = ltrim(rtrim(@destLocation)) +  '\' + ltrim(rtrim(@sourceName)) + '.mdf';
	set @sourceDb_ldf = ltrim(rtrim(@destLogLocation)) +  '\' + ltrim(rtrim(@sourceName)) + '_log.ldf';
	set @destDb_mdf = ltrim(rtrim(@destLocation)) +  '\' +   ltrim(rtrim(@destName)) + '.mdf';
	set @destDb_ldf = ltrim(rtrim(@destLogLocation)) + '\' + ltrim(rtrim(@destName)) + '_log.ldf';
	set @sourceDBName = '[' + ltrim(rtrim(@sourceName)) + ']';
	set @destDbName = '[' + ltrim(rtrim(@destName)) + ']';

	-- if detached, attach base Primary DB can
	if not exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@sourceName)))
	begin
		set @query = 'CREATE DATABASE ' + ltrim(rtrim(@sourceDBName))  + ' ON' +
			' (FILENAME = ''' + ltrim(rtrim(@sourceDb_mdf)) + '''),' +
 			' (FILENAME = ''' + ltrim(rtrim(@sourceDb_ldf)) + ''')' +
			' FOR ATTACH';
	--	print @query;
		EXEC (@query);
	end
	-- if offline, set online
	else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@sourceDBName)) and state_desc = 'offline')
	begin
		set @query = 'ALTER DATABASE ' + ltrim(rtrim(@sourceDBName)) + ' SET ONLINE WITH ROLLBACK IMMEDIATE';
	--	print @query;
		EXEC (@query);
	end

	--Set Database as a Single User
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@sourceDBName)) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE';
   --	print @query;
	EXEC (@query);

	-- Change database names
	--EXEC sp_renamedb @sourceDBName, @destDbName
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@sourceDBName)) + ' MODIFY NAME = ' + ltrim(rtrim(@destDbName));
   -- print @query;
	EXEC (@query);

	-- change logical file names
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@destDbName)) +
					' MODIFY FILE (NAME = ' + ltrim(rtrim(@sourceDBName)) + ' , NEWNAME = ' + ltrim(rtrim(@destDbName)) + ')';
   -- print @query;
	EXEC (@query);
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@destDbName)) +
					' MODIFY FILE (NAME = [' + ltrim(rtrim(@sourceName)) + '_log] , NEWNAME = [' + ltrim(rtrim(@destName)) + '_log])';
   -- print @query;
	EXEC (@query);

	--Set db offline--
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@destDbName)) + ' SET OFFLINE WITH ROLLBACK IMMEDIATE'
	print @query
	EXEC (@query)

	-- Detach Current Database
	set @query = 'sp_detach_db @dbname = ' + @destDbName;
	--print @query;
	EXEC (@query);

	if (@xp_cmdshell_enabled = 1)
	begin
		--skip executing icacls.exe if xp_cmdshell is not enabled--
		select @bkValue=Bk_Value  from commondb..BkProp where Bk_Key='GrantPermissionToDB';
		if @bkValue='True'
		begin
			set @query = 'icacls "' + @destLocation + '\*.*" /grant Everyone:F';
			--print @query;
			exec xp_cmdshell @query, no_output;
			set @query = 'icacls "' + @destLogLocation + '\*.*" /grant Everyone:F';
			--print @query;
			exec xp_cmdshell @query, no_output;
		end

		-- Rename Physical Files
		set @query = 'RENAME "' + ltrim(rtrim(@sourceDb_mdf)) + '", "' + ltrim(rtrim(@destName)) + '.mdf"';
		--print @query
		EXEC xp_cmdshell @query, no_output;
		set @query = 'RENAME "' + ltrim(rtrim(@sourceDb_ldf)) + '", "' + ltrim(rtrim(@destName)) +  '_log.ldf"';
		--print @query
		EXEC xp_cmdshell @query, no_output;
	end
	else
	begin
		--skip executing icacls.exe if xp_cmdshell is not enabled--
		-- Rename Physical Files
		set @destDBNm= dbo.trim(@destName) + '.mdf'
		exec  systemdb.dbo.clr_Util_FileRename @sourceDb_mdf ,@destDb_mdf;
		set @destDBNm= dbo.trim(@destName) +  '_log.ldf'
		exec  systemdb.dbo.clr_Util_FileRename @sourceDb_ldf ,@destDb_ldf;

	end
	-- Attach Renamed  Database Online
	set @query = 'CREATE DATABASE ' + ltrim(rtrim(@destDbName)) + ' ON' +
	' (FILENAME = ''' + ltrim(rtrim(@destDb_mdf)) + '''),' +
	' (FILENAME = ''' + ltrim(rtrim(@destDb_ldf)) +  ''')' +
	' FOR ATTACH';
	--print @query;
	EXEC (@query);

	-- rename long name to the new dbname
	-- An IR database can have a 120 character name + '_IR' = 123 characters.
	-- So, the check for a max of 120 avoids a data truncated exception. Since the update
	-- doesn't do anything in the case of an IR database, it's okay to skip it in this case.
	if len(@destDbName) <= 120
	begin
		set @query = 'use ' + @destDbName + ';';
		set @query = @query + ' update RdbInfo set LongName=''@destName'' where NodeType=101;';
		set @query = @query + ' update RdbInfo set SourceDatabaseName=''@destName'' where SourceDatabaseName=''@sourceName'';';
		set @query = @query + ' update AggInputSources set RdbName=''@destName'' where RdbName=''@sourceName'';';
		set @query = replace(@query, '@destName', rtrim(@destName));
		set @query = replace(@query, '@sourceName', rtrim(@sourceName));
		print @query;
		EXEC (@query);

		--Update DBName in BatchJob
		--Fixed defect 7359--
		update commondb..BatchJob set DBName=@destName where DBName=@sourceName;
		update commondb..Seqplout set DBName=@destName where DBName=@sourceName;
	end

	--Set Database to Multi User
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@destDbName)) + ' SET MULTI_USER';
	--print @query;
	EXEC (@query);

	--Set our Collation just in case
	set @query = 'ALTER DATABASE ' + ltrim(rtrim(@destDbName)) + ' COLLATE SQL_Latin1_General_CP1_CI_AS';
	--print @query;
	EXEC (@query);
	
	exec commondb.dbo.absp_UpdateYLTAnalysisDbNames @sourceName, @destName

END
