if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ServerStartup') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ServerStartup
end
go

create procedure absp_ServerStartup
	@startupLevel int,
	@groupId int,
	@logFileName char(255) = '',
	@blobValidateLevel int = 0,
	@cleanupFinalResults int = 1,
	@pofCleanupLevel int = 0,
	@resultsOdbcName varchar(255) = '',
	@userName varchar(100) = '',
	@password varchar(100) = '',
	@unloadPath varchar(255) = ''
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
              This procedure is called to initialize the master database during the Master database startup.

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
##PD  @resultsOdbcName ^^  The data source of ResultsDB
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication
*/


begin
     set nocount on

     declare @fldr varchar(500)
     declare @dbName varchar(100)
     declare @sql varchar(max)
     declare @sSql varchar(max)
     declare @msgText varchar(255)
     declare @invalidateOnMismatch bit
     declare @logMatches bit
     declare @saveLogTableAtEnd bit
     declare @iResult int
     declare @retVal int
     declare @createDt char(25)
     declare @fName varchar(255)
     declare @errCOde int
     declare @mode int

     execute absp_MessageEx '******* absp_ServerStartup started ***********'

     -- Cleanup migration record
     if exists(select 1 from SYS.TABLES where NAME = 'BKPROP')
     begin
        delete from BKPROP where BK_KEY = 'Migration'
        --commit work
     end
     -- enable system events
     execute absp_Enable_All_System_Events 1


     -- this little kludge fixes an EDM problem whereby default table data ends up with trailing blanks.
     -- because of a problem, we need to trim trailing spaces off of the ADMIN user name
     update USERINFO set USER_NAME = rtrim(ltrim(USER_NAME)) -- just trim them all  WHERE USER_NAME like 'ADMIN--';
     -- do this before any server maintenance procs

     -- SDG__00009898: add the database driver
     -- message 'resultsOdbcName = ' + resultsOdbcName;
     --=================================================
     -- make a server to refer to
     -- note the sys.: there is a  as well so be careful
     -- in case the name changed drop it first

     exec @mode=absp_Util_IsSingleDB
   	 if @mode=1
     begin
     	if (select count(*) from SYS.SYSSERVERS where srvname = 'resultdb') = 1 and @resultsOdbcName <> ''
     	begin
        	exec sp_dropserver 'resultdb'
     	end

     	-- create it
     	if (select count(*) from SYS.SYSSERVERS where srvname = 'resultdb') = 0 and @resultsOdbcName <> ''
     	begin
  			exec  @iResult = absp_Util_CreateLinkedServer 'resultdb', @resultsOdbcName, 'EQERESULTS'
        	if @iResult = 0
  	  		begin
  		   		print 'Successfully connected to resultdb'
  	  		end
  	  		else
  	  		begin
  		   		print 'Failed to connect to resultdb'
  	  		end
        	exec sp_serveroption resultdb,'rpc','on'
  	  		exec sp_serveroption resultdb,'rpc out','on'
     	end
   	end
     --=================================================


     -- see if we need to do absp_ServerMaintenanceBlobValidate
     if @blobValidateLevel > 0
     begin
        set @invalidateOnMismatch=(@blobValidateLevel & 2)/2;
  	    set @logMatches =(@blobValidateLevel & 4)/4;
  	    set @saveLogTableAtEnd=(@blobValidateLevel & 8)/8;
/*
  	    exec absp_ServerMaintenanceBlobValidate @logFileName,
  	                                            @groupId,
  	                                            @invalidateOnMismatch,
  	                                            @logMatches,
  	                                            @saveLogTableAtEnd,
  	                                            @cleanupFinalResults,
  	                                            @userName,
  	                                            @password
*/
     end

     -- see if we need to clean uo leftover (orphan) portfolio records
     if @pofCleanupLevel > 0
     begin
        print 'pof orphan cleanup requested'
		--exec absp_ServerMaintenancePortIdOrphans
     end

     -- Fixed Defect: SDG 12360
     -- Drop Index for some tables in Master Database
     -- debug flag set to 1 for verbose.
     -- if exists(select 1 from VERSION where DB_NAME = 'Master')
     -- begin
     --   execute absp_DropIndexFromDB 1
     -- end

     -- SDG__00015888: Need to set the CHASINFO STATUS from  "NEW" to "DELETED" during server startup
     if exists(select 1 from SYSCOLUMNS where object_name(id) = 'CHASINFO' and NAME = 'STATUS')
     begin
        update CHASINFO set STATUS = 'Deleted'  where STATUS = 'New'
     end

	 if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		drop synonym MigrateLookupID;

     execute absp_MessageEx '******* absp_ServerStartup ended ***********'
end
