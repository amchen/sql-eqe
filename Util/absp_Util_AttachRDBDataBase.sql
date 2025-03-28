if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachRDBDataBase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachRDBDataBase
end

go
create procedure absp_Util_AttachRDBDataBase
	@dbNameToAttach varchar(255),
	@fileToAttach varchar(1000),
	@ldfFile varchar(1000) = '',
	@createdBy varchar(50) = '',
	@userGroupKey int = 0
as
BEGIN
	declare @cmd varchar(1000);
	declare @fileName varchar(255);
	declare @mdfPath varchar(1000);
	declare @ldfPath varchar(1000);
	declare @status int;
	declare @msg varchar(255);
	declare @xp_cmdshell_enabled int;

	set @msg = ''
	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;
		
	if @ldfFile = ''
	begin
		set @ldfFile = left(@fileToAttach, charindex('.mdf',@fileToAttach)-1) + '_log.ldf';
	end

	set @mdfPath = left(@fileToAttach, charindex(@dbNameToAttach + '.mdf', @fileToAttach) - 1);
	set @ldfPath = left(@ldfFile, charindex(@dbNameToAttach + '_log.ldf', @ldfFile) - 1);

	-- remove zzzz_log.ldf file
	if  len(@ldfFile) > 0
	begin

		if (@xp_cmdshell_enabled = 1)
		begin
			-- execute command via xp_cmdshell
			set @cmd = 'del  "' + @ldfFile;
			exec xp_cmdshell @cmd, no_output;
	end
		else
		begin
			-- execute the command via CLR
			exec systemdb.dbo.clr_Util_FileDelete @ldfFile;
		end
	end

	-- do the attach to SQL Server
	exec @status = systemdb..absp_Util_AttachDatabase @msg out, @dbNameToAttach, @mdfPath, @ldfPath, 0
	
	if @status != 0
	begin
		select @status as Status, @msg as Message;
		return;
	end
	
	exec absp_Util_AttachRDBLogical @dbNameToAttach;
	
	-- set the user info in RDBINFO to the user who attaches the database
	if len(@createdBy) > 0 
	begin
		set @cmd = 'update [' + @dbNameToAttach +'].dbo.RdbInfo set createdBy = ''' + rtrim(@createdBy) + ''', UserGroup = (select group_name from usergrps where group_key = ' + ltrim(rtrim(str(@userGroupKey))) + ')';
		execute (@cmd);
	end
	select @status as Status, @msg as Message;
END
