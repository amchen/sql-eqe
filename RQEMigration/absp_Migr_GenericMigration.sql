if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_GenericMigration') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_GenericMigration;
end
go

create  procedure absp_Migr_GenericMigration
as
/*
====================================================================================================
Purpose:	This procedure is executed by a background thread and will process Special Migration in the background.
Returns:	Nothing
====================================================================================================
*/
begin try

	set nocount on;

	declare @msg varchar(max);
	declare @me varchar(100);

	set @me = 'absp_Migr_GenericMigration: ';

	set @msg = @me + 'Starting...';
	exec absp_MessageEx @msg;

	if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_MigrateLookupID') and objectproperty(id,N'IsProcedure') = 1)
	begin
		set @msg = @me + 'exec absp_Migr_MigrateLookupID 0, 0, 0;';
		exec absp_MessageEx @msg;
		exec absp_Migr_MigrateLookupID 0, 0, 0;
	end

	set @msg = @me + 'Done';
	exec absp_MessageEx @msg;

end try

-- Catch all exceptions since this is run by the background thread
begin catch

end catch
