if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateDefaultCurrencyFolderDB') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateDefaultCurrencyFolderDB
end

go
create procedure --------------------------------------------------------------
absp_Util_CreateDefaultCurrencyFolderDB @rc varchar(254) output, @sourcePath varchar(254) = 'C:\WCeDB\Base\PRI', @destPath varchar(254) = 'C:\WceDB\Currency\PRI', @dBType char(3) = 'PRI',@defaultCFName varchar(255) = '_WCe'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a default Primary or IR currency folder using the base
currency folder "Base_CurrencyFolder" or "Base_CurrencyFolder_IR" located in the "$\WCeDB\Base" folder.
	Ex: exec absp_Util_CreateDefaultCurrencyFolderDB output, 'C:\WCeDB\Base','C:\WceDB\Currency', 'IR', 'CF1_IR'

Returns:       success or failure messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourcePath ^^  full path of the base database excluding the database name
##PD  @destPath ^^  full path of the currency database excluding the database name
##PD  @dBType ^^  database type : either PRI or IR.
##PD  @@defaultCFName ^^  default currency folder name

##RD  @rc ^^  returned successful or error messages
*/
AS
begin

 set nocount on

 declare @fileName varchar(254)
 declare @fileName_log varchar(254)
 declare @file_exists int
 declare @folderExists int
 declare @objFso int
 declare @cmd varchar(1000)
 declare @folderName varchar(254)
 declare @baseCfName char(254);
 declare @destFolder varchar(254)
 declare @xp_cmdshell_enabled int;
 declare @retCode int;
 declare @destFilePath varchar(1000);

 set @dbType = rtrim(@dbType)

 select @sourcePath = replace(@sourcePath,'/','\')
 select @destPath = replace(@destPath,'/','\')

 if rtrim(@dbType) = 'IR'
 	set @baseCfName = 'Base_CurrencyFolder' + '_IR'
 else
 	set @baseCfName = 'Base_CurrencyFolder'

 set @rc = ''

 print @sourcePath

 -- check if base CF exists
 set @fileName = ltrim(rtrim(@sourcePath)) + '\' + rtrim(@baseCfName) + '.mdf' -- primary or IR
 print @fileName

  exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;
  
  if (@xp_cmdshell_enabled = 1)
  begin
	-- execute command via xp_cmdshell
	set @cmd = 'dir "' + @fileName + '"';
	exec @file_exists = xp_cmdshell @cmd, no_output
	if @file_exists <> 0
	begin
		print 'File ' + @fileName +  ' Not Found'
		set @rc = 'File ' + @fileName +  ' Not Found'
		return
	end
  end
  else
  begin
	-- execute the unload via CLR
	set @file_exists = systemdb.dbo.clr_Util_FileExists (@fileName);
	if @file_exists= 0
	begin
		print 'File ' + @fileName +  ' Not Found'
		set @rc = 'File ' + @fileName +  ' Not Found'
		return
	end
  end
 
 

 set @fileName_log = ltrim(rtrim(@sourcePath)) + '\'  + rtrim(@baseCfName) + '_log.ldf' -- PRI
 print @fileName_log
 
  if (@xp_cmdshell_enabled = 1)
  begin
	-- execute command via xp_cmdshell
	set @cmd = 'dir "' + @fileName_log + '"';
	exec @file_exists = xp_cmdshell @cmd, no_output
	 if @file_exists <> 0
	begin
		print 'File ' + @fileName_log +  ' Not Found'
		set @rc = 'File ' + @fileName_log +  ' Not Found'
		return
	end
  end
  else
  begin
	-- execute the unload via CLR
	set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName_log);
	if @file_exists = 0
	begin
		print 'File ' + @fileName_log +  ' Not Found'
		set @rc = 'File ' + @fileName_log +  ' Not Found'
		return
	end
  end



 -- create the directory if not exist
 exec absp_Util_CreateFolder @folderName

 -- copy base CF from \Base directory to \Currency directory
 set @destFolder = ltrim(rtrim(@destPath))

 if (@xp_cmdshell_enabled = 1)
  begin
	-- execute command via xp_cmdshell
	set @cmd = 'COPY /Y ' + @fileName + ' ' + @destFolder
    print @cmd
    EXEC @retCode = xp_cmdshell @cmd, no_output
    set @cmd = 'COPY /Y ' + @fileName_log + ' ' + @destFolder
    print @cmd
    EXEC @retCode= xp_cmdshell @cmd, no_output
  end
  else
  begin
  
	-- execute the unload via CLR
	set @destFilePath=@destFolder + '\' +  rtrim(@baseCfName) + '.mdf'
	exec @retCode = systemdb.dbo.clr_Util_FileCopy @fileName, @destFilePath
	set @destFilePath=@destFolder +   '\'  + rtrim(@baseCfName) + '_log.ldf'
	exec @retCode = systemdb.dbo.clr_Util_FileCopy @fileName_log, @destFilePath
  end

 -- rename the currency folder DB
 exec absp_Util_RenameCurrencyDB @baseCfName, @defaultCFName, @destFolder, @destFolder 
 set @rc = 'Successfully created the default currency folder ' + @defaultCFName
 print @rc
end
