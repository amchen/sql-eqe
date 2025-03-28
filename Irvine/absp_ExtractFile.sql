if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ExtractFile') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ExtractFile
end
 go

create procedure absp_ExtractFile @path char(256),@reportType char(3),@nodeType char(1),@name char(120),@progName char(120) = '',@useKey int =0
as

begin
 
   set nocount on
   declare @xp_cmdshell_enabled int;

   exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;
 /*
  This implements a Stored Procedure interface to call a GEIS Callable Blob Extractor
  See "Callable Blob Extract Utility Specification"

  */
   declare @installPath varchar(max)
   declare @sqlx varchar(255)
   declare @sql varchar(255)
   declare @retCode int
   print 'absp_ExtractFile(path '
   print @path
   print ', reportType '
   print @reportType
   print ', nodeType '
   print @nodeType
   print ', name '
   print @name
   print ', progName '
   print @progName
   print ', useKey '
   print @useKey
   print ');'
   set @retCode = -12
   execute absp_Util_GetWceInstallDir @installPath output, 0
   set @sql = ltrim(rtrim(@installPath))+'\'+'BlobExtract.exe '

   set @sql = @sql+' -directory '+'"'+@path+'"'+' -reportType '+@reportType+' -typeOfNode '+@nodeType+' -nameOfNode '+'"'+@name+'"'+' -progName '+'"'+@progName+'"'+' -keyOfNode '+rtrim(ltrim(str(@useKey)))

   print '@sql='
   print @sql
   if (@xp_cmdshell_enabled = 1)
	begin
		execute @retCode = xp_cmdshell @sql
	end
   print 'absp_ExtractFile @retCode='
   print @retCode
   return @retCode
end



