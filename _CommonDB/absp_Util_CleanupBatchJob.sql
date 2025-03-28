if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CleanupBatchJob') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CleanupBatchJob
end
go

create procedure absp_Util_CleanupBatchJob @dbName varchar(130), @dbRefKey int = 0
as
begin

	set nocount on;

	--Remove SEQPLOUT, BatchJob and BatchJobStep entries associated with this database--
	delete from commondb..SEQPLOUT where BatchJobKey in (select BatchJobKey from commondb..BatchJob where DBName=@dbName);

	delete from commondb..BatchJobStep where BatchJobKey in (select BatchJobKey from commondb..BatchJob where DBName=@dbName);

	delete from commondb..BatchProperties where BatchJobKey in (select BatchJobKey from commondb..BatchJob where DBName=@dbName);

	delete from commondb..BatchJob where DBName=@dbName;

	delete from commondb..SqlJobInfo where cf_ref_key = @dbRefKey;

	delete from commondb..TaskInfo where dbRefKey = @dbRefKey;

end
