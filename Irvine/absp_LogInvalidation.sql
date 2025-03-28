if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_LogInvalidation') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_LogInvalidation
end
go
 
create procedure absp_LogInvalidation  	@eventId int,
 								 		@userName varchar(25),
								 		@nodeType int,
								 		@nodeKey  int,
								 		@port_id int, 
								 		@policy_key int, 
								 		@site_key int, 
								 		@eventMessage varchar(254)
									   
	
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console" > 
====================================================================================================

DB Version:    	MSSQL

Purpose:		This procedure logs an invalidation event by inserting a row in STAEVENT  for the node
				being invalidated for the given the nodeKey and nodeType. It also inserts a row
				for the parent portfolio if any, and, if applicable, a row for the parent accumulation 
				portfolio.
				
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
	declare @parentKey int
	declare @nodeName varchar(120)
	declare @extraKey1 int
	declare @extraKey2 int
	
	set @parentKey = 0	
	set @me = 'absp_LogInvalidation'
	
	execute absp_Util_Log_Info '-- Begin --',@me 
	set @start_dat = replace(replace(replace(convert(varchar,GetDate(),20),'-',''),':',''),' ','')
	
	if @eventId<> 20 
		return
	
	--Create a temporary table--
	create table #TMPTBL 
	(
	ID INT IDENTITY NOT NULL,
	NODE_NAME VARCHAR(120) COLLATE SQL_Latin1_General_CP1_CI_AS,
	NODE_TYPE INT,
	NODE_KEY INT,
	PORT_ID INT,
	POLICY_KEY INT,
	SITE_KEY INT
	)
	
		
	if @nodeType = 2 
	begin
		set @parentKey = 0
		select @nodeName = LONGNAME  from PPRTINFO where PPORT_KEY=@nodeKey
		
		insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY)
			values (@nodeName,@nodeType,@nodeKey,0,0,0)
		
		select @parentKey = APORT_KEY  from APORTMAP where CHILD_KEY= @nodeKey and CHILD_TYPE=@nodeType

		if @parentKey>0 
		begin
			--Get aport for the pport--
			set @nodeType=1
			set @nodeKey=@parentKey
		end  
	end  
	
	if @nodeType = 10 or  @nodeType = 30 
	begin
			set @parentKey = 0	
			select @parentKey = PROG_KEY,@nodeName = LONGNAME from CASEINFO where CASE_KEY= @nodeKey
			
			insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY)
			values (@nodeName,@nodeType,@nodeKey,0,0,0)
		
			if @parentKey>0 
			begin
				--Get program for the case--
				execute @nodeType= absp_Util_GetProgramType  @parentKey 
				set @nodeKey=@parentKey
			end  
	end  
	
	if @nodeType = 7 or  @nodeType = 27 
	begin
		set @parentKey = 0	
		select @nodeName = LONGNAME from PROGINFO where PROG_KEY=@nodeKey
	
		insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY)
			values (@nodeName,@nodeType,@nodeKey,0,0,0)
			
		select @parentKey = RPORT_KEY from RPORTMAP where CHILD_KEY= @nodeKey and CHILD_TYPE=@nodeType
		if @parentKey>0 
		begin
		    --Get rport for the program--
			execute @nodeType= absp_Util_GetRPortType  @parentKey 
			set @nodeKey=@parentKey
		end  
	end  
	
	if @nodeType = 3 or  @nodeType = 23 
	begin
		
		select @nodeName = LONGNAME from RPRTINFO where RPORT_KEY=@nodeKey
		insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY)
			values (@nodeName,@nodeType,@nodeKey,0,0,0)
			
		set @parentKey = 0
		select @parentKey = APORT_KEY from APORTMAP where CHILD_KEY= @nodeKey and CHILD_TYPE=@nodeType
		if @parentKey>0 
		begin
			--Get aport for the rport--
			set @nodeType=1
			set @nodeKey=@parentKey
		end  
	end  
	
	if @nodeType = 1 
	begin
		select @nodeName = LONGNAME  from APRTINFO where APORT_KEY=@nodeKey
		insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY)
			values (@nodeName,@nodeType,@nodeKey,0,0,0)
	end 
	
	--Insert all invalidated nodes in STAEVENT from the temporary table--
	insert into STAEVENT (STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA)
	  select @eventId, @start_dat,@start_dat,@userName,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,0,@eventMessage from #TMPTBL 
	  	order by #TMPTBL.ID desc
	
	execute absp_Util_Log_Info '-- End --',@me
end
