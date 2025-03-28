IF exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_ImportLoaderCleanup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ImportLoaderCleanup;
end
go

print 'Loading: absp_ImportLoaderCleanup'
go

create procedure absp_ImportLoaderCleanup @exposureKey int, @cleanupStep int = 0
as
begin
    print 'TODO: Finish absp_ImportLoaderCleanup';

	declare @schemaName varchar(max);

	-- Clean Schema
	set @schemaName=dbo.absp_Util_GetSchemaName (@exposureKey);
	execute absp_Util_CleanupSchema @schemaName;
end
