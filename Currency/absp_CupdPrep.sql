if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdPrep') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdPrep
end
 go

create procedure absp_CupdPrep @nodeKey int ,@nodeType int ,@policyKey int = 0 ,@siteKey int = 0 ,@oldCurrsKey int ,@newCurrsKey int ,@doItFlag int = 0 ,@debugFlag int = 0 ,@sourceDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure creates and populates the following currency update tables required for 
currency conversion:-
CUPDINFO,CUPDCTRL,CUPDLOGS,CURRATIO

Returns:   The currency update key                    
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The node key for which the currency convertion is to be done.
##PD  @nodeType ^^ The node type for which the currency convertion is to be done.
##PD  @policyKey ^^ The policy key for which the currency convertion is to be done.
##PD  @siteKey ^^ The site key for which the currency convertion is to be done.
##PD  @oldCurrsKey ^^ The key of the old currency schema from which the currency values are to be converted.
##PD  @newCurrsKey ^^ The key of the new currency schema to which the currency values are to be converted.
##PD  @doItFlag ^^ This parameter is unused.
##PD  @debugFlag ^^ The debug flag 

##RD @cupdKey ^^ The currency update key of the new currency update record. In case of invalid params, it returns -1.

*/
as

begin

   set nocount on
   
  /*
  This will get you set up to do a currency conversion
  of a given node to a new curr schema from an old curr schema
  */
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @doIt int
   declare @cupdKey int
   declare @cnt1 int
   declare @cnt2 int
   declare @oldUsd float(53)
   declare @newUsd float(53)
   declare @msg varchar(255)
   declare @msgTxt01 varchar(255)
   declare @msgTxt02 varchar(255)
   declare @msgTxt03 varchar(255)
   declare @createDt char(20)
   declare @sqlScript varchar(max)
   declare @sql nvarchar(max)
   declare @oldCFRefKey int
   declare @newCFRefKey int

   set @me = 'absp_CupdPrep: ' -- set to my name (name_of_proc plus ': '
   set @doIt = @doItFlag -- initialize
   set @debug = @debugFlag -- initialize
   if @debug > 0
   begin
      set @msgTxt01 = @me+'starting'
      execute absp_messageEx @msgTxt01
   end
   
   if @sourceDB=''
	   set @sourceDB=DB_NAME()
	  
   --Enclose within square brackets--
   execute absp_getDBName @sourceDB out, @sourceDB
   
   select @oldCFRefKey = CF_REF_KEY from CFLDRINFO where DB_NAME = substring(@sourceDB,2,len(@sourceDB)-2)
   select @newCFRefKey = CF_REF_KEY from CFLDRINFO where DB_NAME = DB_NAME()
   --Enclose within square brackets--
   execute absp_getDBName @sourceDB out, @sourceDB
   
  ------------------------------------------------------------------------------
  -- CUPDCTRL default STATUS value check
   if not exists(select  1	from SYS.COLUMNS  A, Sys.Default_Constraints B 
  							where object_name(A.object_id) = 'CUPDCTRL' 
							and A.name = 'STATUS' 
							--and B.Definition = '(''N'')' 
							and A.Object_Id = B.Parent_Object_Id)
   begin
      execute absp_CupdDevDropTbl
   end
  ------------------------------------------------------------------------------
  -- just in case the info table is missing, create it
    if not exists(select  1 from sysobjects where name = 'CUPDINFO' and type = 'U')
      begin
           exec absp_Util_createTableScript @sqlScript out,'CUPDINFO','','',1,1
   	execute (@sqlScript)
   	
      end -- if control table is old schema, drop it
      if exists(select  1 from sysobjects where name = 'CUPDCTRL' and type = 'U')
      begin
         if not exists(select  1 from SYS.COLUMNS where object_name(object_id) = 'CUPDCTRL' and name = 'POLICY_KEY')
         begin
            drop table CUPDCTRL
         end
      end
     -- just in case the control table is missing, create it
      if not exists(select  1 from sysobjects where name = 'CUPDCTRL' and type = 'U')
      begin
           exec absp_Util_createTableScript @sqlScript out,'CUPDCTRL','','',1,1
   	execute (@sqlScript)
      end
     -- just in case the log table is missing, create it
      if not exists(select  1 from sysobjects where name = 'CUPDLOGS' and type = 'U')
      begin
           exec absp_Util_createTableScript @sqlScript out,'CUPDLOGS','','',1,1
   	execute (@sqlScript)
   
      end
     -- just in case the ratio table is missing, create it
      if not exists(select  1 from sysobjects where name = 'CURRATIO' and type = 'U')
      begin
           exec absp_Util_createTableScript @sqlScript out,'CURRATIO','','',1,0
   	execute (@sqlScript)
      end
      if not exists(select  1 from sysobjects where name = 'CUPDSTAT' and type = 'U')
      begin
           create table CUPDSTAT
	   (
	          CUPDSTATS_KEY  int identity not null,
	          CUPD_KEY       int,
	          APORT_NODES    int default 0, 
	          RPORT_NODES    int default 0, 
	          PPORT_NODES    int default 0, 
	          PROG_NODES     int default 0, 
	          GPI_RECORDS    int default 0, 
	          PC_RECORDS     int default 0, 
	          SAGPS_RECORDS  int default 0, 
	          SLIC_RECORDS   int default 0, 
	          PFASR_RECORDS  int default 0, 
	          SFSAR_RECORDS  int default 0, 
	          CHASDATA_RECORDS  int default 0, 
	          RECORDS        int default 0, 
	          DATE_TIME      datetime,
	          TEXT_MSG       char (50)
    	   )   
      end
  ------------------------------------------------------------------------------
  -----------------------------------------------------------------------------

  -- error checking
  -- node stuff
  -- Better to create a real table but its not used a lot so we created a temp table 
   create table #NODETYPES
   (
      NODE_TYPE INT   null
   ) -- Folder
   insert into #NODETYPES values(0)
   insert into #NODETYPES values(1) -- APORT
   insert into #NODETYPES values(2) -- PPORT	
   insert into #NODETYPES values(3) -- RPORT
   insert into #NODETYPES values(7) -- PROG
   insert into #NODETYPES values(8) -- POLICY
   insert into #NODETYPES values(9) -- SITE
   insert into #NODETYPES values(10) -- CASE
   insert into #NODETYPES values(12) -- CURRENCY Folder
   insert into #NODETYPES values(23) -- MT RPORT
   insert into #NODETYPES values(27) -- MT PROG
   insert into #NODETYPES values(30) -- MT CASE
   if not exists(select  1 from #NODETYPES where NODE_TYPE = @nodeType)
   begin
      if @debug > 0
      begin
         set @msgTxt01 = @me+'parameter error; check nodeKey or nodeType'
         execute absp_messageEx @msgTxt01
      end
      set @msgTxt02 = -1
      set @msgTxt03 = @me+'parameter error; check nodeKey or nodeType'
      execute absp_CupdLogMessage @msgTxt02,'E',@msgTxt03
      set @cupdKey = -1
      return @cupdKey
   end
  -- So I can be called with -1,-1 I will not check the currencies.
   if @oldCurrsKey <> -1 and @newCurrsKey <> -1
   begin
    --currskeys
      if @oldCurrsKey < 1 or @newCurrsKey < 1 --or @oldCurrsKey = @newCurrsKey
      begin
         if @debug > 0
	 begin
		set @msgTxt01 = @me+'parameter error; check oldCurrsKey or newCurrsKey'
		execute absp_messageEx @msgTxt01
	 end
         set @msgTxt02 = -1
         set @msgTxt03 = @me+'parameter error; check oldCurrsKey or newCurrsKey'
         execute absp_CupdLogMessage @msgTxt02,'E',@msgTxt03
         set @cupdKey = -1
         return @cupdKey
      end
      
      set @sql='select  @cnt1 = count(*)  from ' + dbo.trim(@sourceDB)+'..EXCHRATE where CURRSK_KEY = ' + str(@oldCurrsKey)
      execute sp_executesql @sql,N'@cnt1 int output',@cnt1 output

      select  @cnt2 = count(*)  from EXCHRATE where CURRSK_KEY = @newCurrsKey
    -- SDG__00015401 -- copy works but currency conversion fails if you have more codes in the currency schema of the destination Currency Folder
    -- SDG__00015402 -- Copy-Paste of a program across currency folder  is successful  even when the currency conversion fails
    --    The test for mismatched exchange rates was stopping and returning -1, but the caller (in JAVA)
    --    was ignoring the return code.
    --
    --    The rate tables could mismatch for one of two reasons: Either 
    --    (A) the destination table has added records or
    --    (B) the source table has missing records.
    --
    --    Case (A) is harmless, Because the new records have never been referenced.
    --    The GUI is supposed to prevent case (B).
    --
    --    Remove the test for @cnt1 <> @cnt2
      if @cnt1 < 1 or @cnt2 < 1
      begin
	 if @debug > 0
	 begin
		set @msgTxt01 = @me+' EXCHRATE error: zero records in either the new or old currency'
		execute absp_messageEx @msgTxt01
	 end
	 set @msgTxt02 = -1
	 set @msgTxt03 = @me+' EXCHRATE error: zero records in either the new or old currency'
	 execute absp_CupdLogMessage @msgTxt02,'E',@msgTxt03
	 set @cupdKey = -1
	 return @cupdKey
      end
   end
  ------------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- get my new update key
   execute @cupdKey = absp_GenericTableGetNewKey 'CUPDINFO','OLDCURSKEY',0
   exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
   update CUPDINFO set CREATE_DAT = @createDt ,NODE_KEY = @nodeKey,NODE_Type = @nodeType,OLDCURSKEY = @oldCurrsKey,NEWCURSKEY = @newCurrsKey,STATUS = 'NEW'  where
   CUPD_KEY = @cupdKey
   if @debug > 0
   begin
	  set @msgTxt01 = @me+'@cupdKey = '+rtrim(ltrim(str(@cupdKey)))
	  execute absp_messageEx @msgTxt01
   end
   if @oldCurrsKey <> -1 and @newCurrsKey <> -1
   begin
	  set @sql='select  @oldUsd = EXCHGRATE  from ' + dbo.trim(@sourceDB)+'..EXCHRATE where CODE = ''USD'' and CURRSK_KEY = '+ str(@oldCurrsKey)
	  execute sp_executesql @sql,N'@oldUsd float(53) output',@oldUsd output

	  select  @newUsd = EXCHGRATE  from EXCHRATE where CODE = 'USD' and CURRSK_KEY = @newCurrsKey
	  
	  --SDG__00024092 - add new and old schema currsk_key  in curratio
	  set @sql='insert into CURRATIO(CUPD_KEY,CODE,OLD_RATE,OLD_USD,OLD_RATIO,NEW_USD,OLD_CS_KEY, NEW_CS_KEY, OLD_CF_REF_KEY, NEW_CF_REF_KEY)
	    select  ' + str(@cupdKey) + ',CODE,EXCHGRATE,' + convert(varchar, @oldUsd) +',EXCHGRATE/'+ convert(varchar, @oldUsd)+
	            ',' + str(@newUsd) + ',' + str(@oldCurrsKey) + ',' + str(@newCurrsKey) + ',' + str(@oldCFRefKey) + ',' + str(@newCFRefKey)
				+ ' from ' + dbo.trim(@sourceDB)+ 
	            '..EXCHRATE where CURRSK_KEY = ' + str(@oldCurrsKey)
	  exec(@sql)
	  
	  update CURRATIO  SET NEW_RATE = E.EXCHGRATE,NEW_RATIO = E.EXCHGRATE/@newUsd FROM CURRATIO as C, EXCHRATE as E
	  where
	  C.CODE = E.CODE and C.CUPD_KEY = @cupdKey and
	  E.CURRSK_KEY = @newCurrsKey
	  
	  update CURRATIO set RATIO = OLD_RATIO/NEW_RATIO  where CUPD_KEY = @cupdKey
   end
  -- set up my control table
   if @cupdKey > 0
   begin
   select  @nodeKey = NODE_KEY,@nodeType = NODE_TYPE  from CUPDINFO where CUPD_KEY = @cupdKey
   set @msg = @me+'@nodeKey, @nodeType = '+rtrim(ltrim(str(@nodeKey)))+', '+rtrim(ltrim(str(@nodeType)))
   if @debug > 0
   begin
	 execute absp_messageEx @msg
   end
   execute absp_CupdLogMessage @cupdKey,'M',@msg
-- call the correct filler-inner based on the node type
   if @nodeType = 0
   begin
	 execute absp_CupdFolder @cupdKey,@nodeKey,@doIt,@debug
   end
   else
   begin
	 if @nodeType = 1
	 begin
		execute absp_CupdAport @cupdKey,0,@nodeKey,@doIt,@debug
	 end
	 else
	 begin
		if @nodeType = 2
		begin
		      execute absp_CupdPport @cupdKey,0,0,@nodeKey,0,0,@doIt,@debug
		end
		else
		begin
		      if @nodeType = 3 or @nodeType = 23
		      begin
		 	    execute absp_CupdRport @cupdKey,0,0,@nodeKey,@doIt,@debug
		      end
		      else
		      begin
		  	    if @nodeType = 7 or @nodeType = 27
			    begin
			 	  execute absp_CupdProg @cupdKey,0,0,0,@nodeKey,@doIt,@debug
			    end
			    else
			    begin
			          if @nodeType = 8
			   	  begin
					execute absp_CupdPport @cupdKey,0,0,@nodeKey,@policyKey,0,@doIt,@debug
				  end
				  else
				  begin
					if @nodeType = 9
					begin
				 	      execute absp_CupdPport @cupdKey,0,0,@nodeKey,@policyKey,@siteKey,@doIt,@debug
					end
					else
					begin
					      if @nodeType = 10
					      begin
						    insert into CUPDCTRL(CUPD_KEY,PROG_KEY,LPORT_KEY,PORT_ID,CASE_KEY,STATUS) values(@cupdKey,0,0,0,@nodeKey,'N')
					      end
					      else
					      begin
						    if @nodeType = 12
						    begin
							  execute absp_CupdFolder @cupdKey,@nodeKey,@doIt,@debug
						    end
					      end
					end
				  end
			    end
			end
		  end
	    end
       end
   end
  -- ============================================================================================
  -- emergency fix-up for CURRFLDS until we get migration fix
   select  @cnt1 = count(*)  from CURRFLDS where TABLENAME = 'INURINFO' and FIELDNAME = 'IIOCC_VAL'
   if @cnt1 = 0
   begin
	  insert into CURRFLDS values('INURINFO',2,'IIOCC_VAL','IIOCC_CC','OCC_LIM','N')
   end
   select  @cnt1 = count(*)  from CURRFLDS where TABLENAME = 'CASEINFO' and FIELDNAME = 'CIOCC_VAL'
   if @cnt1 = 0
   begin
	  insert into CURRFLDS values('CASEINFO',3,'CIOCC_VAL','CIOCC_CC','OCC_LIM','N')
   end
   select  @cnt1 = count(*)  from CURRFLDS where TABLENAME = 'INURLAYR' and FIELDNAME = 'ILRET_VAL'
   if @cnt1 = 0
   begin
	  insert into CURRFLDS values('INURLAYR',7,'ILRET_VAL','ILRET_CC','SS_RETLINE','N')
   end
   select  @cnt1 = count(*)  from CURRFLDS where TABLENAME = 'CASELAYR' and FIELDNAME = 'CLRET_VAL'
   if @cnt1 = 0
   begin
	  insert into CURRFLDS values('CASELAYR',9,'CLRET_VAL','CLRET_CC','SS_RETLINE','N')
   end
   if @debug > 0
   begin
	  set @msgTxt01 = @me+'finished'
	  execute absp_messageEx @msgTxt01
   end
  -- return the new key
   return @cupdKey
end




