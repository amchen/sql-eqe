if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsValidFolder') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsValidFolder
end
go

create procedure ----------------------------------------------------
absp_Util_IsValidFolder @theFolder char(248) = '' 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a value which signifies whether the specified folder is present or not.

Returns: 0 if the folder is present,
         -1 if the parameter doesn't have proper path string 
         -2 if the folder is not present.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @theFolder ^^  Takes the full path of a folder.

##RD  @rc ^^ It is an OUTPUT parameter which will contain 0 if the folder is present, -1 if the parameter 
             doesn't have proper path string and -2 if the folder is not present.



*/
as
begin

   set nocount on
   
  --  This procedure will check if the folder is valid.
  --  Returns 0 on success, non-zero for failure.
   declare @retVal int;
   declare @folder char(248);
   declare @status int;
   declare @tmpFolder char(248);
   declare @cmd varchar(4000);
   declare @xp_cmdshell_enabled int;;
   
   set @status = 0
   set @retVal = 0
   -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
   execute absp_Util_Replace_Slash @folder output,@theFolder
  -- append test folder
   if(select charindex('/',@folder)) > 0
   begin
      set @folder = ltrim(rtrim(@folder)) + '/__test__'
   end
   else
   begin
      print 'Error: absp_Util_IsValidFolder - Invalid name ['+@folder+'] - '
      print GetDate()
      set @retVal = -1
   end
   
   if(@retVal = 0)
   begin
		set @tmpFolder = replace(@theFolder,'/','\')
		set @tmpFolder = replace(@tmpFolder,'\n','/n')
	   
		exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell ;
		if (@xp_cmdshell_enabled = 1)
		begin
			set @cmd = 'dir "' + dbo.trim(@tmpFolder) + '"'
			exec @status = xp_cmdshell @cmd, no_output
		

		end
		else
		begin
			set @status= systemdb.dbo.clr_Util_FolderExists(@tmpFolder);
		end

		if (@status <> 0)
		begin
			set @retVal = -2
		end
   end
   
   if(@retVal = 0)
   begin
    -- Check if folder has write permission
      set @status = 0
      execute @status = absp_Util_CreateFolder @folder
      if(@status <> 0)
      begin
         print 'Error: absp_Util_IsValidFolder - Cannot write to ['+@folder+'] - '
         print GetDate()
         set @retVal = -2
      end
      else
      begin
         execute absp_Util_DeleteFolder @folder
      end
   end
   
   --resultset required in hibernet
   select @retVal;
   return @retVal
end





