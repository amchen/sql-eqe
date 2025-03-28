if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDependencyKeyForImport') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDependencyKeyForImport;
end
go

create procedure absp_GetDependencyKeyForImport
	@nodeKey int, @nodeType int

AS
      BEGIN
		set nocount on;
		declare @dependencyKey int;
		declare @dbName varchar (max);
		set @dependencyKey = 0;
		set @dbName =DB_NAME();

        SET TRANSACTION  ISOLATION  LEVEL  READ  UNCOMMITTED;

        BEGIN TRAN  --you are changing isoloation level from default read commited to read uncommited
		if (@nodeType = 2)
			select top 1 @dependencyKey =  batchjobkey  from batchjob where pportkey = @nodeKey and jobtypeid = 22 and dbname = @dbName and status in ('R', 'W', 'X') order by joborder desc
		else if (@nodeType = 27)
			select top 1 @dependencyKey =  batchjobkey  from batchjob where programKey = @nodeKey and jobtypeid = 22  and dbname = @dbName and status in ('R', 'W', 'X') order by joborder desc
        COMMIT TRAN  --back to default isolation level

		select @dependencyKey as dependencyReportKey;

      END
