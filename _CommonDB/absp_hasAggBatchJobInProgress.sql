if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_hasAggBatchJobInProgress') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_hasAggBatchJobInProgress
end
go
 
create procedure absp_hasAggBatchJobInProgress @dbRefKey int, @nodeKey integer, @nodeType integer, @isRunning int = 0
as
BEGIN
	
	declare @hasBatched int;
	set @hasBatched = 0;
	-- verify if the current node is a child input source of an aggregation job in progress in waiting or running mode(isRunning =1)
	-- the child could be an aggregation node too
	if @nodeType = 102 or @nodeType = 103
	begin
	    if @isRunning = 1
			select @hasBatched = count(*) from AggBatchJob join Batchjob on AggBatchJob.BatchJobKey = BatchJob.BatchJobKey where ChildDbRefKey = @dbRefKey and ChildRdbInfoKey = @NodeKey and BatchJob.status in ('R','PS','CP','RS')
		else
		    select @hasBatched = count(*) from AggBatchJob where ChildDbRefKey = @dbRefKey and ChildRdbInfoKey = @NodeKey
	end
	-- verify if the aggregation node has it self as a job in progress 
	if @hasBatched =0 and @nodeType = 103
	begin
		if @isRunning = 1
			select @hasBatched = count(*) from AggBatchJob join Batchjob on AggBatchJob.BatchJobKey = BatchJob.BatchJobKey where ParentDbRefKey = @dbRefKey and ParentRdbInfoKey = @NodeKey and BatchJob.status in ('R','PS','CP','RS')
		else
			select @hasBatched = count(*) from AggBatchJob where ParentDbRefKey = @dbRefKey and ParentRdbInfoKey = @NodeKey
	end

	-- for rdb database node type (101), just check if any jobs waiting or in progress 
	if @hasBatched = 0 and @nodeType = 101
	begin
		select @hasBatched = count(*) from AggBatchJob where ParentDbRefKey = @dbRefKey 
	end

	if(@hasBatched is null) set @hasBatched = 0
	select @hasBatched

END

