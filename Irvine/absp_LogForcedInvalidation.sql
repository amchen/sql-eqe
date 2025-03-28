if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_LogForcedInvalidation') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_LogForcedInvalidation
end
go
 
create procedure absp_LogForcedInvalidation (@eventId int,
 								 			@userName varchar(25),
								 			@nodeType int,
								 			@nodeKey  int,
								 			@port_id int, 
								 			@policy_key int, 
								 			@site_key int, 
								 			@eventMessage varchar(254)
									   		)
	
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console" > 
====================================================================================================

DB Version:    	MSSQL

Purpose:		This procedure logs a forced invalidation event by inserting a row in STAEVENT  for 
				the given node The child nodes except for policies and sites are logged. The Port IDs 
				will be logged to facilitate drilling down a Pport.
				
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
	declare @hasChild int
	
	set @parentKey = 0	
	set @me = 'absp_LogForcedInvalidation'
	
	execute absp_Util_Log_Info '-- Begin --',@me 
	set @start_dat = replace(replace(replace(convert(varchar,GetDate(),20),'-',''),':',''),' ','')
	
	--Create temporary table--
	create table #TMPTBL 
		(
			ID INT IDENTITY NOT NULL,
			NODE_NAME VARCHAR(120) COLLATE SQL_Latin1_General_CP1_CI_AS,
			NODE_TYPE INT,
			NODE_KEY INT,
			PORT_ID INT,
	)
	
	set @parentKey = 0	
		
		if @nodeType = 1 
		begin
			set @hasChild = 0
			select @nodeName  = LONGNAME  from APRTINFO where APORT_KEY=@nodeKey
			insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
			   values (@nodeName, @nodeType,@nodeKey,0 )
			   
			--Get the child nodes--
			set @hasChild = 1 
			set @parentKey=@nodeKey
		end 
	
		if @nodeType = 2 or @hasChild = 1  
		begin
			if @parentKey>0 
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					select LONGNAME, 2,PPORT_KEY,0 from PPRTINFO inner join APORTMAP
					  on PPRTINFO.PPORT_KEY = APORTMAP.CHILD_KEY 
					  and APORTMAP.CHILD_TYPE=2 and APORTMAP.APORT_KEY=@parentKey
					  order by PPRTINFO.PPORT_KEY
			else
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					   select LONGNAME ,@nodeType,@nodeKey,0 from PPRTINFO where PPORT_KEY=@nodeKey
			

		end 
			
		if @nodeType = 3 or  @nodeType = 23 or @hasChild = 1 
		begin
			set @hasChild = 0
			if @parentKey>0 
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					select LONGNAME, APORTMAP.CHILD_TYPE,RPORT_KEY,0 from RPRTINFO 
						inner join APORTMAP	on RPRTINFO.RPORT_KEY = APORTMAP.CHILD_KEY 
						and APORTMAP.CHILD_TYPE in (3,23) and APORTMAP.APORT_KEY=@parentKey
					 order by  RPRTINFO.RPORT_KEY
			else
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					select LONGNAME ,@nodeType,@nodeKey,0 from RPRTINFO where RPORT_KEY=@nodeKey
			
			--Get child programs for the rport--
			set @hasChild = 1
		end 
		
		if @nodeType = 7 or  @nodeType = 27 or 	@hasChild = 1 
		begin
			if @hasChild =1 
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					select PROGINFO.LONGNAME, case when #TMPTBL.NODE_TYPE =3 then 7 else 27 end, NODE_KEY,0 
						from #TMPTBL 
						inner join RPORTMAP	on  #TMPTBL.NODE_KEY = RPORTMAP.CHILD_KEY 
						inner join PROGINFO on PROGINFO.PROG_KEY=RPORTMAP.CHILD_KEY
						and RPORTMAP.CHILD_TYPE in (7,27)
						and #TMPTBL.NODE_TYPE in(3,23)
					order by  PROGINFO.PROG_KEY
			else			
				insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
					select LONGNAME ,@nodeType,@nodeKey,0 from PROGINFO where PROG_KEY=@nodeKey
					
			--Get child cases--
			--We cannot perform forced invalidation of a case--
			insert into #TMPTBL (NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID)
				select CASEINFO.LONGNAME,case when #TMPTBL.NODE_TYPE =7 then 10 else 30 end, CASE_KEY, 0 
					from #TMPTBL inner join CASEINFO on CASEINFO.PROG_KEY=#TMPTBL.NODE_KEY
					inner join PROGINFO on CASEINFO.PROG_KEY=PROGINFO.PROG_KEY
					and PROGINFO.BCASE_KEY=CASE_KEY
					and #TMPTBL.NODE_TYPE in (7,27)
				order by CASEINFO.CASE_KEY
					       
					       
		end 
				
		--Insert all invalidated nodes in STAEVENT from the temporary table--
		insert into STAEVENT (STADEF_KEY,START_DAT,FINISH_DAT, USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA)
		   select @eventId,@start_dat,@start_dat,@userName,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,0,0,0,@eventMessage from #TMPTBL 
	  	   order by #TMPTBL.ID desc
	
	execute absp_Util_Log_Info '-- End --',@me 
end
