if exists ( select 1 from  sysobjects  where id = object_id   ( N'dbo.absp_executeCleanupQueries' ) and  objectproperty ( ID , N'IsProcedure' ) = 1)
begin
    drop procedure dbo.absp_executeCleanupQueries;
end
go

create procedure [dbo].[absp_executeCleanupQueries]
	@batchJobKey int
as
begin

	set nocount on;
	declare @debug int;
	declare @tmpIDBName varchar(130);

	set @debug = 0;

	--Return if database is detached or offline
	if not exists (select 1 from  commondb..BatchJob where BatchJobKey = @batchJobKey and ((DBName='') or (DBName in
		(SELECT name collate SQL_Latin1_General_CP1_CI_AS FROM sys.databases where state_desc = 'online' collate SQL_Latin1_General_CP1_CI_AS ))))
	begin
		-- Return Dummy result to satify hibernate
		select '';
		return;
	end

	--Get TMP IDB Name
	select @tmpIDBName = TempIDBName from commondb..BatchJob where BatchJobKey = @batchJobKey;

	declare @count int;
	declare @EngineArgs varchar(max);
	declare @EngineGroupID int;
	declare @dbName varchar(120);
	declare @waitingStatusCount int;
	declare @successStatusCount int;
	declare @SQL varchar(max);

	create table #TMP (
		EngineGroupID int,
		Status varchar(50)
	);

	create table #SEQPLOUT_TMP (
		ID int identity(1,1),
		engargs varchar(max),
		grpId int,
		dbName varchar(120)
	);

	-- Fix for Prerequisite Job to execute cleanup for ONLY failed job
	if exists (select 1 from commondb..BatchJob where BatchJobKey = @batchJobKey and JobTypeID = 50)
		insert #TMP (EngineGroupId, Status) SELECT EngineGroupId, Status FROM commondb..BatchJobStep where BatchJobKey = @batchJobKey and Status = 'F' group by EngineGroupId, Status;
	else
		insert #TMP (EngineGroupId, Status) SELECT EngineGroupId, Status FROM commondb..BatchJobStep where BatchJobKey = @batchJobKey group by EngineGroupId, Status;

	insert into #SEQPLOUT_TMP (engargs, grpId, dbName)
		select SeqPlOut. eng_args, group_id, dbName from SeqPlOut
			where group_Id in
				(select distinct EngineGroupId from #TMP
					where EngineGroupId in (select EngineGroupId from #TMP a where status = 'S' and not 'S' = ALL
					(select Status from #TMP b where a.EngineGroupId = b.EngineGroupId))
				or EngineGroupId in (select EngineGroupId from #TMP a where status = 'W' and not 'W' = ALL
					(select Status from #TMP b where a.EngineGroupId = b.EngineGroupId))
				or EngineGroupId in (select EngineGroupId from #TMP where status in ('F','C')))
			and BatchJobKey = @batchJobKey and (dbName <> @tmpIDBName or @tmpIDBName = '') and eng_name = 'CLEANUP';

	DECLARE DBcursor CURSOR FOR
		select engargs, grpId, dbName from #SEQPLOUT_TMP;

	OPEN DBcursor;
	FETCH FROM DBcursor	INTO @EngineArgs, @EngineGroupID, @dbName;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@EngineArgs <> '' and @EngineArgs is not null)
		Begin
			SET @SQL = @EngineArgs;

			if @debug = 1 print ' EngineArgs:    ' + @EngineArgs;
			if @debug = 1 print ' EngineGroupID: ' + cast(@EngineGroupID as varchar(20));

			if (@dbName <> '' and @dbName is not null)
				set @SQL = 'USE [' + @dbName + '] ' + @SQL;

			if @debug = 1 print ' QueryString: ' + @SQL;
			exec(@SQL);
		end

		FETCH FROM DBcursor	INTO @EngineArgs, @EngineGroupID, @dbName;
	END
	CLOSE DBcursor;
	DEALLOCATE DBcursor;

	-- Return Dummy result to satify hibernate
	select '';
end
