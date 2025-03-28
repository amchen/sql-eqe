if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDisabledRequiredEvents') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDisabledRequiredEvents
end
go

create procedure absp_Util_GetDisabledRequiredEvents
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQL2005

Purpose:	This procedure checks for all required events that are currently disabled.

Returns:        ResultSet containing the names of all required events that are currently disabled.
====================================================================================================
</pre>
</font>
##BD_END

##RS  NAME  ^^  names of all required events that are currently disabled.
*/
as
begin


-- we no longer have SQL Agent Jobs, just return
return


   set nocount on

   select name from msdb.dbo.sysjobs where name like 'absev%' and enabled <> 1;

end
go
