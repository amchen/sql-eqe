if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_AddTaskProgress') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AddTaskProgress
end
go

create procedure absp_Util_AddTaskProgress
	@taskKey int,
	@message varchar(max),
	@procID int = -1
	
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2008
Purpose:

This procedure will add a new record to TaskProgress table for a given task

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @taskKey		 ^^	The task key for which to add the record
##PD  @message  ^^ The message string.
*/
as
begin	
	declare @currDateTime char(14);
	declare @procName varchar(100);
	declare @msg varchar(max);
	
	
	set @procName = '';
	
	if (@procID <> -1)
	begin
		set @procName = OBJECT_NAME(@ProcID);
		set @msg = '[' + @procName + '] ' + @message;
	end	
	else
		set @msg = @message;
	
	-- check if the task key is valid. 
	
	if exists (select 1 from TaskInfo where TaskKey = @taskKey)
	begin
		exec absp_Util_GetDateString @currDateTime output;
		insert into TaskProgress values (@taskKey, @currDateTime, @msg);
	end
	
	
end
