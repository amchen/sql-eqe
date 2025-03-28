if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BlobTempCreate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BlobTempCreate
end

go

create procedure absp_BlobTempCreate @baseTableName char(120),@aportKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a temporary table with the same structure as 
the given existing base table.

Returns:       Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @baseTableName     ^^ A string containing the base table name.
##PD  @aportKey          ^^ An integer value for the aportkey.
*/
as
begin
 
   set nocount on
   
  declare @baseName char(120)
   declare @tableName char(120)
   declare @tblPostfix varchar(255)
   set @baseName = rtrim(ltrim(@baseTableName))+'_'+rtrim(ltrim(str(@aportKey)))
  -- Special note: assume for a minute the server power dies at just such an inopportune 
  -- moment that we ended up with a dangling TN_APK combination such that when it started 
  -- up again and the analysis re-ran that we would get a tablename collision.  
  -- This routine right here can catch that case an should it happen it will call 
  -- absp_ BlobDiscard for you so that the previous never-completed temp table is removed on
  --  your behalf and you can proceed with a fresh copy.
   if exists(select 1 from sysobjects where name = @baseName and type = 'U')
   begin
      execute absp_BlobDiscard @baseTableName,@aportKey
   end
  -- now make new one
   set @tblPostfix = '_'+rtrim(ltrim(str(@aportKey)))
   execute absp_Util_MakeTmpTable @tableName out, @baseTableName,'',@tblPostfix,0,'',1
end



