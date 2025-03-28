if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DetachWCeDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DetachWCeDatabase
end
go

create procedure absp_Util_DetachWCeDatabase
    @rc varchar(255) output,
    @dbName varchar(255),
	@forced int = 0,
	@longname varchar(255) = '',
	@dbPathPri varchar(254) = 'C:\WCeDB\Currency\PRI',
	@dbPathIR varchar(254) = 'C:\WCeDB\Currency\IR',
	@dbLogPathPri varchar(254) = 'C:\WCeDB\Currency\PRI',
	@dbLogPathIR varchar(254) = 'C:\WCeDB\Currency\IR'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:		This procedure will detach the given database from the server.

Returns:        Returns 1 for success, 0 for failure.
====================================================================================================
</pre>
</font>
##BD_END

##PD	@dbName			^^  The name of the database to be detached.
##RD	@ret_status		^^  Returns 0 for success, non-zero for failure.

*/
as
begin

   set nocount on

	declare @sql nvarchar(MAX)
	declare @fileName varchar(255)
	declare @filePath varchar(1000)
	declare @ret_status int
	declare @dbNameIR varchar(255)
	declare @longNameIR varchar(255)
	declare @file_exists int
	declare @rc2 varchar(255)
	declare @cmd varchar(1000)
	declare @bkValue varchar(20)
	declare @dbRefKey int
	declare @isDetachForCopy int
	declare @xp_cmdshell_enabled int;

	set @ret_status = 0 -- 0 = success, 1 = non-unique mdf name (for rename only), 2 = some other error

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;

	set @dbNameIR = @dbName + '_IR'
 	select @dbPathPri = replace(@dbPathPri,'/','\')
 	select @dbPathIR = replace(@dbPathIR,'/','\')
 	select @dbLogPathPri = replace(@dbLogPathPri,'/','\')
 	select @dbLogPathIR = replace(@dbLogPathIR,'/','\')


	-- check for a rename
	if @longname != ''
	begin
		set @fileName = ltrim(rtrim(@dbPathPri)) + '\' + ltrim(rtrim(@longname)) + '.mdf'
		if (@xp_cmdshell_enabled = 1)
		begin
			set nocount on
			--exec xp_fileexist @fileName, @file_exists OUT
		  set @cmd = 'dir "' + @fileName + '"'
			exec @file_exists = xp_cmdshell @cmd, no_output
			-- file exists
			if @file_exists = 0
			begin
				set @ret_status = 1
				return @ret_status
			end

		end
		else
		begin
			set @file_exists = systemdb.dbo.clr_Util_FileExists(@fileName);
			if @file_exists = 1
			begin
				set @ret_status = 1
				return @ret_status
			end
		end

		-- file does not exist
  		begin try
			set @longnameIR = @longname + '_IR'
			exec absp_Util_RenameCurrencyDB @dbNameIR, @longnameIR, @dbPathIR, @dbLogPathIR
			set @dbNameIR = @longnameIR

			exec absp_Util_RenameCurrencyDB @dbName, @longname, @dbPathPri, @dbLogPathPri 
			-- fix up cfldrinfo for rename in case row not deleted (e.g. during a database copy)
			update commondb.dbo.cfldrinfo set db_name = @longname where db_name = @dbName
			set @dbName = @longname
  		end try
  		begin catch
			set @ret_status = 2
			set @rc = 'Error detaching and renaming ' + @dbName + ': ' + ERROR_MESSAGE()
  			return @ret_status
		end catch
	end

	select @dbRefKey=cf_ref_key from commondb.dbo.CFldrInfo where LongName =@dbName;

	if @forced = 1 -- a forced detach?
	begin
		set @sql = 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE '
		exec (@sql)

		set @sql = 'ALTER DATABASE [' + @dbNameIR + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE '
		exec (@sql)
	end

	select @bkValue=Bk_Value  from commondb..BkProp where Bk_Key='GrantPermissionToDB'
	
	-- Now detach the Database from SQL Server.
	-- do IR first. If there's an exception then primary won't be detached
	if exists ( select 1 from sys.databases where name = @dbNameIR )
	begin
		exec sp_detach_db @dbNameIR;
		
		if @bkValue='True' and  @xp_cmdshell_enabled = 1 --skip executing icacls.exe if xp_cmdshell is not enabled
		begin
			set @cmd = 'icacls "' + @dbPathIR    + '\*.*" /grant Everyone:F';
			exec xp_cmdshell @cmd, no_output;
			set @cmd = 'icacls "' + @dbLogPathIR + '\*.*" /grant Everyone:F';
			exec xp_cmdshell @cmd, no_output;
		end
	end

	begin try
		if exists ( select 1 from sys.databases where name = @dbName )
		begin
			exec sp_detach_db @dbName
			if @bkValue='True' and  @xp_cmdshell_enabled = 1 --skip executing icacls.exe if xp_cmdshell is not enabled
			begin
				set @cmd = 'icacls "' + @dbPathPri    + '\*.*" /grant Everyone:F';
				exec xp_cmdshell @cmd, no_output;
				set @cmd = 'icacls "' + @dbLogPathPri + '\*.*" /grant Everyone:F';
				exec xp_cmdshell @cmd, no_output;
			end
		end
	end try
	begin catch -- couldn't detach primary so re-attach IR
		set @rc = 'Error detaching ' + @dbName + ': ' + ERROR_MESSAGE()
		set @ret_status = 2
		exec absp_Util_AttachDatabase @rc2 output, @dbNameIR, @dbPathIR -- attach associated IR database
	end catch

	select @isDetachForCopy=1 from commondb..CFldrInfo where cf_ref_key = @dbRefKey;

	if (@ret_status = 0) and (@isDetachForCopy is null)
	begin
		exec commondb.dbo.absp_Util_CleanupBatchJob @dbName, @dbRefKey
	end

	return @ret_status
end
