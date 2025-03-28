if exists (select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_LogIt') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_LogIt;
end
go

create procedure absp_Migr_LogIt
	@log_msg varchar(max)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure writes the migration log message to MigrationLog table.
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END
##PD  @log_msg ^^ The log message. The log message will be formatted to display the timestamp
*/

begin
	set nocount on;

	declare @formatted_log_message varchar(2000);
	declare @createDt varchar(25);

	-- Get current timestamp
	exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]';

	-- Format the message
	set @formatted_log_message = @createDt + '  ' + left(@log_msg, 1975);

	-- Log the message
	if exists (select 1 from SYS.TABLES where NAME = 'MigrationLog')
	begin
		insert MigrationLog (MigrationLogText) values (@formatted_log_message);
	end
end
