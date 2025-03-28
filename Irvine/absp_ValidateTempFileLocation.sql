if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ValidateTempFileLocation') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ValidateTempFileLocation
end

go

create procedure absp_ValidateTempFileLocation @ret_ASTMP varchar(255) output
as
/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL
Purpose: 

This procedure returns the temporary file location by checking the file envSetting.txt
and finding out the value of the ASTMP variable in an OUTPUT parameter. 

Returns:       Nothing
=================================================================================
</pre> 
</font> 
##BD_END 


##PD @ret_ASTMP ^^ The value of ASTMP variable as in envSetting.txt

*/
begin

   set nocount on
   
   declare @fileName char(100)
   declare @dbFileDrive char(1)
   declare @tempFileDrive varchar(255)
   declare @envSettings varchar(255)
   declare @line varchar(255)
   declare @ASTMPIndx int
   declare @indxEqual int
   declare @linePos int
   declare @lineCnt int
   declare @j int
   declare @crlf char(2)
   declare @SWV_exec nvarchar(4000)
   
   set @crlf = char(10)+char(13)
   
   set @fileName = 'c:/envSetting.txt'
   set @ASTMPIndx = 0
   set @indxEqual = 0
   set @lineCnt = 1
   set @linePos = 0
  -- First dump all the environment setting
  --  message'call xp_cmdShell ('' set > '+@fileName+''')' type info to client;
   set @SWV_exec = 'exec xp_cmdShell '' set > '+@fileName+''''
   execute (@SWV_exec)
   
   execute absp_Util_ReadFile @envSettings output, @fileName

  --  message @envSettings;
  -- Now parse the file line by line until ASTMP variable is found
   while @linePos < len(@envSettings)
   begin
      set @j = charindex(@crlf,@envSettings,@linePos)
      set @line = substring(@envSettings,@linePos,@j -@linePos)
      set @linePos = @j+2
 
      select  @ASTMPIndx = charindex('ASTMP',@line) 
      if(@ASTMPIndx > 0)
      begin
         select  @indxEqual = charindex('=',@line,@ASTMPIndx) 
         select  @tempFileDrive = substring(@line,@indxEqual+1,len(@line) -@indxEqual+1) 
         print 'ASTMP = '+@tempFileDrive 
         set @ret_ASTMP = @tempFileDrive
         return
      end
      set @j = charindex(@crlf,@envSettings,@linePos)
      set @lineCnt = @lineCnt+1
   end
   set @ret_ASTMP = NULL
   
end




