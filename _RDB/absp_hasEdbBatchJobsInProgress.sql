if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_hasEdbBatchJobsInProgress') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_hasEdbBatchJobsInProgress;
end
go

create procedure absp_hasEdbBatchJobsInProgress
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:   Check if the RDB database has any EDB active jobs (R,W,WL,PS,PP,CP,RW,RS,X)
	      
Returns:   0 or 1 (1 = has active EDB batch jobs)
====================================================================================================
</pre>
</font>
##BD_END
*/

begin
	set nocount on;
	declare @srcNodeKey int
	declare @srcNodeType int
	declare @dbRefKey int
	declare @hasBatchJob int
	
	set @hasBatchJob = 0
	if not exists(select 1 from sys.tables where name='RDBInfo')
	begin
		select @hasBatchJob
		return
	end
	
	declare rdbInfoCurs cursor fast_forward for
	select sourceNodeKey, sourceNodeType, Cf_Ref_Key from RdbInfo ri inner join commondb..CFldrInfo cf on cf.LongName=sourceDatabaseName where NodeType > 101 and ri.Attrib=0

	open rdbInfoCurs;
	fetch next from rdbInfoCurs into @srcNodeKey, @srcNodeType, @dbRefKey;
	while @@fetch_status = 0
	begin
	    if @srcNodeType = 1 and exists(select 1 from commondb..BatchJob where DBRefKey=@dbRefKey and AportKey=@srcNodeKey and NodeType=@srcNodeType and Status in('R', 'W', 'WL','PS','PP','CP','CR','RS','RW','X'))
		begin
			set @hasBatchJob = 1
			break
		end
		
	    else if @srcNodeType = 2 and exists(select 1 from commondb..BatchJob where DBRefKey=@dbRefKey and PportKey=@srcNodeKey and NodeType=@srcNodeType and Status in('R', 'W', 'WL','PS','PP','CP','CR','RS','RW','X'))
		begin
			set @hasBatchJob = 1
			break
		end	
		
		else if @srcNodeType = 23 and exists(select 1 from commondb..BatchJob where DBRefKey=@dbRefKey and RportKey=@srcNodeKey and NodeType=@srcNodeType and Status in('R', 'W', 'WL','PS','PP','CP','CR','RS','RW','X'))
		begin
			set @hasBatchJob = 1
			break
		end				

		fetch next from rdbInfoCurs into @srcNodeKey, @srcNodeType, @dbRefKey;
	end
	close rdbInfoCurs;
	deallocate rdbInfoCurs;
	
	select @hasBatchJob
end
