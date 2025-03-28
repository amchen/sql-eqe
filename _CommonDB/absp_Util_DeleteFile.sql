if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteFile') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteFile
end
 go
create  procedure absp_Util_DeleteFile @fileName char(248)
/*
##BD_BEGIN absp_Util_DeleteFile ^^ 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes a file with the given name and returns zero on success and non-zero on failure.

Returns:       It returns 0 if the file is deleted else 1.
====================================================================================================
</pre>
</font>
##BD_END


##PD  @fileName ^^  The name of the file to be deleted.
##RD  @rc ^^ Returns 0 if the file is successfully created else 1
*/
as
begin

   set nocount on
   
  -- This procedure calls an external function contained in eqesyb.dll
  -- Returns 0 for success, non-zero for failure
   declare @rc int
   declare @newFile char(248)
  -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
    
   execute absp_Util_Replace_Slash @newFile out, @fileName
	set @rc = dbo.absxp_delete_file(@newFile)
		if(@rc <> 0)
		begin
			print 'absp_Util_DeleteFile: '+@newFile+', @rc: '+rtrim(ltrim(str(@rc)))
		end
	return @rc
   end



