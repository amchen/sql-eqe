if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanUpSessions') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanUpSessions
end
go

create  procedure absp_CleanUpSessions @cleanSessionW int = 1, @debug int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure will delete all those WCE sessions that are not associated 
with any job and all valid sequence plans that are marked completed or failed 
or cancelled. 

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @cleanSessionW  ^^ The flag specifying whether to chean SessionW table.
##PD  @debug  ^^ The flag for messaging purpose only.

*/
as
begin

	set nocount on;
   
	declare @sql varchar(max);
	declare @user2KeepInlist varchar(max);
	declare @batchJobKeyInlist varchar(max);
	declare @msgText varchar(255);
   
	execute absp_MessageEx '--Start absp_CleanUpInvalidSessions--'
   
	-- get the userInlist to keep in sessionW 
	if @cleanSessionW = 1 
	begin
		set @sql = 'select distinct BatchJob.SessionID from commondb..BatchJob BatchJob join commondb..SessionW SessionW on '+'BatchJob.SessionID = SessionW.User_Id union select 1 union select 2';
		print @sql
		execute   absp_Util_GenInList @user2KeepInlist output,@sql,'N';
   		select 'geninlist - 1st ' + @user2KeepInlist;
   		if @debug = 1
   		begin
      			set @msgText = '@user2KeepInlist = '+@user2KeepInlist
      			execute absp_MessageEx @msgText
   		end
	end  
  
  	-- get the batchJobKeyInlist to be removed from SEQPLOUT
	set @sql = 'select distinct BatchJob.BatchJobKey from commondb..BatchJob BatchJob
			inner join commondb..SeqPlOut SeqPlOut
			on BatchJob.BatchJobKey = SeqPlOut.BatchJobKey  
			and BatchJob.status in (''S'', ''F'', ''C'')'
			print @sql
   	execute  absp_Util_GenInList @batchJobKeyInlist output,@sql,'N'
   	select 'Geninlist - 2nd ' + @batchJobKeyInlist

	if @debug = 1
	begin
      		set @msgText = '@batchJobKeyInlist = '+@batchJobKeyInlist
		execute absp_MessageEx @msgText
	end
	
	--Clean SESSIONW
	if @cleanSessionW = 1 
	begin
		if len(@user2KeepInlist) > 0
		begin
			set @sql = 'delete SESSIONW where USER_ID not '+@user2KeepInlist
			print @sql
			execute(@sql)
		end
	end  

	--Clean  SEQPLOUT 
	if len(@batchJobKeyInlist) > 0
	begin
		set @sql = 'delete commondb..SeqPlOut where BatchJobKey '+@batchJobKeyInlist
		print @sql
		execute(@sql)      
	end
	execute absp_MessageEx '--End absp_CleanUpInvalidSessions--'
end