if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_ReadFile') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ReadFile;
end
go

create procedure absp_Util_ReadFile @str varchar(MAX) output, @filename char(255)
as

/*
====================================================================================================
Purpose:

This procedure reads the given file and returns the contents in an OUTPUT parameter.

In ASA we use the system procedure XP_READ_FILE to read a file.
In SQL Server 2005 there is no equivalent system call so this procedure should be used
to read a file.

Returns:       Nothing
====================================================================================================

@filename ^^  The file which is to be read
@str ^^  An OUTPUT parameter which gets the string that is read from the file
*/

begin
	set nocount on;

	declare @ExecCmd varchar(255);
	declare @line varchar(MAX);
	declare @search varchar(255);
	declare @sql nvarchar(MAX);
	declare @binaryData varbinary(MAX);
	declare @xp_cmdshell_enabled int;
	declare @file_exists int;

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;
	if (@xp_cmdshell_enabled = 1)
	begin
		declare @TEMPFILE table(PK int NOT NULL IDENTITY(1,1), THISLINE varchar(MAX));
		set @ExecCmd = 'type "' + @FileName + '"';
		set @Search = 'The system cannot find ';
		insert into @tempfile exec xp_cmdshell @ExecCmd;
		select * from @tempfile;
		select @line =  isnull(THISLINE,'') from @TEMPFILE where PK = 1;

		if charindex(@search,@line)<>0
		begin
			set @str = NULL;
			raiserror ('Invalid File',10,1);
			return;
		end
		SET @sql = 'select @binaryData =(select * from openrowset (
           bulk ''' + @FileName + '''
           , SINGLE_BLOB ) x
           )';

		EXEC sp_executesql @sql
                 , N'@binaryData varbinary(max) output'
                 , @binaryData OUTPUT;

		set @str = @binaryData;
	end
	else
	begin
		 
		if (systemdb.dbo.clr_Util_FileExists (@FileName)=1)
		begin
			exec systemdb.dbo.clr_Util_FileRead @FileName,  @str out;
		end
		else
		begin
			--File does not exists--
			set @str = NULL;
			raiserror ('Invalid File',10,1);
			return;
		end
	end

end
