if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreatesystemdbViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreatesystemdbViews;
end

go
create procedure absp_Util_CreatesystemdbViews
/*
====================================================================================================
Purpose:
	This procedure creates views of system tables for the caller database in multi-user currency dbatabase
	Returns:	None
====================================================================================================
*/
AS
begin
	set nocount on;

	-- create views
	exec absp_Util_CreateGenericViews 'systemdb';

end
