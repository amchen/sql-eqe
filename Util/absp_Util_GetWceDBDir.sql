if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetWceDBDir') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetWceDBDir
end

go
create procedure ----------------------------------------------------------
absp_Util_GetWceDBDir @ret_WceDBDir char(255) output 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the WCEDB installed directory in an OUTPUT parameter.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD @ret_WceDBDir ^^ An OUTPUT parameter where the WCEDB install directory is returned.
*/
AS
begin

   set nocount on
   
   -- where main DB is actually running
   declare @i int
   declare @wceDbDir varchar(255)
   declare @slash char(2)
  
  -- This function returns the WCEDB install directory.
   select @wceDbDir = physical_name from sys.database_files where physical_name like '%mdf%'
   set @wceDbDir = rtrim(ltrim(@wceDbDir))
   if len(@wceDbDir) < 5
   begin
    --return '-3 cannot proceed without database directory ';
      set @ret_WceDBDir = '-3 cannot proceed without database directory '
      return
   end
  -- we need to find the last trailing slash
   set @i = charindex('\',@wceDbDir)
   if @i = 0
   begin
    --return '-4 cannot proceed without a real folder ';
      set @ret_WceDBDir = '-4 cannot proceed without a real folder '
      return
   end
  -- keep looking for last slash
   while charindex('\',@wceDbDir,@i+1) > 0
   begin
      set @i = charindex('\',@wceDbDir,@i+1)
   end
  -- all we want is the path part
   set @wceDbDir = left(@wceDbDir,@i)
  -- SDG__00013423, handle UNC paths
   set @slash = left(@wceDbDir,1)
   if(@slash = '\')
   begin
      set @wceDbDir = replace(@wceDbDir,'\','/')
   end
  -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
   execute absp_Util_Replace_Slash @wceDbDir output, @wceDbDir
   set @wceDbDir = upper(rtrim(ltrim(@wceDbDir)))
   set @ret_WceDBDir = @wceDbDir
end



