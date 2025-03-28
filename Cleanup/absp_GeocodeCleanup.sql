IF exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_GeocodeCleanup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GeocodeCleanup;
end
go

create procedure absp_GeocodeCleanup
	@exposureKey int,
	@cleanupStep int = 0
as
begin

	declare @schemaName varchar(max);

	-- Clean Schema
	set @schemaName = dbo.absp_Util_GetSchemaName (@exposureKey);
	execute absp_Util_CleanupSchema @schemaName;

	-- Set ExposureInfo.GeocodeStatus = 'Failed'
	update ExposureInfo set GeocodeStatus = 'Failed' where ExposureKey = @exposureKey;

end
