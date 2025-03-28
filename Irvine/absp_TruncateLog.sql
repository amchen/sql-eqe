if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TruncateLog') and objectproperty(id,N'IsProcedure') = 1)
begin
    drop procedure absp_TruncateLog
end
go

create procedure absp_TruncateLog @logSizeThreshold int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

    This procedure will check the log size of all the databases connected to WCe and
    if the log size exceeds the given threshold then the transaction log will get truncated.
    We use Simple Recovery Model for SQL Server and we can truncate the transaction log on-the-fly
    since we cannot backup transaction logs.

Returns:    None

====================================================================================================
</pre>
</font>
##BD_END

##PD  @logSizeThreshold ^^  The maximum allowed size of a log file before we truncate it (in GB)
*/
AS

-- This procedure is implemented to fix Mantis Defect: 1167.
begin

    declare @sql    varchar(max)
    declare @dbName varchar(255)

    SET NOCOUNT ON

    CREATE TABLE #TMP_LOG_STAT
    (
        databaseName sysname COLLATE SQL_Latin1_General_CP1_CI_AS ,
        logSize      decimal(18,5),
        logUsed      decimal(18,5),
        status       int
    )

    -- Get the stat for all the databases connected to the server.
    INSERT INTO #TMP_LOG_STAT EXEC absp_Util_SQLPerf

    -- Create a temp table with the list of all the databases (both Primary and IR)

    select distinct DB_NAME into #DBNAME from CFLDRINFO

    -- Now since the databases in #DBNAME is connect to WCe we can assume they all have corresponding IR databases.
    insert into #DBNAME select distinct DB_NAME + '_IR'  from CFLDRINFO

    -- Now filter out the ones that are not associated with our Application
    delete from #TMP_LOG_STAT where databaseName not in (select distinct DB_NAME from #DBNAME)

    -- Now delete the ones that did not exceed the threshold
    -- The threhold is in GB so we need to convert it to MB
    delete from #TMP_LOG_STAT where logSize <= (@logSizeThreshold * 1024)

    -- Now we have the list of databases whose transaction logs needs to be truncated.
    declare curs1  cursor fast_forward  for
    select rtrim(databaseName) from #TMP_LOG_STAT
    open curs1
    fetch next from curs1 into @dbName
        while @@fetch_status = 0
        begin

            set @sql = 'USE [' + @dbName + ']; CHECKPOINT; DBCC SHRINKFILE(2, 2, TRUNCATEONLY) WITH NO_INFOMSGS;';
            print @sql;
            execute(@sql);

            fetch next from curs1 into @dbName
        end
    close curs1
    deallocate curs1

    -- Cleanup
    DROP TABLE #DBNAME
    DROP TABLE #TMP_LOG_STAT
end
