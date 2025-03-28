if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetConnectionId') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetConnectionId
end

go

create  procedure 
absp_GetConnectionId @jobProcId char(255) 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
              This procedure returns the session id for a given application name

Returns:       Session Id on success else returns -1. .

====================================================================================================
</pre>
</font>
##BD_END

##PD  @jobProcId ^^ The application name of a connection
*/
begin

  set nocount on
  declare @retVal int;
  set @retVal = -1;
  select @retval = session_id from sys.dm_exec_sessions where program_name = @jobProcId;
  return @retVal;
end
  
  
  