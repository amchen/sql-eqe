if exists (select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_ShowWaitTypes') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_ShowWaitTypes;
end
go

create procedure absp_QA_ShowWaitTypes

/*
====================================================================================================
Source:  http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
Returns: Result set of wait types.
====================================================================================================

Summary of wait types:

ASYNC_NETWORK_IO:    the classic cause of this wait type is RBAR (Row-By-Agonizing-Row) processing of results in a client,
                     instead of caching the results client-side and telling SQL Server to send more.
                     A common misconception is that this wait type is usually caused by network problems, that is rarely the case in my experience.
CXPACKET:            this wait type always accrues when parallelism happens, as the control thread in a parallel operation waits until all threads have completed.
                     However, when parallel threads are given unbalanced amounts of work to do, the threads that finish early also accrue this wait type,
                     leading to it maybe becoming the most prevalent. So this one could be benign, as the workload has lots of good parallelism,
                     but could be malignant if there is unwanted parallelism or problems causing skewed distribution of work among parallel threads.
LCK_M_IX:            this wait type occurs when a thread is waiting for a table or page IX lock so that a row insert or update can occur.
                     It could be from lock escalation to a table X or S lock causing all other threads to wait to be able to insert/update.
LCK_M_X:             this wait type commonly occurs when lock escalation is happening. It could also be caused by using a restrictive isolation level like
                     REPEATABLE_READ or SERIALIZABLE that requires S and IS locks to be held until the end of a transaction.
                     Note that distributed transactions change the isolation level to SERIALIZABLE under the covers, something that has bitten several of our clients before we helped them.
                     Someone could also have inhibited row locks on a clustered index causing all inserts to acquire page X locks, this is very uncommon though.
PAGEIOLATCH_SH:      this wait type occurs when a thread is waiting for a data file page to be read into memory.
                     Common causes of this wait being the most prevalent are when the workload does not fit in memory and the buffer pool has to keep evicting pages and reading others in from disk,
                     or when query plans are using table scans instead of index seeks, or when the buffer pool is under memory pressure which reduces the amount of space available for data.
PAGELATCH_EX:        the two classic causes of this wait type are tempdb allocation bitmap contention (from lots of concurrent threads creating and dropping temp tables
                     combined with a small number of tempdb files and not having TF1118 enabled) and an insert hotspot (from lots of concurrent threads inserting small rows
                     into a clustered index with an identity value, leading to contention on the index leaf-level pages). There are plenty of other causes of this wait type too,
                     but none that would commonly lead to it being the leading wait type over the course of a week.
SOS_SCHEDULER_YIELD: the most common cause of this wait type is that the workload is memory resident and there is no contention for resources, so threads are able to repeatedly
                     exhaust their scheduling quanta (4ms), registering SOS_SCHEDULER_YIELD when they voluntarily yield the processor. An example would be scanning through a
                     large number of pages in an index. This may or may not be a good thing.
WRITELOG:            this wait type is common to see in the first few top waits on servers as the transaction log is often one of the chief bottlenecks on a busy server.
                     This could be caused by the I/O subsystem not being able to keep up with the rate of log flushing combined with lots of tiny transactions forcing frequent flushes of minimal-sized log blocks.
*/

as
begin

    set nocount on;

	WITH [Waits] AS
		(SELECT
			[wait_type],
			[wait_time_ms] / 1000.0 AS [WaitS],
			([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
			[signal_wait_time_ms] / 1000.0 AS [SignalS],
			[waiting_tasks_count] AS [WaitCount],
			100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
			ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM sys.dm_os_wait_stats
		WHERE [wait_type] NOT IN (
			N'BROKER_EVENTHANDLER',         N'BROKER_RECEIVE_WAITFOR',
			N'BROKER_TASK_STOP',            N'BROKER_TO_FLUSH',
			N'BROKER_TRANSMITTER',          N'CHECKPOINT_QUEUE',
			N'CHKPT',                       N'CLR_AUTO_EVENT',
			N'CLR_MANUAL_EVENT',            N'CLR_SEMAPHORE',
			N'DBMIRROR_DBM_EVENT',          N'DBMIRROR_EVENTS_QUEUE',
			N'DBMIRROR_WORKER_QUEUE',       N'DBMIRRORING_CMD',
			N'DIRTY_PAGE_POLL',             N'DISPATCHER_QUEUE_SEMAPHORE',
			N'EXECSYNC',                    N'FSAGENT',
			N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
			N'HADR_CLUSAPI_CALL',           N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
			N'HADR_LOGCAPTURE_WAIT',        N'HADR_NOTIFICATION_DEQUEUE',
			N'HADR_TIMER_TASK',             N'HADR_WORK_QUEUE',
			N'KSOURCE_WAKEUP',              N'LAZYWRITER_SLEEP',
			N'LOGMGR_QUEUE',                N'ONDEMAND_TASK_QUEUE',
			N'PWAIT_ALL_COMPONENTS_INITIALIZED',
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
			N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
			N'SERVER_IDLE_CHECK',           N'SLEEP_BPOOL_FLUSH',
			N'SLEEP_DBSTARTUP',             N'SLEEP_DCOMSTARTUP',
			N'SLEEP_MASTERDBREADY',         N'SLEEP_MASTERMDREADY',
			N'SLEEP_MASTERUPGRADED',        N'SLEEP_MSDBSTARTUP',
			N'SLEEP_SYSTEMTASK',            N'SLEEP_TASK',
			N'SLEEP_TEMPDBSTARTUP',         N'SNI_HTTP_ACCEPT',
			N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
			N'SQLTRACE_WAIT_ENTRIES',       N'WAIT_FOR_RESULTS',
			N'WAITFOR',                     N'WAITFOR_TASKSHUTDOWN',
			N'WAIT_XTP_HOST_WAIT',          N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
			N'WAIT_XTP_CKPT_CLOSE',         N'XE_DISPATCHER_JOIN',
			N'XE_DISPATCHER_WAIT',          N'XE_TIMER_EVENT')
		)
	SELECT
		[W1].[wait_type] AS [WaitType],
		CAST ([W1].[WaitS] AS DECIMAL (16, 2)) AS [Wait_S],
		CAST ([W1].[ResourceS] AS DECIMAL (16, 2)) AS [Resource_S],
		CAST ([W1].[SignalS] AS DECIMAL (16, 2)) AS [Signal_S],
		[W1].[WaitCount] AS [WaitCount],
		CAST ([W1].[Percentage] AS DECIMAL (5, 2)) AS [Percentage],
		CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgWait_S],
		CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgRes_S],
		CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgSig_S]
	FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2]
		ON [W2].[RowNum] <= [W1].[RowNum]
	GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS],
		[W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
	HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; -- percentage threshold

end
