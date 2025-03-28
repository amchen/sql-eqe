IF exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_TranslatorCleanup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TranslatorCleanup;
end
go

print 'Loading: absp_TranslatorCleanup';
go

create procedure absp_TranslatorCleanup @exposureKey int, @cleanupStep int = 0
as
begin
    print 'TODO: Finish absp_TranslatorCleanup';

	declare @schemaName varchar(max);

	-- Clean Schema
	set @schemaName=dbo.absp_Util_GetSchemaName (@exposureKey);
	execute absp_Util_CleanupSchema @schemaName;
end
