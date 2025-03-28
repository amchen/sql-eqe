if exists(select * from sysobjects where id = object_id(N'absp_QA_MostCalledProcs') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_MostCalledProcs
end

go
create procedure absp_QA_MostCalledProcs
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure returns a list of 100 stored procedures which are being called the most often.

Returns:       It returns nothing.  

====================================================================================================
</pre>
</font>
##BD_END
*/

as
begin
    -- Get Top 100 executed SP's ordered by execution count
       SELECT TOP 100 qt.text AS 'SP Name', qs.execution_count AS 'Execution Count',  
       qs.execution_count/DATEDIFF(Second, qs.creation_time, GetDate()) AS 'Calls/Second',
       qs.total_worker_time/qs.execution_count AS 'AvgWorkerTime',
       qs.total_worker_time AS 'TotalWorkerTime',
       qs.total_elapsed_time/qs.execution_count AS 'AvgElapsedTime',
       qs.max_logical_reads, qs.max_logical_writes, qs.total_physical_reads, 
       DATEDIFF(Minute, qs.creation_time, GetDate()) AS 'Age in Cache'
       FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       WHERE qt.dbid = db_id() -- Filter by current database
    ORDER BY qs.execution_count DESC
end



