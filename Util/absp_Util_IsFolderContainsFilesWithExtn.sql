if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsFolderContainsFilesWithExtn') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsFolderContainsFilesWithExtn
end

go

create procedure absp_Util_IsFolderContainsFilesWithExtn @folderPath varchar(2000), @extn varchar(10)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure checks if the given folder is empty or not.

Returns:       1 if empty else 0.

====================================================================================================
</pre>
</font>
##BD_END

##PD  folderPath ^^  The Folder path which is to be checked.

##RD  @rc ^^ returns 1 if the folder is empty else 0.


*/
begin

   set nocount on
   declare @isEmpty int
   set @isEmpty = 0

   execute absp_Util_Replace_Slash @folderPath output, @folderPath
   
   execute @isEmpty = absxp_CheckIfFolderContainsFilesWthExtn @folderPath, @extn 
   
   
   return @isEmpty
end
