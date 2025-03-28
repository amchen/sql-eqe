if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckIfCLREnabled') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckIfCLREnabled;
end
go

create procedure absp_Util_CheckIfCLREnabled
/*
====================================================================================================
Purpose:		This procedure checks if CLR option is enabled or not in the database.
Returns:        Returns 1 if is enabled, 0 if is disabled.
====================================================================================================
*/
as
begin

	set nocount on;

	declare @run_value int;
	declare @retString varchar(200);

	set @run_value = 0;

	-- check if clr is enabled
	select @run_value = convert(int, isnull(value, value_in_use))
		from  sys.configurations
		where name = 'clr enabled';

	-- check if RQECLR component is installed
	if (@run_value = 1)
	begin
		if not exists (select 1 from systemdb.sys.objects where type_desc like '%function' and name = 'clr_Util_GetError')
		begin
			set @run_value = 0;
		end
		else
		begin
			set @retString = systemdb.dbo.clr_Util_GetError(0);
			print @retString;
		end
	end

	--resultset required by hibernate
	select @run_value;
	return @run_value;
end
