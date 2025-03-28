if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_RenameDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_RenameDatabase;
end
go

CREATE PROCEDURE absp_Util_RenameDatabase
(
	@sourceName varchar(255),
	@destName varchar(255),
	@mdfPath varchar(255) = 'C:\WceDB\Currency\Primary',
	@ldfPath varchar(255) = 'C:\WceDB\Currency\Primary'
)
/*
====================================================================================================
Purpose:

This procedure renames a database without renaming the physical files. It is assumed the physcial
files are already renamed.

Returns:       None.
====================================================================================================
*/
AS
BEGIN
	DECLARE @query varchar(2000);
	DECLARE @sourceDBName varchar(255);
	DECLARE @destDbName varchar(255);
	DECLARE @destDb_mdf varchar(400);
	DECLARE @destDb_ldf varchar(400);
 	DECLARE @create_dat varchar(14);
	DECLARE @dbExistsMsg nvarchar(255);

	set @sourceDBName = ltrim(rtrim(@sourceName));
	set @destDbName = ltrim(rtrim(@destName));
 	select @mdfPath = replace(@mdfPath,'/','\');
 	select @ldfPath = replace(@ldfPath,'/','\');
	set @destDb_mdf = ltrim(rtrim(@mdfPath)) +  '\' +   ltrim(rtrim(@destDbName)) + '.mdf';
	set @destDb_ldf = ltrim(rtrim(@ldfPath)) + '\' + ltrim(rtrim(@destDbName)) + '_log.ldf';

	if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@destDbName)))
	begin
	  set @dbExistsMsg = N'The database "' + @destDbName + '" already exists. Please choose another name.';
	  raiserror (@dbExistsMsg, 11, 1);
	  return;
	end

	-- if detached, attach base Primary DB can
	if not exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@sourceDBName)))
	begin
		set @query = 'CREATE DATABASE [' + ltrim(rtrim(@sourceDBName))  + '] ON' +
			' (FILENAME = ''' + ltrim(rtrim(@destDb_mdf)) + '''),' +
 			' (FILENAME = ''' + ltrim(rtrim(@destDb_ldf)) + ''')' +
			' FOR ATTACH'
		print @query
		EXEC (@query)
	end
	-- if offline
	else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@sourceDBName)) and state_desc = 'offline')
	begin
		set @query = 'ALTER DATABASE [' + ltrim(rtrim(@sourceDBName)) + '] SET ONLINE WITH ROLLBACK IMMEDIATE'
		print @query
		EXEC (@query)
	end

	--Set Database as a Single User
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@sourceDBName)) + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
   	print @query
	EXEC (@query)

	-- Change database names
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@sourceDBName)) + '] MODIFY NAME = [' + ltrim(rtrim(@destDbName)) + ']'
   	print @query
	EXEC (@query)

	-- change logical file names
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@destDbName)) +
					'] MODIFY FILE (NAME = [' + ltrim(rtrim(@sourceDBName)) + '] , NEWNAME = [' + ltrim(rtrim(@destDbName)) + '])'
    	print @query
	EXEC (@query)
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@destDbName)) +
					'] MODIFY FILE (NAME = [' + ltrim(rtrim(@sourceDBName)) + '_log] , NEWNAME = [' + ltrim(rtrim(@destDbName)) + '_log])'
   	print @query
	EXEC (@query)

	--Set Database to Multi User
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@destDbName)) + '] SET MULTI_USER'
   	print @query
	EXEC (@query)

	--Set our Collation just in case
	set @query = 'ALTER DATABASE [' + ltrim(rtrim(@destDbName)) + '] COLLATE SQL_Latin1_General_CP1_CI_AS'
		print @query
	EXEC (@query)

	-- set create_dat in fldrinfo to the current date/time
    exec absp_Util_GetDateString @create_dat output,'yyyymmddhhnnss';
	set @query = 'update [@destDbName].dbo.FldrInfo set Create_Dat = ''@create_dat'' where LongName like ''%WCe%''';
	set @query = replace(@query, '@destDbName', @destDbName);
	set @query = replace(@query, '@create_dat', @create_dat);
	print @query;
	EXEC(@query);

	set @query = 'update [@destDbName].dbo.FldrInfo set LongName=''@destDbName'' where CURR_NODE=''Y''';
	set @query = replace(@query, '@destDbName', @destDbName);
	print @query;
	EXEC(@query);

	-- Create Exposure.Report views to IDB because that is where they are now populated
	declare @sql nvarchar(max);
	set @sql = N'exec ' + quotename(@destDbName) + '..absp_Util_CreateExposureViewsToIDB';
	execute(@sql);

END
