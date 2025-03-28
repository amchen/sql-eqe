use commondb;
if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_QA_SeqPlOutTrigger') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_QA_SeqPlOutTrigger;
end
go

create procedure dbo.absp_QA_SeqPlOutTrigger
as
BEGIN
	declare @sql varchar(max);

	--create the table
	if exists (select 1 from sysobjects where id = object_id('SeqPlOutClone') and type = 'U') drop table SeqPlOutClone;

	CREATE TABLE SeqPlOutClone (
		SeqPln_Key INTEGER NOT NULL DEFAULT 0,
		Estim_Time INTEGER NOT NULL DEFAULT 0,
		Eng_Name VARCHAR (120) DEFAULT '',
		Priority VARCHAR (2) DEFAULT '',
		Eng_Args VARCHAR (MAX) DEFAULT '',
		Seq_ID SMALLINT NOT NULL DEFAULT 0,
		AnlCfg_Key INTEGER NOT NULL DEFAULT 0,
		Err_Msg VARCHAR (254) DEFAULT '',
		Group_ID INTEGER NOT NULL DEFAULT 0,
		BatchJobKey INTEGER NOT NULL DEFAULT 0,
		BatchJobStepKey INTEGER NOT NULL DEFAULT 0,
		DBName VARCHAR (120) DEFAULT '',
		CleanupDBType VARCHAR (10) NOT NULL DEFAULT ''
	);

	if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_insert_of_SeqPlOut_insert_SeqPlOutClone') and objectproperty(id,N'IsTrigger') = 1) drop trigger On_insert_of_SeqPlOut_insert_SeqPlOutClone;

	--create the trigger to clone the SeqPlOut table
	set @sql=
	'create trigger On_insert_of_SeqPlOut_insert_SeqPlOutClone on dbo.SeqPlOut
	after insert,update
	as
	insert SeqPlOutClone (SeqPln_Key,Estim_Time,Eng_Name,Priority,Eng_Args,Seq_ID,AnlCfg_Key,Err_Msg,Group_ID,BatchJobKey,BatchJobStepKey,DBName,CleanupDBType)
		select SeqPln_Key,Estim_Time,Eng_Name,Priority,Eng_Args,Seq_ID,AnlCfg_Key,Err_Msg,Group_ID,BatchJobKey,BatchJobStepKey,DBName,CleanupDBType
		from SeqPlOut';
	execute (@sql);

	print 'absp_QA_SeqPlOutTrigger is active!'
	print '----------------------------------'
	print 'select * from SeqPlOut'
	print 'select * from SeqPlOutClone'

END
go
/*Testing
--execute absp_QA_SeqPlOutTrigger
--insert into SeqPlOut
--select * from SeqPlOutClone
*/
