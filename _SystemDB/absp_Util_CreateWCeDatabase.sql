if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateWCeDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateWCeDatabase
end

go
create procedure --------------------------------------------------------------
absp_Util_CreateWCeDatabase
	@rc varchar(255) output,
	@databaseName varchar(255),
	@sourcePathPri varchar(254) = 'C:\WCeDB\Base\PRI',
	@destPathPri char(254) = 'C:\WCeDB\Currency\PRI',
	@sourcePathIR char(254) = 'C:\WCeDB\Base\IR',
	@destPathIR char(254) = 'C:\WCeDB\Currency\IR'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new database file located in $\WceDB\Currency

Returns:      successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@databaseName ^^  database name
##PD  @sourcePathPri ^^  full path of the base Primary database excluding the database name
##PD  @sourcePathIR ^^  full path of the base Ir database excluding the database name
##PD  @destPathPri ^^  full path of the user primary currency database excluding the database name
##PD  @destPathIR ^^  full path of the user IR currency database excluding the database name

##RD  @rc ^^ successful or error messages.
*/

AS
begin

	set nocount on

	declare @status integer
	declare @fileName varchar (255)
	declare @file_exists int
	declare @cmd varchar(1000)
	declare @xp_cmdshell_enabled int;

	set @rc = ''
	set @status = 0

	-- is there already an mdf with this name?
 	select @destPathPri = replace(@destPathPri,'/','\')
	-- set @dbPathPri = ltrim(rtrim(@dbPath)) + '\PRI'
	set @fileName = ltrim(rtrim(@destPathPri)) + '\' + ltrim(rtrim(@databaseName)) + '.mdf'
	print '@fileName: ' + @fileName

	--exec xp_fileexist @fileName, @file_exists OUT
	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;
	if (@xp_cmdshell_enabled = 1)
	begin
		set @cmd = 'dir "' + @fileName + '"';
		exec @file_exists = xp_cmdshell @cmd, no_output
		if @file_exists <> 1
		begin
			set @status = -1
			set @rc = 'Database ' + @databaseName + ' already exists. Please choose another database name.'
			return @status
		end
	end
	else
	begin
		set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName);
		if @file_exists = 1
		begin
			set @status = -1
			set @rc = 'Database ' + @databaseName + ' already exists. Please choose another database name.'
			return @status
		end
	end


	-- copy and rename primary database
	exec absp_Util_CreateDefaultCurrencyFolderDB @rc output, @sourcePathPri, @destPathPri, 'PRI', @databaseName
	if (left(@rc, 12) != 'Successfully') -- is this the best way to check the status?
	begin
		set @status = -1
		return @status
	end

	-- copy and rename IR database
	set @databaseName = @databaseName + '_IR'
	exec absp_Util_CreateDefaultCurrencyFolderDB @rc output, @sourcePathIR, @destPathIR, 'IR', @databaseName
	if (left(@rc, 12) != 'Successfully') -- is this the best way to check the status?
	begin
		set @status = -1
		return @status
	end

	return @status
end
