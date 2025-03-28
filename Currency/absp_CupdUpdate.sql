if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdUpdate') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdUpdate
end
go

create procedure absp_CupdUpdate @cupdKey int,@doItFlag int = 0,@debugFlag int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure performs currency conversion in all the currency tables associated to a given cupdKey.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @doItFlag ^^  This is unused by the procedure and the called procedures. 
##PD  @debugFlag ^^  The debug flag.

*/
as
begin

   set nocount on
   
	  /*

	  This is the guy that does the work
	  Gets called from driver to start from scratch, OR,
	  call manually with existing CUPD_KEY to restart an aborted job
	  */
	  -- standard declares
	   declare @me varchar(255)
	   declare @debug int
	   declare @doIt int
	   declare @nodeKey int
	   declare @nodeType int
	   declare @msg varchar(255)
	   declare @newCursKey int
	   declare @tableName char(50)
	   declare @sql varchar(1000)
	   create table #CURRATIO_TMP
	   (
		  CODE char(3)  COLLATE SQL_Latin1_General_CP1_CI_AS  null,
		  RATIO float(53)   null
	   )
	   declare @msgTxt varchar(255)
	   declare @PPK int
	   declare curs0  cursor dynamic local for select distinct PPORT_KEY from CUPDCTRL where
	   CUPD_KEY = @cupdKey and
	   PPORT_KEY > 0 and
	   STATUS = 'N' order by
	   PPORT_KEY asc
	   declare @LPK int
	   declare @RPK int
	   declare @createDt char(20)
	   
	   declare curs2  cursor dynamic local for select distinct RPORT_KEY from CUPDCTRL where 
	   CUPD_KEY = @cupdKey and RPORT_KEY > 0 and STATUS = 'N' order by RPORT_KEY asc

	   declare @PRPK int
	   declare @cs1PRGK int
	   declare @cs1LK int
	   declare @cs1PK int
	   declare @cs1CSK int
	   declare case1  cursor dynamic local for select distinct PROG_KEY,LPORT_KEY,PORT_ID,CASE_KEY as caseKey from CUPDCTRL where
	   CUPD_KEY = @cupdKey and
	   PROG_KEY = 0 and
	   LPORT_KEY = 0 and
	   PORT_ID = 0 and
	   CASE_KEY > 0 and
	   STATUS = 'N' order by
	   CASE_KEY asc
	   declare @cs5CHASK int
	   declare @cs5POLK int
	   declare @cs5SITEK int
	   declare curs5  cursor dynamic local for select distinct CHAS_KEY ,POLICY_KEY,SITE_KEY from
	   CUPDCTRL where
	   CUPD_KEY = @cupdKey and
	   CHAS_KEY > 0 and
	   STATUS = 'N' order by
	   CHAS_KEY asc
	   declare @cursFldr_FK int
	   declare cursFldr  cursor dynamic local for select distinct FOLDER_KEY from CUPDCTRL where
	   CUPD_KEY = @cupdKey and
	   FOLDER_KEY > 0 and
	   STATUS = 'N'
	   set @me = 'absp_CupdUpdate: ' -- set to my name (name_of_proc plus ': '
	   set @doIt = @doItFlag -- initialize
	   set @debug = @debugFlag -- initialize

	   if @debug > 0
	   begin
		  set @msgTxt = @me+'starting'
		  execute absp_messageEx @msgTxt
	   end

	   set @cupdKey = @cupdKey
	  -- load CURRATIO into CURRATIO_TMP
	   insert into #CURRATIO_TMP select  CODE,RATIO from CURRATIO where CUPD_KEY = @cupdKey
	   create index CURRATIO_TMP_I1 on #CURRATIO_TMP
	   (CODE asc)
	  -- need the new CURRSK_KEY
	   select  @newCursKey = NEWCURSKEY  from CUPDINFO where CUPD_KEY = @cupdKey
	  -- update the CUPDINFO status
	   update CUPDINFO set STATUS = 'Progress'  where
	   CUPD_KEY = @cupdKey
	  -- now do the work
	  -- 1.  Iterate the distinct PORT_ID and update the portfolio tables
	  -- 1a.	by PPORT_KEY
	  -- 1b.	by RPORT_KEY by PROG_KEY
	  -- 2.  Iterate the distinct CHAS_KEY and update CHASDATA then CHASINFO.CURRSK_KEY
	  -- 2a.   for CHASINFO.currskey
	  -- 3.  Iterate the distinct PROG_KEY and update cupdForProg
	  -- 4.  Iterate the distinct APORT_KEY and update cupdForAport
	  -- =====================================================================================
	  -- 1a.  Iterate the distinct PORT_ID and update the portfolio tables by PPORT_KEY
	   --open curs0
	   --fetch next from curs0 into @PPK
	   --while @@fetch_status = 0
	   --begin
		   --declare curs1 cursor dynamic local for select distinct LPORT_KEY from CUPDCTRL where
		   --CUPD_KEY = @cupdKey and LPORT_KEY > 0 and PPORT_KEY = @PPK and STATUS = 'N' order by
		   --LPORT_KEY asc

		  --open curs1
		  --fetch next from curs1 into @LPK
		  --while @@fetch_status = 0
			  --begin
					 --execute absp_CupdUpdateLPort @cupdKey,@LPK,@doIt,@debug
					 --fetch next from curs1 into @LPK
			  --end
		  --close curs1
		  --deallocate curs1
		-- now update my PPORT record
		  --exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
		  --update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt  where
		  --CUPD_KEY = @cupdKey and
		  --PPORT_KEY = @PPK and
		 -- LPORT_KEY = 0
		 -- fetch next from curs0 into @PPK
	   --end
	   --close curs0
	   --deallocate curs0
	  -- =====================================================================================
	  -- 1b.  Iterate the distinct PORT_ID and update the portfolio tables by RPORT_KEY by PROG_KEY
	   open curs2
	   fetch next from curs2 into @RPK
	   while @@fetch_status = 0
	   begin
		   declare curs3  cursor dynamic local for select distinct PROG_KEY from CUPDCTRL where
		   CUPD_KEY = @cupdKey and PROG_KEY > 0 and RPORT_KEY = @RPK and STATUS = 'N' order by PROG_KEY asc

		  open curs3
		  fetch next from curs3 into @PRPK
		  while @@fetch_status = 0
		  begin
			 --declare curs4  cursor dynamic local for select distinct LPORT_KEY from CUPDCTRL where
			 --CUPD_KEY = @cupdKey and LPORT_KEY > 0 and RPORT_KEY = @RPK and PROG_KEY = @PRPK and
			 --STATUS = 'N' order by LPORT_KEY asc

			 --open curs4
			 --fetch next from curs4 into @LPK
			 --while @@fetch_status = 0
			 --begin
			--	execute absp_CupdUpdateLPort @cupdKey,@LPK,@doIt,@debug
				--fetch next from curs4 into @LPK
			 --end
			 --close curs4
			 --deallocate curs4
		  -- =====================================================================================
		  -- Iterate the distinct PROG_KEY and update cupdForProg
			 set @msgTxt = @me+'about to - '+'absp_CupdForProgram('+rtrim(ltrim(str(@cupdKey)))+', '+rtrim(ltrim(str(@debug)))+');'
			 execute absp_messageEx @msgTxt
		  -- now do the parts of the Prog
			 execute absp_CupdForProgram @cupdKey,@PRPK,@debug
		  -- now update my PROG record
		  	 exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
			 update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt where
			 CUPD_KEY = @cupdKey and
			 PROG_KEY = @PRPK and
			 RPORT_KEY = @RPK and
			 LPORT_KEY = 0
			 fetch next from curs3 into @PRPK
		  end
		  close curs3
		  deallocate curs3
		-- now update my RPORT record
		  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
		  update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt  where
		  CUPD_KEY = @cupdKey and
		  RPORT_KEY = @RPK and
		  PROG_KEY = 0 and
		  LPORT_KEY = 0
		  fetch next from curs2 into @RPK
	   end
	   close curs2
	   deallocate curs2 			


	  -- =====================================================================================
	  -- 1c.  Iterate the distinct CASE_KEY for case-level ONLY
	   open case1
	   fetch next from case1 into @cs1PRGK,@cs1LK,@cs1PK,@cs1CSK
	   while @@fetch_status = 0
	   begin
		  execute absp_CupdTreatyTables 'CASE_KEY',@cs1CSK,@cupdKey,@debug
		-- now update the status of my CASE_KEY record
		  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
		  update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt where
		  CUPD_KEY = @cupdKey and
		  CASE_KEY = @cs1CSK
		  fetch next From case1 into @cs1PRGK,@cs1LK,@cs1PK,@cs1CSK
	   end
	   close case1
	   deallocate case1 			

	  -- =====================================================================================
	  -- 1c.  Iterate the distinct PROG_KEY  
	  	  declare prog cursor dynamic local for select distinct PROG_KEY  as progKey 
	   	   	from CUPDCTRL where CUPD_KEY = @cupdKey and  PROG_KEY>0   and STATUS = 'N' order by  PROG_KEY asc
	   open prog
	   fetch next from prog into @cs1PRGK
	   while @@fetch_status = 0
	   begin
	   	--Get all cases for prog--
	   	declare curs1  cursor dynamic local for select distinct CASE_KEY from CASEINFO where  PROG_KEY=@cs1PRGK
	   	open curs1
		fetch next from curs1 into @cs1CSK
	   	while @@fetch_status = 0
		begin  
			execute absp_CupdTreatyTables 'CASE_KEY',@cs1CSK,@cupdKey,@debug
			-- now update the status of my CASE_KEY record
			exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
			update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt where CUPD_KEY = @cupdKey and CASE_KEY = @cs1CSK
			fetch next from prog into @cs1CSK
		end
		close curs1
	   	deallocate curs1 
		fetch next from prog into @cs1PRGK
	   end
	   close prog
	   deallocate prog 	

	  -- =====================================================================================
	  -- 2.  Iterate the distinct CHAS_KEY and update CHASDATA then CHASINFO.CURRSK_KEY
	  -- 2a.   update CHASINFO.currskey
	   set @tableName = 'CHASDATA'
	   open curs5
	   fetch next From curs5 into @cs5CHASK,@cs5POLK,@cs5SITEK
	   while @@fetch_status = 0
	   begin
		  set @msgTxt = @me+'about to - '+'exec absp_cupd_'+rtrim(ltrim(@tableName))+' '+rtrim(ltrim(str(@cupdKey)))+', '+rtrim(ltrim(str(@cs5SITEK)))+', '+rtrim(ltrim(str(@debug)))+''
		  execute absp_messageEx @msgTxt
		-- only update CHASDATA if we are at the Portfolio level, not Policy and Site level
		-- since the cupd routine does the update by CHAS_KEY only and may recalc additional records
		  if(@cs5POLK = 0 and @cs5SITEK = 0)
			  begin
				     set @sql = 'exec absp_cupd_'+ @tableName +' '+ str(@cupdKey) +', '+ str(@cs5CHASK) + ', ' + str(@debug)+''
					 execute(@sql)
			  end
		-- update the currency key in CHASINFO
		  update CHASINFO set CURRSK_KEY = @newCursKey  where CHAS_KEY = @cs5CHASK
		  set @msgTxt = @me+'about to - update status to y'
		  execute absp_messageEx @msgTxt
		  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
		  update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt where
		  CUPD_KEY = @cupdKey and
		  CHAS_KEY = @cs5CHASK and
		  TABLENAME = @tableName
		  set @msgTxt = @me+'about to - commit'
		  execute absp_messageEx @msgTxt
		  fetch next from curs5 into @cs5CHASK,@cs5POLK,@cs5SITEK
	   end
	   close curs5
	   deallocate curs5
	  -- note:  the following procedures do their own commit and update CUPDCTRL.STATUS
	  -- =====================================================================================
	  -- 4.  Iterate the distinct APORT_KEY and update cupdForAport
	   set @msgTxt = @me+'about to - '+'absp_CupdForAport('+rtrim(ltrim(str(@cupdKey)))+', '+rtrim(ltrim(str(@debug)))+');'
	   execute absp_messageEx @msgTxt
	   execute absp_CupdForAport @cupdKey,@debug 
	  -- =====================================================================================
	  -- 5.  Iterate the remaining FOLDER_KEY which are status = N
	   open cursFldr
	   fetch next from cursFldr into @cursFldr_FK
	   while @@fetch_status = 0
	   begin
	   	  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
		  update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt where
		  CUPD_KEY = @cupdKey and FOLDER_KEY = @cursFldr_FK and STATUS = 'N'
		  fetch next from cursFldr into @cursFldr_FK
	   end
	   close cursFldr
	   deallocate cursFldr
	   if @debug > 0
	   begin
		  set @msgTxt = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
		  execute absp_messageEx @msgTxt
	   end
	  -- update the CUPDINFO status
	   if not exists(select  1 from CUPDCTRL where CUPD_KEY = @cupdKey and STATUS = 'N')
	   begin
		  update CUPDINFO set STATUS = 'Complete'  where
		  CUPD_KEY = @cupdKey
	   end
end

