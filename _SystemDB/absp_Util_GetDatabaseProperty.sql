if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetDatabaseProperty') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_GetDatabaseProperty;
end
go

create procedure absp_Util_GetDatabaseProperty
	@propertyName varchar(248)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure gets the value of the database extended property.

	This will Get the database property value
	exec absp_Util_GetDatabaseProperty 'IsNewRQEDatabase';

	This will Set the database property value to No
	exec absp_Util_SetDatabaseProperty 'IsNewRQEDatabase','No';

	This will Delete the database property value
	exec absp_Util_SetDatabaseProperty 'IsNewRQEDatabase',NULL;

Returns: It returns the value of the database property if exists.
         NULL if the database property does not exists.
====================================================================================================
</pre>
</font>
##BD_END
##PD  @propertyName ^^ The name of the database extended property.
##RD  @retValue ^^ Returns the value of the database property.
*/

begin
	set nocount on;
	declare @retValue varchar(254);
	select @retValue=cast(value as varchar(254)) from fn_listextendedproperty(@propertyName, default, default, default, default, default, default);
	select @retValue as PropertyValue;
end
