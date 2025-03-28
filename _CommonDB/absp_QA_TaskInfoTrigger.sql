use commondb;
if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_QA_TaskInfoTrigger') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_QA_TaskInfoTrigger;
end
go

create procedure dbo.absp_QA_TaskInfoTrigger
as
BEGIN
	declare @sql varchar(max);

	--create the table
	if exists (select 1 from sysobjects where id = object_id('TaskInfoClone') and type = 'U') drop table TaskInfoClone;

	CREATE TABLE TaskInfoClone (
		TaskKey INTEGER NOT NULL DEFAULT 0,
		TaskTypeID INTEGER NOT NULL DEFAULT 0,
		UserKey INTEGER NOT NULL DEFAULT 0,
		SessionID INTEGER NOT NULL DEFAULT 0,
		NodeType INTEGER NOT NULL DEFAULT 0,
		DBRefKey INTEGER NOT NULL DEFAULT 0,
		FolderKey INTEGER NOT NULL DEFAULT 0,
		AportKey INTEGER NOT NULL DEFAULT 0,
		PportKey INTEGER NOT NULL DEFAULT 0,
		ExposureKey INTEGER NOT NULL DEFAULT 0,
		AccountKey INTEGER NOT NULL DEFAULT 0,
		PolicyKey INTEGER NOT NULL DEFAULT 0,
		SiteKey INTEGER NOT NULL DEFAULT 0,
		RportKey INTEGER NOT NULL DEFAULT 0,
		ProgramKey INTEGER NOT NULL DEFAULT 0,
		CaseKey INTEGER NOT NULL DEFAULT 0,
		StartDate VARCHAR (14) DEFAULT '',
		Status VARCHAR (20) DEFAULT '',
		TaskOptions VARCHAR (MAX) DEFAULT '',
		TaskDetailDescription VARCHAR (MAX) DEFAULT '',
		TaskDBProcessID INTEGER NOT NULL DEFAULT 0,
		TaskTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

	if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_insert_of_TaskInfo_insert_TaskInfoClone') and objectproperty(id,N'IsTrigger') = 1) drop trigger On_insert_of_TaskInfo_insert_TaskInfoClone;

	--create the trigger to clone the TaskInfo table
	set @sql=
	'create trigger On_insert_of_TaskInfo_insert_TaskInfoClone on dbo.TaskInfo
	after insert,update
	as
	insert TaskInfoClone (TaskKey,TaskTypeID,UserKey,SessionID,NodeType,DBRefKey,FolderKey,AportKey,PportKey,ExposureKey,AccountKey,PolicyKey,SiteKey,RportKey,ProgramKey,CaseKey,StartDate,[Status],TaskOptions,TaskDetailDescription,TaskDBProcessID)
		select TaskKey,TaskTypeID,UserKey,SessionID,NodeType,DBRefKey,FolderKey,AportKey,PportKey,ExposureKey,AccountKey,PolicyKey,SiteKey,RportKey,ProgramKey,CaseKey,StartDate,[Status],TaskOptions,TaskDetailDescription,TaskDBProcessID
		from TaskInfo';
	execute (@sql);

	print 'absp_QA_TaskInfoTrigger is active!'
	print '----------------------------------'
	print 'select * from TaskInfo'
	print 'select * from TaskInfoClone'
		
END
go
/*Testing
--execute absp_QA_TaskInfoTrigger
--insert into TaskInfo (TaskTypeID,UserKey) values (1,1)
--select * from TaskInfoClone
*/
