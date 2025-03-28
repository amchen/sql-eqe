if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteFolder') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteFolder
end
go

create procedure absp_Util_DeleteFolder @folderName char(248) ,@force_It int = 1 
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure deletes a folder with the given name and returns zero on success and non-zero on failure.
        	    
Returns:       It returns 0 if the folder is deleted else 1.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @folderName 	^^  The name of the folder to be deleted.
##PD  @force_it 	^^  A flag which indicates if empty folders or non-empty folders are to be deleted

##RD @rc ^^ Returns 0 if the folder is successfully deleted else 1 
*/
begin

   set nocount on
   
   declare @rc int
   declare @newFolder char(248)
   execute absp_Util_Replace_Slash @newFolder out, @folderName
   set @rc = dbo.absxp_Delete_Folder(@newFolder,@force_It)
   if(@rc <> 0)
   begin
      print 'absp_Util_DeleteFolder: '+@newFolder+', force_it: '+rtrim(ltrim(str(@force_it)))+', @rc: '+rtrim(ltrim(str(@rc)))
   end
   return @rc
end






