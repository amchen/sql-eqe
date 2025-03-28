if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_DetectAttachedWCEDatabases') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DetectAttachedWCEDatabases
end
go

create procedure absp_Util_DetectAttachedWCEDatabases 	@groupKey int = 1,
							@userKey int = 0,
							@allowServerBatchCleanup int,
							@logFileName char(255),
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

     This procedure will check for new currency folder databases that are already attached but having
     no entry in CFLDRINFO. Records will be inserted in CFLDRINFO for these databases.


Returns: A resultset containing the database name and status of the attached wce databases.
====================================================================================================
</pre>
</font>
##PD  @appVersion ^^ The application version
##BD_END
*/
as
begin

set nocount on

-- this is a no op with new external mount stored procedure

end
