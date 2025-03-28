if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CopyFile') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CopyFile
end

go
create procedure --------------------------------------------------------------
absp_Util_CopyFile
	@rc varchar(255) output,
	@sourceFile varchar(254) ,
	@destFile varchar(254)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure executes a DOS copy command on the SQL Server box.

Returns:      successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@sourceFile ^^  full path to source file to be copied
##PD  @@destFile ^^  full path to destination file

##RD  @rc ^^ successful or error messages.
*/

AS
begin

	set nocount on

	declare @status integer
	declare @cmd varchar(8000)
  	declare @file_exists int
	declare @xp_cmdshell_enabled int;

	set @rc = ''
	set @status = 0

 	select @sourceFile = dbo.trim(replace(@sourceFile,'/','\'))
 	select @destFile = dbo.trim(replace(@destFile,'/','\'))

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;
  	-- if mdf file of the same name already there return news to caller
	if (@xp_cmdshell_enabled = 1)
	begin
		-- execute command via xp_cmdshell
		set @cmd = 'dir "' + @destFile + '"'
		exec @file_exists = xp_cmdshell @cmd, no_output
	end
	else
	begin
		-- execute the command via CLR
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@destFile);
		if @file_exists=0 set @file_exists=1 else set @file_exists=0;
	end

	if @file_exists = 0
	begin
		set @status = -1
		set @rc = 'Error copying ' + ltrim(rtrim(@sourceFile)) + ' to ' + ltrim(rtrim(@destFile)) + ': ' + ltrim(rtrim(@destFile)) + ' already exists.'
		return @status
	end
	begin try
		-- surround file names in double quotes to allow spaces
		if (@xp_cmdshell_enabled = 1)
		begin
			-- execute command via xp_cmdshell
			set @cmd = 'copy /y "' + @sourceFile + '" "' + @destFile + '"'
			print @cmd
			exec xp_cmdshell @cmd, no_output
		end
		else
		begin
			-- execute the unload via CLR
			exec @status = systemdb.dbo.clr_Util_FileCopy @sourceFile, @destFile
		end


  	end try
  	begin catch
		set @status = -1
		set @rc = 'Error copying ' + ltrim(rtrim(@sourceFile)) + ' to ' + ltrim(rtrim(@destFile)) + ': ' + ERROR_MESSAGE()
	end catch

	return @status
end

