if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_LoadTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_LoadTable
end

go
create procedure -------------------------------------------------------
absp_Migr_LoadTable @theTable char(120),@theFilePath char(255),@theDelimiter char(1) = ',',@modeFlag bit = 0,@debugFlag int = 1 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates a given table with data from a given file as specified 
in the FilePath parameter.


Returns:       nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  @theTable       ^^ Name of the file which is to be populated..
##PD  @theFilePath    ^^ The path of the data file which has the data.
##PD  @theDelimiter   ^^ The delimiter used to separate the data.
##PD  @modeFlag ^^ A flag value.
##PD  @debugFlag      ^^ A flag value used for displaying messages.

*/
as
begin
 
   set nocount on
   
 -- This proc bulk loads into theTable from theFilePath using theDelimiter
   declare @debug int
   declare @filepath char(255)
   declare @sql varchar(max)
   declare @wceInstall char(255)
   declare @wceDrive char(2)
   declare @msgText varchar(255)
   declare @errCode int
   set @debug = @debugFlag
   execute absp_Util_Replace_Slash @filepath output, @theFilePath
  -- get the WCe install drive/folder
   execute absp_Migr_GetWCeInstallDir @wceInstall output,@modeFlag
   if @debug > 0
   begin
      set @msgText = 'absp_Migr_LoadTable: @wceInstall = '+@wceInstall
      execute absp_MessageEx @msgText
   end
   set @wceDrive = left(@wceInstall,2)
   if @debug > 0
   begin
      set @msgText = 'absp_Migr_LoadTable: @wceDrive = '+@wceDrive
      execute absp_MessageEx @msgText
   end

  -- substitute the drive letter
   set @filepath = @wceDrive+right(ltrim(rtrim(@filepath)),LEN(@filepath) -2)
   --Defect SDG__00018799 - Call  absp_Util_LoadData to load table--
   exec absp_Util_LoadData @theTable,@filepath, @theDelimiter
   if @errCode<>0
   begin
	set @msgText = 'absp_Migr_LoadTable: '+ERROR_MESSAGE()
	exec absp_messageEx  @msgText 
	return
   end 
   
   if @debug > 0
   begin
      set @msgText = 'absp_Migr_LoadTable: '+@sql
      execute absp_MessageEx @msgText
   end
   
end





