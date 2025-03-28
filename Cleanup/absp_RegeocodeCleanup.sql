IF exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_RegeocodeCleanup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_RegeocodeCleanup;
end
go

create procedure absp_RegeocodeCleanup
	@exposureKey int
as
begin
	declare @schemaName varchar(200);
	declare @schemaNameR varchar(200);

	-- Clean Schema
	set @schemaName = dbo.absp_Util_GetSchemaName(@exposureKey);
	set @schemaNameR = replace(@schemaName,'exk','exkR');
	exec absp_Util_CleanupSchema @schemaNameR;
end
