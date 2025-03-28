if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_GetFileSizeMB') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetFileSizeMB;
end
go
create procedure absp_Util_GetFileSizeMB @theFile char(1000)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:
This procedure calls an external function absxp_GetFileSize() which in turn returns the size of
the specified file (in MB) if the file is found else it returns an error code (-2) .
Returns:       The file size if the file is found else a negative error code.
====================================================================================================
</pre>
</font>
##BD_END

##PD  theFile ^^  The file name for which the filesize is to be found.
##RD  @rc ^^ The file size is returned if the file is found else an error code.
*/
AS
begin

   set nocount on;

   -- This procedure calls an external function contained in eqesyb.dll
   -- Returns 0 for success, non-zero for failure
   declare @rc int;
   declare @newFile varchar(1000);
   declare @msgText varchar(1200);

   -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
   execute absp_Util_Replace_Slash @newFile output, @theFile;
   set @newFile = dbo.trim(@newFile);
   set @rc = dbo.absxp_GetFileSize(@newFile);

   if(@rc = -1)
   begin
      set @msgText = 'absp_Util_GetFileSizeMB: '+@newFile+', does not exist!';
      execute absp_MessageEx @msgText;
   end
   else
   begin
      if(@rc = -2)
      begin
         set @msgText = 'absp_Util_GetFileSizeMB: '+@newFile+', Read Error!';
         execute absp_MessageEx @msgText;
      end
      else
      begin
         set @msgText = 'absp_Util_GetFileSizeMB: '+@newFile+' ('+rtrim(ltrim(str(@rc)))+' MB), Success';
         execute absp_MessageEx @msgText;
      end
   end

   --resultset required for Hibernate
   select @rc;
   return @rc;
end
