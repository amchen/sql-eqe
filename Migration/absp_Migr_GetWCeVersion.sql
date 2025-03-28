if EXISTS(SELECT * FROM sysobjects where id = object_id(N'absp_Migr_GetWCeVersion') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_Migr_GetWCeVersion
end

GO
create procedure absp_Migr_GetWCeVersion @ret_VERSION CHAR(10) output, @theFinishDate CHAR(14) 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the VERSION from the RQEVersion table in an OUTPUT parameter based on the Finish date given as
input parameter .

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_VERSION   ^^  An OUTPUT parameter where the VERSION is returned
##PD  @theFinishDate    ^^  A date value based on which the VERSION will be returned.
*/
AS
begin

   set nocount on
   
   declare @version char(10)
   declare @versionCol char(20)
   declare @sql nvarchar(4000)
   declare @versionTbl varchar(130)
   declare @versionDtCol varchar(25)
   
   set @version=''
   if exists(select 1 from SYS.COLUMNS where object_name(object_id) = 'RQEVersion' and NAME = 'RQEVersion')
   begin
      set @versionCol='RQEVersion'
      set @versionTbl='RQEVersion'
      set @versionDtCol='VersionDate'
   end
   else
   begin
      set @versionCol='WCEVersion'
      set @versionTbl='Version'
      set @versionDtCol='UPDATED_ON'
   end
   set @sql='select  top (1) @version = '+ @versionCol+' from ' + @versionTbl +  ' where '+@versionDtCol+' < '''+@theFinishDate +''' order by ' + @versionDtCol + ' desc'
   execute sp_executesql @sql,N'@version char(10) output',@version output
   set @ret_VERSION = @version
end