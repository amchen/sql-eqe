IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[absp_Util_GetSchemaName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[absp_Util_GetSchemaName]
GO

CREATE FUNCTION absp_Util_GetSchemaName (@exposureKey int)
RETURNS varchar(30)
AS
BEGIN
	declare @schemaName varchar(30);
	if (@exposureKey < 1000)
		select @schemaName='exk'+RIGHT('00'+ CONVERT(VARCHAR(30),@exposureKey),3);
	else
		select @schemaName='exk'+CONVERT(VARCHAR(30),@exposureKey);

	return @schemaName;
END
/*
select dbo.absp_Util_GetSchemaName (10)
select dbo.absp_Util_GetSchemaName (100)
select dbo.absp_Util_GetSchemaName (1000)
select dbo.absp_Util_GetSchemaName (9999)
*/
