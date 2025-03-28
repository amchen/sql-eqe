if exists (select 1 from SYSOBJECTS where ID = object_id(N'absp_GetListofInvalidSessionID') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_GetListofInvalidSessionID
end
go

CREATE PROCEDURE absp_GetListofInvalidSessionID @list_of_session_id_from_locklist varchar(max)
   
/*
##BD_BEGIN
<font size="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: SQL2005
Purpose:	This procedure returns a resultset containing all the invalid session Ids(userID) from the list
			of given sessionIds.

Returns:    A list of invalid sessionIds.
====================================================================================================
</pre>
</font>
##BD_END

##RD	SessionId	^^ Session Id
*/
as

begin
    set nocount on
    
    declare @sql varchar(max)
	declare @sessionID int
	declare @InvalidSessionTbl table (SessionID int)
    
    --If LOGOFF_DAT is not set then locks associated with that SessionID are valid. We eliminate them--
	set @sql = 'select USER_ID from SESSIONW where USER_ID in ('+@list_of_session_id_from_locklist+') and not (LOGOFF_DAT is null or LOGOFF_DAT='''')'
	execute('declare c1 cursor forward_only global  for '+@sql) 
	
 	open c1
	fetch c1 into @sessionID	
	while @@FETCH_STATUS=0
	begin	
		--Invalid session if we have no TaskInfo record for the session or we have failed rows--
		if (not exists(select 1 from TaskInfo where SessionID=@sessionID and Status != 'F'))
			 insert into @InvalidSessionTbl (SessionID ) values(@sessionID) 

		fetch c1 into @sessionID	
	end
	close c1
	deallocate c1
	
	--Return resultset having invalid SessionIds--
	select SessionID from @InvalidSessionTbl order by SessionID
end
 
 