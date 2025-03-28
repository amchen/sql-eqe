if Exists(select 1 from SysObjects where Name = 'absp_dropBackupEvent' And Type = 'P')
begin
	drop procedure absp_dropBackupEvent
end

GO

create procedure absp_dropBackupEvent
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:		MSSQL
Purpose:		This Procedure deletes Job absev_BackupDataBase

Returns:		Nothing
====================================================================================================

</pre>
</font>
##BD_END
*/
AS
begin


-- we no longer have SQL Agent Jobs, just return
return


   set nocount on

	begin Try
		if exists(select 1 from msdb.dbo.SysJobs where NAME = 'absev_BackupDataBase')
			begin
				exec msdb.dbo.sp_delete_job @job_name = N'absev_BackupDataBase'
			end
	end Try

	begin Catch
			select Error_Number() as Error_Number, Error_Message() as Error_Message
	end Catch
end
