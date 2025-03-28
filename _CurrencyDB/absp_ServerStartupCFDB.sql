if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ServerStartupCFDB') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ServerStartupCFDB
end
go

create procedure absp_ServerStartupCFDB
	@startupLevel int,
	@groupId int,
	@logFileName char(255) = '',
	@blobValidateLevel int = 0,
	@cleanupFinalResults int = 1,
	@pofCleanupLevel int = 0,
	@userName varchar(100) = '', 
	@password varchar(100) = '' 
	
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
              This procedure is called to initialize the currency folder primary database during the server startup.
              This procedure does the following
              
              1. Enables all events 
              2. Drops all triggers
              3. Drops index from some tables.
              4. Validate blob records 

Returns:       Nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @startupLevel ^^ Unused parameter
##PD  @groupId ^^ DBTASKS group Id
##PD  @logFileName ^^  The log file name 
##PD  @blobValidateLevel ^^  The blob validate level
##PD  @cleanupFinalResults ^^  A flag to indicate whether to cleanup Final results 
##PD  @pofCleanupLevel ^^  A flag to indicate whether to cleanup orphan portfolios
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication
*/

begin
	set nocount on

	declare @invalidateOnMismatch bit
	declare @logMatches bit
	declare @saveLogTableAtEnd bit
		
     	execute absp_MessageEx '******* absp_ServerStartupCFDB started ***********'
     
	-- enable system events
	execute absp_Enable_All_System_Events 1
	
     
	-- see if we need to do absp_ServerMaintenanceBlobValidate
	if @blobValidateLevel > 0 
	begin
	set @invalidateOnMismatch=(@blobValidateLevel & 2)/2
	    set @logMatches =(@blobValidateLevel & 4)/4
	    set @saveLogTableAtEnd=(@blobValidateLevel & 8)/8
	    exec absp_ServerMaintenanceBlobValidate @logFileName,
						    @groupId,
						    @invalidateOnMismatch,
						    @logMatches,
						    @saveLogTableAtEnd,
						    @cleanupFinalResults,
						    @userName,
						    @password
	end

	-- see if we need to clean uo leftover (orphan) portfolio records
	if @pofCleanupLevel > 0
	begin
		print 'pof orphan cleanup requested'
		
	end
	
	-- Fixed Defect: SDG 12360
	-- Drop Index for some tables in Master Database
	-- debug flag set to 1 for verbose.
	-- if exists(select 1 from VERSION where DB_NAME = 'Master')
	-- begin
	-- 	execute absp_DropIndexFromDB 1
	-- end
	
	-- SDG__00015888: Need to set the CHASINFO STATUS from  "NEW" to "DELETED" during server startup
	if exists(select 1 from SYSCOLUMNS where object_name(id) = 'CHASINFO' and NAME = 'STATUS')
	begin
		update CHASINFO set STATUS = 'Deleted'  where STATUS = 'New'
	end

	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		drop synonym MigrateLookupID;

     
	execute absp_MessageEx '******* absp_ServerStartupCFDB ended ***********'
end