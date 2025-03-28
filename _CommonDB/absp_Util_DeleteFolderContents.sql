if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteFolderContents ') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteFolderContents
end

go
create procedure absp_Util_DeleteFolderContents  @folderName char(248) ,@force_it int = 1 
AS
/*
##BD_BEGIN <font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes the contents of a folder with the given name and returns 0 on success 
and 1 on failure.

Returns:       It returns 0 or 1.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @folderName ^^  The name of the file to be deleted.
##PD  @force_it ^^  A flag which indicates if empty folders or non-empty folders are to be deleted

##RD @rc ^^ Returns 0 or 1 
*/
begin

   set nocount on
   
  -- This procedure calls an external function contained in eqesyb.dll
  -- Returns 0 for success, non-zero for failure
  --
  -- The force_it param is not recognized by eqesyb.dll and will always be interpreted as 1, i.e, force delete.
   declare @rc int
   declare @newFolder char(248)
  -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
   
   execute absp_Util_Replace_Slash @newFolder output, @folderName
   set @rc = dbo.absxp_delete_folder_contents(@newFolder,@force_it)
   if(@rc <> 0)
   begin
      print 'absp_Util_DeleteFolderContents: '+@newFolder+', force_it: '+rtrim(ltrim(str(@force_it)))+', @rc: '+rtrim(ltrim(str(@rc)))
   end
   --set @SWP_Ret_Value = @rc
   return @rc
end

