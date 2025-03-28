if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_SetDatabaseProperty') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_SetDatabaseProperty;
end
go

create procedure absp_Util_SetDatabaseProperty
	@propertyName varchar(248),
	@propertyValue varchar(248)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure sets the value of the database extended property.
         If the propertyValue is NULL, the extended property is deleted.

	This will Get the database property value
	exec absp_Util_GetDatabaseProperty 'IsNewRQEDatabase';

	This will Set the database property value to No
	exec absp_Util_SetDatabaseProperty 'IsNewRQEDatabase','No';

	This will Delete the database property value
	exec absp_Util_SetDatabaseProperty 'IsNewRQEDatabase',NULL;

Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END
##PD  @propertyName ^^ The name of the database extended property.
##PD  @propertyValue ^^ The value of the database extended property.
*/

begin
	set nocount on;

	if exists(select 1 from sys.extended_properties where class_desc='DATABASE' and name=@propertyName)
	begin
		if (@propertyValue is NULL)
		begin
			exec sp_dropextendedproperty @propertyName;
		end
		else
		begin
			exec sp_updateextendedproperty @propertyName, @propertyValue;
		end
	end
	else
	begin
		exec sp_addextendedproperty @propertyName, @propertyValue;
	end
end
