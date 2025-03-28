if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ServerMaintenanceBlobValidate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerMaintenanceBlobValidate
end

go
create procedure absp_ServerMaintenanceBlobValidate @logFileName char(255),
                                                    @groupId int,
                                                    @invalidateOnMismatch bit = 0,
                                                    @logMatches bit = 0,
                                                    @saveLogTableAtEnd bit = 0,
                                                    @optionFlag int = 1,
													@userName	varchar(100) = '',
								  					@password	varchar(100) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure
- invokes absp_ServerMaintenancePrep() to create and populate the server
maintenance tables
- invokes absp_ServerMaintenanceBlobValidateTable() to insert records into
SVRMTLOG based on the matched/unmatched blob data in master and
results.
- The rows of SVRMTLOG are finally saved in a flat file based on the flag
saveLogTableAtEnd.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @logFileName ^^  Name of the log file
##PD  @groupId ^^  The DBTASK group ID.
##PD  @invalidateOnMismatch ^^  A Flag to indicate if results are to be invalidated if there is a mismatch of master & resukts data.
##PD  @logMatches ^^  A flag to indicate that even matches are to be logged
##PD  @saveLogTableAtEnd ^^  A flag to indicate if the SVRMTLOG rows are to be saved to a flat file
##PD  @optionFlag ^^  A flag to indicate if results are to be removed during invalidation
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication
*/
AS


begin
  /*
  this will evaluate master/result blob counts and then attempt to synchronize them
  */
   set nocount on;
   declare @maintKey int;
   declare @path char(255);
   declare @lp1_TblNm char(10);
   declare @lp1_KeyNm char(10);
   declare @sql varchar(1000);
   declare @dbName varchar(30);
   declare @hostName varchar(30);
   declare @errCode int;
   declare @fileName varchar(255);
   declare @msgText varchar(255);

   return;

  --=================================================
  -- OK, here we go
   print GetDate()
   print ' inside absp_ServerMaintenanceBlobValidate '
   execute @maintKey = absp_ServerMaintenancePrep 1,'absp_ServerStartBlobValidate',@logFileName
  --=================================================

  -- for each table ...
  -- get the count by key from master
   declare lp1  cursor fast_forward  for
          select distinct TABLENAME as TN,KEYNAME as KN from DELCTRL where BLOB_DB = 'R' order by TABLENAME asc
   open lp1
   fetch next from lp1 into @lp1_TblNm,@lp1_KeyNm
   while @@fetch_status = 0
   begin
      execute absp_ServerMaintenanceBlobValidateTable @lp1_TblNm,@lp1_KeyNm,@maintKey,@groupId,@invalidateOnMismatch,@logMatches,@optionFlag
      fetch next from lp1 into @lp1_TblNm,@lp1_KeyNm
   end
   close lp1
   deallocate lp1

  --=================================================
   if @saveLogTableAtEnd = 1
   begin
      execute absp_Util_GetWceInstallDir @path output
      if len(@path) > 0
      begin
		-- get database name
		set @dbName = db_name()
		select @hostName = @@servername

		set @sql = 'select * from ' + @dbName + '.dbo.' + 'SVRMTLOG where MAINT_KEY = ' + rtrim(ltrim(str(@maintKey)))
		set @fileName= ltrim(rtrim(@path)) + '\_SVRMTLG_.LOG';
		--Defect SDG__00018799 - Call  absp_Util_unLoadData to unload table--
		exec @errCode =  absp_Util_unLoadData 'Q',@sql,@fileName,'|', @userName=@userName,@password=@password
		if @errCode <> 0
		begin
			set @msgText='absp_ServerMaintenanceBlobValidate: '+ERROR_MESSAGE()
			exec absp_messageEx @msgText
			return
		end
      end
   end
   execute absp_ServerMaintenancePrep 1,'absp_ServerStartBlobValidate',@logFileName,@maintKey
end
