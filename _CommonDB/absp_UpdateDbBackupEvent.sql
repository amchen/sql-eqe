if exists(select 1 from sysobjects where NAME = 'absp_UpdateDbBackupEvent' And Type = 'P')
begin
    drop procedure absp_UpdateDbBackupEvent
end
go

create procedure absp_UpdateDbBackupEvent
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This Procedure creates a Job, absev_BackupDatabase which calls procedure
                absp_BackupDatabase based on certain values from BKPROP table.

Returns:        Nothing
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

    begin try
        declare @stTime         char (255);
        declare @evryHours      char (255);
        declare @schDays        char (255);
        declare @stDate         char (255);
        declare @retVal         int;

        declare @add_Job        nVarchar (1000);    -- To Store Add Job Query --
        declare @add_Step       nVarchar (4000);    -- To Store Add Job Step Query --
        declare @add_Schedule   nVarchar (1000);    -- To Store Add Job Schedule Query --
        declare @jobId          nVarchar (1000);    -- To Store Job Id of created Job after data type conversion --

        set @retVal = 0;

        set @stTime = '08:00PM';
        select @stTime = bk_value from bkprop where  bk_key = 'StartTime';
        --print 'StartTime=' + @stTime ;

        set @evryHours = '24';
        select @evryHours = bk_value from bkprop where  bk_key = 'EveryHours';
        --print'EveryHours=' + @evryHours

        set @schDays ='''Mon'',''Tue'',''Wed'',''Thu'',''Fri'',''Sat'',''Sun''';

        select @schDays = bk_value  from bkprop where  bk_key = 'ScheduledDays';
        --print 'ScheduledDays=' + @schDays;

        set @stDate = getdate();
        --print 'StartDate=' + @stDate ;
        set @stDate = getdate();
        --//set @stDate = ''' + @stDate + ''';

        select @stDate = bk_value from bkprop where  bk_key = 'StartDate';
        --print 'StartDate=' + @stDate ;

        set @stDate = '''' + @stDate + '''';
        set @stTime = '''' + @stTime + '''';

        -- Add Job --
        set @add_Job =  'exec sp_add_job @job_name=N''absev_BackupDatabase'' ,' +
                        '@enabled=1, ' +
                        '@notify_level_eventlog=0, ' +
                        '@notify_level_email=0, ' +
                        '@notify_level_netsend=0, '  +
                        '@notify_level_page=0, ' +
                        '@delete_level=0, ' +
                        '@description=N''Calls a procedure to backup database '',' +
                        '@category_name=N''EQE Job'',' +
                        '@job_id = @jobId  OUTPUT '

        -- Add Job Step --
        set @add_Step = 'exec sp_add_jobstep @job_id=@jobId, @step_name=N''absev_BackupDatabase_JobStep'', ' +
                        '@step_id=1, '+
                        '@cmdexec_success_code=0, ' +
                        '@on_success_action=1, ' +
                        '@on_success_step_id=0, ' +
                        '@on_fail_action=2, ' +
                        '@on_fail_step_id=0, ' +
                        '@retry_attempts=0, ' +
                        '@retry_interval=0, ' +
                        '@os_run_priority=0, @subsystem=N''TSQL'', ' +
                        '@command=N''if (select count(*) from BKPROP where BK_KEY = ''''Migration'''') = 0 begin exec absp_BackupDatabase end'', ' +
                        '@database_name=N''master'', ' +
                        '@flags=0 '

        -- Add Job Schedule --
        set @add_Schedule = 'sp_add_schedule @schedule_name =  ''absev_BackupDatabase_JobSchedule'' , ' +
                            '@enabled=1, ' +
                            '@freq_type=4, ' +
                            '@freq_interval=1, ' +
                            '@freq_subday_type=8, ' +
                            '@freq_subday_interval=24,  ' +
                            '@freq_relative_interval=0, ' +
                            '@freq_recurrence_factor=0, ' +
                            '@active_start_date=20070101, ' +
                            '@active_end_date=99991231, ' +
                            '@active_start_time=1, ' +
                            '@active_end_time=235959'

        if exists(select 1 from msdb.dbo.sysjobs where upper(Name) = 'ABSEV_BACKUPDATABASE')
            begin
                execute msdb.dbo.sp_delete_job @job_name = N'absev_BackupDataBase'
                execute msdb.dbo.sp_executesql @add_Job,N'@jobId Varchar(1000) output ',@jobId output
                execute msdb.dbo.sp_executesql @add_Step,N'@jobId Varchar (1000) ',@jobId
                execute msdb.dbo.sp_executesql @add_Schedule

            end
        else
            begin
                execute msdb.dbo.sp_executesql @add_Job,N'@jobId Varchar(1000) output ',@jobId output
                execute msdb.dbo.sp_executesql @add_Step,N'@jobId Varchar (1000) ',@jobId
                execute msdb.dbo.sp_executesql @add_Schedule
            end

            execute msdb.dbo.sp_attach_schedule
                       @job_name = N'absev_BackupDataBase',
                       @schedule_name = N'absev_BackupDatabase_JobSchedule'

        return @retVal
    end try

    begin catch
        select Error_Message() As Error_Message, Error_Line() As Error_Line
    end catch

end
