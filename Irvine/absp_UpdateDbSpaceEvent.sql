if exists (select 1 from SysObjects where Name = 'absp_UpdateDbSpaceEvent' And Type = 'P')
begin
    drop procedure absp_UpdateDbSpaceEvent
end
go

create procedure absp_UpdateDbSpaceEvent
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This Procedure adds an alert absev_CheckDatabaseSpace_Alert1, which invokes a Job
                absev_CheckDatabaseSpace, when free database space for Eqe database falls below
                "CheckSpace.Threshold" BK_VALUE in BKPROP table. The job inturn calls procedure
                absp_CheckDbSpace.

Returns:No Value

====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin


-- we no longer have SQL Agent Jobs, just return
return


   set nocount on

    declare @threshold  varchar (20);
    declare @interval   varchar (20);
    declare @retVal     integer;

    declare @add_Job    nVarchar (1000);    -- To Store Add Job Query --
    declare @add_Step   nVarchar (4000);    -- To Store Add Job Step Query --
    declare @add_Alert  nVarchar (1000);    -- To Store Add Alert Query --
    declare @jobId      nVarchar (1000);    -- To Store Job Id of created Job after data type conversion --

    begin try

        set @retVal = 0;

        select @threshold = BK_VALUE from BKPROP where  BK_KEY = 'CheckSpace.Threshold';
        select @interval = BK_VALUE from BKPROP where  BK_KEY = 'CheckSpace.Interval';

        -- Add Job --
        set @add_Job =  'exec sp_add_job @job_name=N''absev_CheckDatabaseSpace'' ,' +
                        '@enabled=1, ' +
                        '@notify_level_eventlog=0, ' +
                        '@notify_level_email=0, ' +
                        '@notify_level_netsend=0, '  +
                        '@notify_level_page=0, ' +
                        '@delete_level=0, ' +
                        '@description=N''Check For Database space and accordingly raise an ALERT '',' +
                        '@category_name=N''EQE Job'',' +
                        '@job_id = @jobId  OUTPUT '

        -- Add Job Step --
        set @add_Step = 'exec sp_add_jobstep @job_id=@jobId, @step_name=N''absev_CheckDatabaseSpace_JobStep'', ' +
                        '@step_id=1, ' +
                        '@cmdexec_success_code=0, ' +
                        '@on_success_action=1, ' +
                        '@on_success_step_id=0, ' +
                        '@on_fail_action=2, ' +
                        '@on_fail_step_id=0, ' +
                        '@retry_attempts=0, ' +
                        '@retry_interval=0, ' +
                        '@os_run_priority=0, @subsystem=N''TSQL'', ' +
                        '@command=N''exec absp_CheckDbSpace '', ' +
                        '@database_name=N''eqe'', ' +
                        '@flags=0 '

        -- Add Alert --
        set @add_Alert ='exec sp_add_alert @name=N''absev_CheckDatabaseSpace_JobAlert'', ' +
                        '@message_id=0, ' +
                        '@severity=0, ' +
                        '@enabled=1, ' +
                        '@include_event_description_in=0, ' +
                        '@delay_between_responses = ' + @interval + ', ' +
                        '@performance_condition=N''SQLServer:Databases|Data File(s) Size (KB)|Eqe|<|' + @threshold + ''', ' +
                        '@job_name = ''absev_CheckDatabaseSpace'''


        -- Drop event absev_CheckDatabaseSpace --
        if exists(select 1 from msdb.dbo.sysjobs where NAME = 'absev_CheckDatabaseSpace')
            begin
                execute msdb.dbo.sp_delete_job @job_name = N'absev_CheckDatabaseSpace'
                execute msdb.dbo.sp_executesql @add_Job, N'@jobId Varchar(1000) output', @jobId output
                execute msdb.dbo.sp_executesql @add_Step, N'@jobId Varchar (1000)', @jobId
            end
        else
            begin
                execute msdb.dbo.sp_executesql @add_Job, N'@jobId Varchar(1000) output', @jobId output
                execute msdb.dbo.sp_executesql @add_Step, N'@jobId Varchar (1000)', @jobId
            end

        -- Add Alert Finally --
        if exists (select 1 from msdb.dbo.sysalerts where NAME = 'absev_CheckDatabaseSpace_JobAlert')
            begin
                execute msdb.dbo.sp_add_jobserver @job_name = N'absev_CheckDatabaseSpace'
                execute msdb.dbo.sp_delete_alert @name = N'absev_CheckDatabaseSpace_JobAlert'
                execute msdb.dbo.sp_executesql @add_Alert
            end
        else
            begin
                execute msdb.dbo.sp_add_jobserver @job_name = N'absev_CheckDatabaseSpace'
                execute msdb.dbo.sp_executesql @add_Alert
            end

        return @retVal
    end try

    begin catch
        select Error_Number(), Error_Message()
    end catch
end
