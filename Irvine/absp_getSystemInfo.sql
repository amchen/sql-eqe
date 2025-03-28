if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getSystemInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getSystemInfo
end

go

create procedure absp_getSystemInfo AS
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts records in USRNOTES containing information about the system
and returns a single resultset to display it. 

Returns: Returns a single resultset displaying the system information.
=================================================================================
</pre>
</font>
##BD_END

##RS NOTES ^^ The system information

*/
begin

   set nocount on
   
   declare @inputBlob varchar(MAX)
   declare @line varchar(MAX)
   declare @linePos int
   declare @lineCnt int
   declare @i int
   declare @j int
   declare @crlf char(2)
   declare @dt varchar(25);
   declare @xp_cmdshell_enabled int;

   exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;
   set @crlf = char(10) + char(13)
  -- do whatever DOS commands you want and direct into  a temp file
  -- date + time
  	if (@xp_cmdshell_enabled = 1)
	begin
		execute master..xp_cmdshell 'date /t  >c:\__$setinfo.txt'
		execute master..xp_cmdshell 'time /t  >>c:\__$setinfo.txt'
		-- environment settings
		execute master..xp_cmdshell 'set  >>c:\__$setinfo.txt'
		-- this gives you how much disk space is avaliable on c
		execute master..xp_cmdshell 'dir c:\__$setinfo.txt  >>c:\__$setinfo.txt'
		-- this gives you how much disk space is avaliable on d (it may or may not exist)
		execute master..xp_cmdshell 'dir d:  >>c:\__$setinfo.txt'
		-- now read it back
		execute  absp_Util_ReadFile  @inputBlob out, 'c:\__$setinfo.txt' 
		--message ' in absp_getSystemInfo, len(@inputBlob) = '+str ( length ( @inputBlob ) );
		-- delete it
		execute master..xp_cmdshell 'del c:\__$setinfo.txt'
	end
	else
	begin
		set @dt=getdate();
		exec systemdb.dbo.clr_Util_WriteLine 'c:\__$setinfo.txt', @dt,0
		exec systemdb.dbo.clr_Util_FileRead 'c:\__$setinfo.txt',  @inputBlob out
		exec systemdb.dbo.clrFileDelete 'c:\__$setinfo.txt'
	end
   set @linePos = 1
   set @lineCnt = 1
  -- blow out the last results
   delete from USRNOTES where NOTE_TYPE = -99
  -- parse the file into a series of lines and put each line in usrnotes
   while @linePos < len(@inputBlob)
   begin
      set @j = charindex(@crlf,@inputBlob,@linePos)
      set @line = substring(@inputBlob,@linePos,@j -@linePos)
      set @linePos = @j+2
    --message '*******' + @line;
      insert into USRNOTES(NOTE_KEY,NOTE_TYPE,NOTES) values(@lineCnt,-99,CAST(@line AS varchar(max)))
      set @j = charindex(@crlf,@inputBlob,@linePos)
      set @lineCnt = @lineCnt+1
   end
  -- return the answer

   select   NOTES as SYSINFO from USRNOTES where NOTE_TYPE = -99 order by NOTE_KEY asc

   return
end




