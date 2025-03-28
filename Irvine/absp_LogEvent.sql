if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_LogEvent') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_LogEvent
end
go
 
create procedure absp_LogEvent   @eventId int,
 								 @userName varchar(25),
								 @nodeType int,
								 @nodeKey  int,
								 @port_id int, 
								 @policy_key int, 
								 @site_key int, 
								 @rbat_key int,
								 @eventMessage varchar(254)
								 
	
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================

DB Version:    	MSSQL

Purpose:		This procedure logs an event by inserting a row into STAEVENT getting values from 
				the input parameters.
						          
Returns:        Nothing
	                        
====================================================================================================
	
</pre>
</font>
##BD_END

##PD  @eventId ^^ The event ID
##PD  @userName ^^ The name of the user that caused the event
##PD  @nodeType ^^  The type for the treeview node
##PD  @nodeKey ^^  The key for the treeview node
##PD  @port_id ^^  The portfolio id if applicable
##PD  @policy_key ^^  The policy key if applicable
##PD  @site_key ^^  The site key if applicable
##PD  @eventMessage ^^  The event details data. 

*/
as
begin
set nocount on
	declare @me varchar(1000)
	declare @start_dat char(14)
	declare @nodeName char(120)
	declare @extraKey1 int
	declare @extraKey2 int
	
	set @me = 'absp_LogEvent'
	execute absp_Util_Log_Info '-- Begin --',@me 
	set @extraKey1=0
	set @extraKey2=0
		
	set @start_dat = replace(replace(replace(convert(varchar,GetDate(),20),'-',''),':',''),' ','')
	
	--Get the nodeName--
	if @nodeType=8 
	begin
		set @nodeKey=@policy_key 
		set @extraKey1=@port_id 
	end
	else if @nodeType=9 
	begin
		set @nodeKey=@site_key 
		set @extraKey1=@policy_key 
		set @extraKey2=@port_id 
	end 
	
	execute absp_Util_GetNodeNameByKey  @nodeName out,@nodeKey,@nodeType,@extraKey1,@extraKey2 
	
	--In case of policy & site nodeKey is empty--
	if @nodeType=8  
		set @nodeKey=0 
	else if @nodeType=9 
		set @nodeKey=0
	
	
	insert into STAEVENT (STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA)
		values (@eventId,@start_dat,@start_dat,@userName, @nodeName, @nodeType,@nodeKey,@port_id,@policy_key,@site_key,@rbat_Key, @eventMessage )

	execute absp_Util_Log_Info '-- End --',@me 
end