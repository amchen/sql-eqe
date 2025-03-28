if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateFolder') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateFolder
end
go

create procedure absp_Util_CreateFolder @folderName char(248) 
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure creates a folder with the given name and returns zero on success and non-zero on failure.
     
     
    	    
Returns:       It returns 0 if the folder is successfully created else returns 1.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @folderName ^^  The name of the folder to be created.

##RD  ret_Status ^^ Returns 0 if the folder is successfully created else returns 1 
*/

begin

   set nocount on
   
   declare @ret_Status int
   declare @newFolder char(248)
   execute absp_Util_Replace_Slash @newFolder output, @folderName
   set @ret_Status = dbo.absxp_Create_Folder(@newFolder)
   if(@ret_Status <> 0)
   begin
      print 'absp_Util_CreateFolder: '+ @newFolder + ', @ret_Status: ' + rtrim(ltrim(str(@ret_Status)))
   end
   
   select @ret_Status
   return @ret_Status
end


