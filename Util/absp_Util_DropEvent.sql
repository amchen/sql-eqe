if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_Util_DropEvent') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DropEvent
end
 go
create procedure absp_Util_DropEvent @eventName varchar(max)

/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    ASA
Purpose:

	This procedure will drop any given event.

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @eventName ^^ The name of the event to be dropped.
*/

as
begin 

	set nocount on
	declare @sql varchar(max)
	if  exists (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'' + @eventName+ '')
	begin
		set @sql = 'msdb.dbo.sp_delete_job @job_name=N'''+@eventName+''''+', @delete_unused_schedule=1'
		exec (@sql)
	end
end