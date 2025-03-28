
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CheckWaitingRunningFailedSteps') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckWaitingRunningFailedSteps;
end
go

create procedure absp_CheckWaitingRunningFailedSteps
	@batchJobKey int
	
AS 
      BEGIN 
		set nocount on;
		declare @hasJobStep int;
		set @hasJobStep = 0;
		
        SET TRANSACTION  ISOLATION  LEVEL  READ  UNCOMMITTED; 
        create table #Tmp (batchjobstepkey int) 
        BEGIN TRAN  --you are changing isoloation level from default read commited to read uncommited 
         
        insert into #Tmp select top 1 batchjobstepkey from commondb..BatchJobStep where status in ('R') and batchjobkey = @batchJobKey
		insert into #Tmp select top 1 batchjobstepkey from commondb..BatchJobStep where status in ('W') and batchjobkey = @batchJobKey
		insert into #Tmp select top 1 batchjobstepkey from commondb..BatchJobStep where status in ('F') and batchjobkey = @batchJobKey
		insert into #Tmp select top 1 batchjobstepkey from commondb..BatchJobStep where status in ('C') and batchjobkey = @batchJobKey and startdate <> '' order by batchjobstepkey desc
		
		COMMIT TRAN  --back to default isolation level 
		
		select * from commondb..BatchJobStep where BatchJobStepKey in (Select batchjobstepkey from #Tmp)
      END 