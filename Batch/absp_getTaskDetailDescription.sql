if exists(select * from sysobjects WHERE id = object_id(N'absp_getTaskDetailDescription') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure [absp_getTaskDetailDescription]
end
go
create procedure [absp_getTaskDetailDescription] @nodeType INT,@FolderKey INT, @DBRefKey INT, @AportKey INT,@PportKey INT,
@RportKey INT, @ProgramKey INT, @CaseKey INT,@taskKey INT,@sourceDataBaseName varchar(120),@targetDataBaseName varchar(120),@targetNodeType INT,@taskTypeid INT
,@targetFolderKey INT, @targetDBRefKey INT, @targetAportKey INT,@targetPportKey INT,
@targetRportKey INT, @targetProgramKey INT, @targetCaseKey INT, @rdbInfoKey INT = 0

AS
begin
declare @sourceNodeName as varchar(50)
declare @targetNodeName as varchar(50)
declare @qry varchar(max)

--declare @taskTypeid int
--set @taskTypeid= (select tasktypeid from TaskInfo where TaskKey=@taskKey)


if (@taskTypeid=3 and (@targetNodeType is not null))
	begin
		EXEC absp_getNodeName @sourceDataBaseName,@FolderKey , @DBRefKey , @AportKey ,@PportKey ,
@RportKey , @ProgramKey , @CaseKey, @taskKey, @nodeType, @sourceNodeName out
		EXEC absp_getNodeName @targetDataBaseName,@targetFolderKey , @targetDBRefKey , @targetAportKey ,@targetPportKey ,
@targetRportKey , @targetProgramKey , @targetCaseKey, @taskKey, @targetNodeType, @targetNodeName out
		--EXEC absp_getTargetNodeName @sourceDataBaseName, @taskKey,@sourceNodeName out
		--EXEC absp_getTargetNodeName @targetDataBaseName, @taskKey,@targetNodeName out
		select 'Copying Exposure from ' +@sourceDataBaseName+'.'+@sourceNodeName+' to '+@targetDataBaseName+'.'+@targetNodeName as TaskDescription
		--print @TaskDescription
 End
Else
Begin

if @nodeType = 102 or @nodeType = 103
set @qry = 'select case ' + rtrim(str(@nodeType)) +         
' when 102 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from RdbInfo where RdbInfoKey = ' + rtrim(str(@rdbInfoKey)) +  ')' +
' when 103 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from RdbInfo where RdbInfoKey = ' + rtrim(str(@rdbInfoKey)) + ')' +
' else '' '' end TaskDetailDescription' + 
' from taskinfo t, TaskDef td where td.TaskTypeID = t.TaskTypeID and t.taskKey = ' +rtrim(str(@taskKey))
else
set @qry = 'select case ' + rtrim(str(@nodeType)) + 
' when 0 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from fldrinfo where  folder_key = ' + rtrim(str(@FolderKey)) + ' and curr_node=''N'')' + 
' when 12 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from cfldrInfo where folder_key = ' + rtrim(str(@FolderKey)) + ' and cf_ref_key = '  + rtrim(str(@DBRefKey)) + ')' +
' when 1 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from AprtInfo where aport_key = ' + rtrim(str(@AportKey)) +  ')' +
' when 2 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from PprtInfo where pport_key = ' + rtrim(str(@PportKey)) + ')' +
' when 3 then (select replace(TaskDescription,''{0}'', ltrim(rtrim(longname))) from RprtInfo where rport_key = ' + rtrim(str(@RportKey)) + ')' +
' when 7 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from ProgInfo where  prog_key = ' + rtrim(str(@ProgramKey)) + ')' +
' when 10 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from CaseInfo where case_key = ' + rtrim(str(@CaseKey)) + ')' +
' when 23 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from RprtInfo where rport_key = ' + rtrim(str(@RportKey)) + ')' +
' when 27 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from ProgInfo where prog_key = ' + rtrim(str(@ProgramKey)) + ')' +
' when 30 then (select replace(TaskDescription,''{0}'',ltrim(rtrim(longname))) from CaseInfo where case_key = ' + rtrim(str(@CaseKey)) + ')' + 
' when 31 then substring(TaskDescription,1,len(TaskDescription)-3) + ' +
    ' case isNull(t.PportKey, 0)' +
        ' when 0 then (select ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) from progInfo r, account a where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey)' + 
        ' else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(accountName)) from pprtinfo p, account a where pport_key = PportKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey) end' +
' when 32 then substring(TaskDescription,1,len(TaskDescription)-3) + ' +    
    ' case isNull(t.PportKey, 0)' + 
        ' when 0 then (select  ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) +  ''->'' + ltrim(rtrim(policyName))from progInfo r, (account a join policy pcy on a.accountKey = pcy.accountKey and a.exposureKey = pcy.exposureKey) where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey and pcy.policyKey =t.PolicyKey )' +
        ' else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(a.accountName)) + ''->'' + ltrim(rtrim(pcy.policyName))  from pprtinfo p, (account a join policy pcy on a.accountKey = pcy.accountKey and a.exposureKey = pcy.exposureKey) where pport_key = t.pportKey and a.accountKey=t.accountKey and a.exposureKey=t.exposureKey and pcy.policyKey = t.policyKey) end' +
' when 33 then substring(TaskDescription,1,len(TaskDescription)-3) + ' + 
    ' case isNull(t.PportKey, 0)' + 
        ' when 0 then (select ltrim(rtrim(r.longname)) + ''->'' + ltrim(rtrim(accountName)) +  ''->'' + ltrim(rtrim(siteName)) from progInfo r, (account a join site st on a.accountKey = st.accountKey and a.exposureKey = st.exposureKey) where prog_key = t.ProgramKey and a.accountKey=t.AccountKey and a.exposureKey = t.exposureKey and st.siteKey =t.siteKey)' + 
        ' else (select  ltrim(rtrim(p.longname)) + ''->'' + ltrim(rtrim(a.accountName)) + ''->'' + ltrim(rtrim(st.siteName))  from pprtinfo p, (account a join site st on a.accountKey = st.accountKey and a.exposureKey = st.exposureKey) where pport_key = t.pportKey and a.accountKey=t.accountKey and a.exposureKey=t.exposureKey and st.siteKey = t.siteKey) end' + 
' else '' '' end TaskDetailDescription' + 
' from taskinfo t, TaskDef td where td.TaskTypeID = t.TaskTypeID and t.taskKey = ' +rtrim(str(@taskKey))

print @qry
execute(@qry)
end
End
