if exists ( select 1 from sysobjects where name =  'absp_Util_MCF_CreateLockTestCurrencyDB' and type = 'P' ) 
begin
        drop procedure absp_Util_MCF_CreateLockTestCurrencyDB ;
end
go

create procedure absp_Util_MCF_CreateLockTestCurrencyDB  @cfDBName varchar(128) = 'LockTestCF', @basePathPri varchar(254),  @currencyPathPri varchar(254), @basePathIR varchar(254), @currencyPathIR varchar(254), @createNewDB integer = 0
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure creates a currency DB and loads sets of info tables for testing node locks
     
    	    
Returns:       Nothing  
====================================================================================================
</pre>
</font>
##BD_END 

*/


BEGIN 

	set nocount on
  	declare @dbnameIR varchar(128)
  	declare @sql nvarchar(4000)
  	declare @fileName varchar(255)
 	declare @fileName_log varchar(255)
 	declare @fileNameIR varchar(255)
 	declare @fileNameIR_log varchar(255)

  	
   	select @basePathPri = replace(@basePathPri,'/','\')
   	select @basePathIR = replace(@basePathIR,'/','\')
   	select @currencyPathPri = replace(@currencyPathPri,'/','\')
   	select @currencyPathIR = replace(@currencyPathIR,'/','\')
   	
  	set @cfDBName = ltrim(rtrim(@cfDBName))
  	set @dbnameIR = @cfDBName + '_IR'
  	 	
  	
	set @fileName = @currencyPathPri + '\' + @cfDBName + '.mdf'
	set @fileName_log = @currencyPathPri + '\' + @cfDBName + '_log.ldf'
	set @fileNameIR = @currencyPathIR + '\' + @dbnameIR + '.mdf'
	set @fileNameIR_log = @currencyPathIR + '\' + @dbnameIR + '_log.ldf'
	
	if not exists (SELECT 1 FROM sys.databases where name = @cfDBName)
	begin
		if @createNewDB = 1 
	  	begin
	  		exec absp_Util_CreateDefaultCurrencyFolderDB output,@basePathPri, @currencyPathPri, 'PRI', @cfDBName    
 		end
		else
		begin
			set @sql = 'CREATE DATABASE ' + ltrim(rtrim(@cfDBName))  + ' ON' +
					' (FILENAME = ''' + ltrim(rtrim(@fileName)) + '''),' +
		 			' (FILENAME = ''' + ltrim(rtrim(@fileName_log)) + ''')' +
					' FOR ATTACH'
			print @sql
			exec sp_executesql @sql 
			
		end
	end
	-- if offline, make it online
	else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@cfDBName)) and state_desc = 'offline')
	begin
		set @sql = 'ALTER DATABASE ' + ltrim(rtrim(@cfDBName)) + ' SET ONLINE WITH ROLLBACK IMMEDIATE'
		print @sql
		exec sp_executesql @sql
		
	end
	--else -- already attached
	
	--set collation
	set @sql = 'ALTER DATABASE ' + ltrim(rtrim(@cfDBName)) + ' COLLATE SQL_Latin1_General_CP1_CI_AS'
	print @sql
	exec sp_executesql @sql
 
	if not exists (SELECT 1 FROM sys.databases where name = @dbnameIR)
	begin
		if @createNewDB = 1 
	  	begin  
	 		exec absp_Util_CreateDefaultCurrencyFolderDB output,@basePathIR, @currencyPathIR, 'IR', @dbNameIR
 		end
		else
		begin
			
			set @sql = 'CREATE DATABASE ' + ltrim(rtrim(@dbnameIR))  + ' ON' +
					' (FILENAME = ''' + ltrim(rtrim(@fileNameIR)) + '''),' +
					' (FILENAME = ''' + ltrim(rtrim(@fileNameIR_log)) + ''')' +
					' FOR ATTACH'
						print @sql
			exec sp_executesql @sql 

		end
	end
	-- if offline, make it online
	else if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@dbnameIR)) and state_desc = 'offline')
	begin		
		set @sql = 'ALTER DATABASE ' + ltrim(rtrim(@dbnameIR)) + ' SET ONLINE WITH ROLLBACK IMMEDIATE'
		print @sql
		exec sp_executesql @sql 
	end
	--else -- already attached
	--set collation
	set @sql = 'ALTER DATABASE ' + ltrim(rtrim(@dbnameIR)) + ' COLLATE SQL_Latin1_General_CP1_CI_AS'
	print @sql
	exec sp_executesql @sql 
	
 	-- attach new databases to the WCe app
 	select @sql = 'use systemdb ' +
 	' if not exists(select 1 from commondb.dbo.CFLDRINFO where DB_NAME= ''' + @cfDBName + ''') '  +
 	' exec absp_Util_TreeviewAttachCurrencyFolderDB''' + @cfDBName + ''''	
    
    	print @sql
	exec sp_executesql @sql
		
   	select @sql = 'use'
	select @sql = @sql + ' ' + @cfDBName +
		 ' update CFLDRINFO set CFLDRINFO.[LONGNAME] = CFLDRINFO.[DB_NAME] '
	print @sql 
	exec sp_executesql @sql
	
   	select @sql = 'use'
	select @sql = @sql + ' ' + @cfDBName +
		 ' update CFLDRINFO set CFLDRINFO.[GROUP_KEY] = 1 where CFLDRINFO.[GROUP_KEY] = 0'
	print @sql 
	exec sp_executesql @sql
	

	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete FLDRINFO where FOLDER_KEY > 1'
	
	print @sql 
	exec sp_executesql @sql 
	
    set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert FLDRINFO on ' +
	'insert into FLDRINFO (FOLDER_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY,ATTRIB,CF_REF_KEY)
		values(2, ''folder1'',''ACTIVE'',''20100820180029'',1,	1,''N'',0,0,0)'
	print @sql 
	exec sp_executesql @sql 	

	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete FLDRMAP where FOLDER_KEY > 0'
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql +
  	' insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(1,2,0) ' +
  	' insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(2,1,1)'
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete APRTINFO '
	exec sp_executesql @sql	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert APRTINFO on ' +
	' insert into APRTINFO(APORT_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,REF_APTKEY,ATTRIB) ' +
		'values(1, ''ap1'',''ACTIVE'',''20100820180421'',1,1,0,0)'
	print @sql 
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete APORTMAP '
	print @sql
	exec sp_executesql @sql		
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql +
	' insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(1,1,2) ' +
	' insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(1,2,2) ' +
	' insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(1,1,3) ' +
	' insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(1,2,23)'
	print @sql
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete PPRTINFO'
	print @sql
	exec sp_executesql @sql	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert PPRTINFO on ' +
	' insert into PPRTINFO (PPORT_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,REF_PPTKEY,ATTRIB) ' +
		'values(1,''pp1'',''ACTIVE'',''20100820180632'',1,1,2,0) ' +
	' insert into PPRTINFO (PPORT_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,REF_PPTKEY,ATTRIB) ' +
		'values(2,''pp2'',''ACTIVE'',''20100820180632'',1,1,0,0) ' 	
	print @sql
	exec sp_executesql @sql 
	
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete RPRTINFO'
	print @sql 	
	exec sp_executesql @sql 		
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert RPRTINFO on ' +
	' insert into RPRTINFO(RPORT_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,REF_RPTKEY,MT_FLAG,ATTRIB) ' +
		'values(1,''rp1'',''ACTIVE'',''20100820185037'',1,1,0,''N'',0) ' +	
	' insert into RPRTINFO(RPORT_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,REF_RPTKEY,MT_FLAG,ATTRIB) ' +
		'values(2,''rap1'',''ACTIVE'',''20100821051430'',1,1,0,''Y'',0)'
	print @sql 	
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete RPORTMAP'
	print @sql 	
	exec sp_executesql @sql 
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + 
	' insert into RPORTMAP (RPORT_KEY,CHILD_KEY,CHILD_TYPE) values(1,1,7) ' +
	' insert into RPORTMAP (RPORT_KEY,CHILD_KEY,CHILD_TYPE) values(2,2,27)'
	print @sql 	
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete PROGINFO'
	print @sql 
	exec sp_executesql @sql
	 	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert PROGINFO on ' +
	' insert into PROGINFO (PROG_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,LPORT_KEY, ' +
		'BCASE_KEY,CURRNCY_ID,IMPXCHRATE,INCEPT_DAT,EXPIRE_DAT,GROUP_NAM,BROKER_NAM,PROGSTAT,PORT_ID,MT_FLAG,ATTRIB) ' +
		'values(1,''prg1'',''NEW'',''20100821050153'',1,1,0,1,0,0,''20100821'',''20110820'',''None'',''None'',''Bound'',0,''N'',0)'
	print @sql 
	exec sp_executesql @sql 
		
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert PROGINFO on ' +
	' insert into PROGINFO (PROG_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,GROUP_KEY,LPORT_KEY, ' +
		'BCASE_KEY,CURRNCY_ID,IMPXCHRATE,INCEPT_DAT,EXPIRE_DAT,GROUP_NAM,BROKER_NAM,PROGSTAT,PORT_ID,MT_FLAG,ATTRIB) ' +
		'values(2,''accnt1'',''NEW'',''20100821052404'',1,1,0,0,0,0,''20100821'',''20110820'',''None'',''None'',''Bound'',0,''Y'',0)'
	print @sql 
	exec sp_executesql @sql 

	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete CASEINFO'
	print @sql 	
	exec sp_executesql @sql 		
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert CASEINFO on ' +
	' insert into  CASEINFO (CASE_KEY,PROG_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,TTYPE_ID,NUM_OCCS,AGG_LIMIT,USE_JGFACT, ' +
		'JUDGE_FACT,EVENT_TRIG,OCC_LIM,CIAGG_VAL,CIAGG_CC,CITRIG_VAL,CITRIG_CC,CIOCC_VAL,CIOCC_CC,INUR_ORDR,MT_FLAG,ATTRIB) ' +
		'values(1,1,''case1'',''ACTIVE'',''20100821'',1,1,0,0,''N'',0,0,0,0,''EUR_K'',0,''EUR_K'',0,''USD_U'',0,''N'',0)'
	print @sql 
	exec sp_executesql @sql 
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert CASEINFO on ' +	
	' insert into  CASEINFO (CASE_KEY,PROG_KEY,LONGNAME,[STATUS],CREATE_DAT,CREATE_BY,TTYPE_ID,NUM_OCCS,AGG_LIMIT,USE_JGFACT,' +
		'JUDGE_FACT,EVENT_TRIG,OCC_LIM,CIAGG_VAL,CIAGG_CC,CITRIG_VAL,CITRIG_CC,CIOCC_VAL,CIOCC_CC,INUR_ORDR,MT_FLAG,ATTRIB)' +
		'values(2,2,''trty1'',''ACTIVE'',''20100821'',1,1,0,0,''N'',0,0,0,0,''EUR_K'',0,''EUR_K'',0,''USD_U'',1,''Y'',0)'	
	print @sql 
	exec sp_executesql @sql 
	

	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' delete CASELAYR'
	exec sp_executesql @sql
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert CASELAYR on ' +
	' insert into CASELAYR(CSLAYR_KEY,CASE_KEY,LNUMBER,OCC_LIMIT,OCC_ATTACH,PCT_ASSUME,PCT_PLACE,UW_PREM,CALCR_ID,AGG_LIMIT,AGG_ATTACH,SUBJ_PREM,ELOSSRATIO,ELOSS_BETA,ATTH_RATIO,AGG_RATIO,PR_CEDED,SS_MAXLINE, ' +
	' SS_RETLINE,COB_ID,TREATY_ID,PR_ATTACH,PR_LIMIT,PR_ASSUME,PR_NUM_POL,CLLIM_VAL,CLLIM_CC,CLATT_VAL,CLATT_CC, ' +
	' CLPREM_VAL,CLPREM_CC,CLAGG_VAL,CLAGG_CC,CLRET_VAL,CLRET_CC,CLAAT_VAL,CLAAT_CC,CLSPRM_VAL,CLSPRM_CC,CLPRA_VAL,CLPRA_CC,CLPRL_VAL,CLPRL_CC) ' +
	' values(1,1,1,13612850.5309012,0,100.000,100.000,0,1,0,0,0,0.00,0.00,0.00,0.00,NULL,0,0,0,0,0,0,0.000,0,10000000, ' +
	'''EUR_K'',0,''EUR_K'',0,''EUR_K'',0,''EUR_K'',0,NULL,0,''EUR_K'',0,NULL,0,NULL,0,NULL) ' 
	exec sp_executesql @sql
	
	set @sql = 'use ' + @cfDBName   
	set @sql = @sql + ' set identity_insert CASELAYR on ' +
	' insert into CASELAYR(CSLAYR_KEY,CASE_KEY,LNUMBER,OCC_LIMIT,OCC_ATTACH,PCT_ASSUME,PCT_PLACE,UW_PREM,CALCR_ID,AGG_LIMIT,AGG_ATTACH,SUBJ_PREM,ELOSSRATIO,ELOSS_BETA,ATTH_RATIO,AGG_RATIO,PR_CEDED,SS_MAXLINE, ' +
	' SS_RETLINE,COB_ID,TREATY_ID,PR_ATTACH,PR_LIMIT,PR_ASSUME,PR_NUM_POL,CLLIM_VAL,CLLIM_CC,CLATT_VAL,CLATT_CC, ' +
	' CLPREM_VAL,CLPREM_CC,CLAGG_VAL,CLAGG_CC,CLRET_VAL,CLRET_CC,CLAAT_VAL,CLAAT_CC,CLSPRM_VAL,CLSPRM_CC,CLPRA_VAL,CLPRA_CC,CLPRL_VAL,CLPRL_CC) ' +
	' values(2,2,1,13612850.5309012,0,100.000,100.000,0,1,0,0,0,0.00,0.00,0.00,0.00,NULL,0,0,0,0,0,0,0.000,0,10000000, ' +
	'''EUR_K'',0,''EUR_K'',0,''EUR_K'',0,''EUR_K'',0,NULL,0,''EUR_K'',0,NULL,0,NULL,0,NULL) ' 
	exec sp_executesql @sql
end
