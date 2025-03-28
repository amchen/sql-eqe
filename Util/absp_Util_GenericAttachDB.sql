if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_GenericAttachDB') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GenericAttachDB
end

go
create procedure --------------------------------------------------------------
absp_Util_GenericAttachDB @dbName varchar(255),  @dbLocation varchar(255) = 'C:\WCeDB\_CurrencyDB', @rc varchar(255) output

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure attachs a database

Returns:      messages starting with retCode, 0: success else failure
====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbName ^^  the SQL Server DB name.
##PD  @dbLocation ^^  location of the DB (path)

##RD  @rc ^^ messages starting with retCode, 0: success else failure
*/
AS
begin

 set nocount on

 declare @fileName varchar(255)
 declare @fileName_log varchar(255)
 declare @cmd varchar(1000)
 declare @file_exists int
 declare @folderExists int
 declare @objFso int
 declare @xp_cmdshell_enabled int;

 exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;

	set @rc = ''

	-- Make sure dbLocation folder exists
	exec absp_Util_CreateFolder @dbLocation

    -- check if the file exists
    set @fileName = @dbLocation + '\' + @dbName + '.mdf'
	set @fileName_log = @dbLocation + '\' + @dbName + '_log.ldf'

	-- Check the mdf
	--exec xp_fileexist @fileName, @file_exists OUT
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'dir "' + @fileName + '"'
		exec @file_exists = xp_cmdshell @cmd, no_output
	end
	else
	begin
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName);
		if @file_exists=0 set @file_exists=1 else set @file_exists=0;
	end

	if @file_exists = 1
	begin
	   print '2:' + @fileName + ' does not exist'
	   set @rc = '2:' + @fileName + ' does not exist.'
	   return
	end

	-- Check the log
	--exec xp_fileexist @fileName_log, @file_exists OUT
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'dir "' + @fileName_log + '"'
		exec @file_exists = xp_cmdshell @cmd, no_output
	end
	else
	begin
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName_log);
		if @file_exists=0 set @file_exists=1 else set @file_exists=0;
	end

	if @file_exists = 1
	begin
	   print '3:' + @fileName_log + ' does not exist'
	   set @rc = '3:' + @fileName_log + ' does not exist.'
	   return
	end

    -- if here, file and path are OK, start attaching the DB
    -- if both mdf and ldf exist in  \WCeDB\_CurrencyDB, try to attach the CF
	if not exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@dbName)))
    begin
		set @cmd = 'CREATE DATABASE ' + ltrim(rtrim(@dbName))  + ' ON' +
			' (FILENAME = ''' + ltrim(rtrim(@fileName)) + '''),' +
			' (FILENAME = ''' + ltrim(rtrim(@fileName_log)) + ''')' +
			' FOR ATTACH'
		print @cmd
		EXEC (@cmd)
		set @rc = '0:Attached database ' + @dbName + '.'
	end
	-- if offline, make it online
	else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@dbName)) and state_desc = 'offline')
	begin
		set @cmd = 'ALTER DATABASE ' + ltrim(rtrim(@dbName)) + ' SET ONLINE WITH ROLLBACK IMMEDIATE'
		print @cmd
		EXEC (@cmd)
    	set @rc = '0:Brought database' + @dbName + ' Online.'
	end
	else -- already attached
  		set @rc ='0:' +  @dbName  + ' has already attached, skip it.'

 	--Mantis 929 - Ensure that it has the collation we need
	set @cmd = 'ALTER DATABASE ' + ltrim(rtrim(@dbName)) + ' COLLATE SQL_Latin1_General_CP1_CI_AS'
	print @cmd
	EXEC (@cmd)
	set @rc = '0:Set collation for ' + @dbName + ' to SQL_Latin1_General_CP1_CI_AS|'

	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		drop synonym MigrateLookupID;
	
	print @rc
end