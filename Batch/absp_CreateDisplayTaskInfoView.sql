if exists(select * from SYSOBJECTS where id = object_id(N'absp_CreateDisplayTaskInfoView') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateDisplayTaskInfoView
end
go

create procedure absp_CreateDisplayTaskInfoView
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

    This procedure automatically creates display task info views in the User Database for the
    TaskInfo table in the commondb database

Returns:       None
====================================================================================================
</pre>
</font>
##BD_END

*/

AS
begin

    set nocount on

	declare @sql nvarchar(max)
	declare @userDb varchar(120)

    print 'start Procedure absp_CreateDisplayTaskInfoView... '
    
    set @userDb = ltrim(rtrim(DB_NAME()))
	if @userDb = 'commondb' or @userDb = 'systemdb' or right(ltrim(rtrim(@userDb)), 3) = '_IR'
	begin
	    print 'return because dbName = ' +@userDb
		return
    end
    
	-- drop 'view' from the database if exists
	if exists (select 1 from SYSOBJECTS where id = OBJECT_ID('DisplayTaskInfo') and OBJECTPROPERTY(id, N'IsView') = 1)
	begin
		 set @sql = 'drop view DisplayTaskInfo'
         print @sql
		 exec(@sql)
	end

	-- create the view for TaskInfo table
	if OBJECT_ID('commondb.dbo.TaskInfo', 'U') IS NOT NULL
	begin
		set @sql = 'create view DisplayTaskInfo as ' + 
	    '(select ltrim(rtrim(TaskTypeName)) displayTaskType, ' +
		'(select distinct ltrim(rtrim(node_name)) from nodedef where node_type = NodeType) displayNodeType, ' +
		'case nodeType ' +
		'when 0 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from fldrinfo ' +
					'where  folder_key = FolderKey and curr_node=''N'') ' +
		'when 12 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from cfldrInfo ' +
					'where folder_key = FolderKey and cf_ref_key = DBRefKey) ' +
		'when 1 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from AprtInfo ' +  
					'where aport_key = AportKey) ' +
		'when 2 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from PprtInfo ' +
					'where pport_key = PportKey) ' +
		'when 3 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from RprtInfo ' +
					'where rport_key = RportKey) ' +
		'when 7 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from ProgInfo ' +
					'where  prog_key = ProgramKey) ' +
		'when 10 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(prg.longname)) + ''->'' + ltrim(rtrim(ci.longname)))  from CaseInfo ci join ProgInfo prg on ci.prog_key=prg.prog_key ' + 
					'where case_key = CaseKey) ' +
		'when 23 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from RprtInfo ' + 
					'where rport_key = RportKey) ' +
		'when 27 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from ProgInfo ' + 
					'where prog_key = ProgramKey) ' +
		'when 30 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(prg.longname)) + ''->'' + ltrim(rtrim(ci.longname))) from CaseInfo ci join ProgInfo prg on ci.prog_key=prg.prog_key ' +
					'where case_key = CaseKey) ' +
		'when 31 then substring(TaskDescription,1,len(TaskDescription)-3) + '  +
			'case isNull(t.PportKey, 0) ' +
			'when 0 then (select ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) from progInfo r, account a where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey) ' + 
			'else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(accountName)) from pprtinfo p, account a where pport_key = PportKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey) end ' +
		'when 32 then substring(TaskDescription,1,len(TaskDescription)-3) + ' + 
			'case isNull(t.PportKey, 0) ' +
			'when 0 then (select  ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) +  ''->'' + ltrim(rtrim(policyName))from progInfo r, (account a join policy pcy on a.accountKey = pcy.accountKey and a.exposureKey = pcy.exposureKey) ' +
					'where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey and pcy.policyKey =t.PolicyKey ) ' +
			'else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(a.accountName)) + ''->'' + ltrim(rtrim(pcy.policyName))  from pprtinfo p, (account a join policy pcy on a.accountKey = pcy.accountKey and a.exposureKey = pcy.exposureKey) ' +
					'where pport_key = t.pportKey and a.accountKey=t.accountKey and a.exposureKey=t.exposureKey and pcy.policyKey = t.policyKey) end ' +
		'when 33 then substring(TaskDescription,1,len(TaskDescription)-3) + ' +
			'case isNull(t.PportKey, 0) ' +
			'when 0 then (select ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) +  ''->'' + ltrim(rtrim(siteName)) from progInfo r, (account a join site st on a.accountKey = st.accountKey and a.exposureKey = st.exposureKey) ' +
					'where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey and st.siteKey =t.siteKey) ' +
			'else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(a.accountName)) + ''->'' + ltrim(rtrim(st.siteName))  from pprtinfo p, (account a join site st on a.accountKey = st.accountKey and a.exposureKey = st.exposureKey) ' + 
					'where pport_key = t.pportKey and a.accountKey=t.accountKey and a.exposureKey=t.exposureKey and st.siteKey = t.siteKey) end  ' +
		'else ''unknown'' ' +
		'end displayDescription, ' +
		'CASE subString(startdate,5,2) ' +
		'WHEN ''01'' THEN subString(startdate,7,2) + '' Jan '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''02'' THEN subString(startdate,7,2) + '' Feb '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''03'' THEN subString(startdate,7,2) + '' Mar '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''04'' THEN subString(startdate,7,2) + '' Apr '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''05'' THEN subString(startdate,7,2) + '' May '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''06'' THEN subString(startdate,7,2) + '' Jun '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''07'' THEN subString(startdate,7,2) + '' Jul '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''08'' THEN subString(startdate,7,2) + '' Aug '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''09'' THEN subString(startdate,7,2) + '' Sep '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''10'' THEN subString(startdate,7,2) + '' Oct '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''11'' THEN subString(startdate,7,2) + '' Nov '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'WHEN ''12'' THEN subString(startdate,7,2) + '' Dec '' + left(startdate,4) + '', '' + subString(startdate,9,2) + '':'' + subString(startdate,11,2) + '':'' + subString(startdate,13,2) ' +
		'else ' +
		''' '' ' +
		'END displayLaunchTime, ' +
		'(select db_name from cfldrinfo where cf_ref_key = DBRefKey) displayDbName, ' + 
		' t.*, td.TaskTypeName,td.TaskDescription,td.AllowCancel from taskinfo t, TaskDef td where td.TaskTypeID = t.TaskTypeID) '
	
		--print @sql
		exec(@sql)
	end
	print 'End Procedure absp_CreateDisplayTaskInfoView... '
end