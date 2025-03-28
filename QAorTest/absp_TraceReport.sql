if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TraceReport') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TraceReport
end
go

create procedure 
absp_TraceReport @traceTable varchar(100)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

This procedure correlates the trace data into a report similar to ASA profiler.

Returns:       It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  progKey ^^  The key of the program node for which the log information is to be deleted. 
*/
as
begin
	declare @proc_name varchar(255)
	declare @msecs int
	declare @sql nvarchar(4000)

	-- turn off rowcount message
	set nocount on

	-- create our temp tables with indexes
	create table #TMPTRACE1 (procname varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS, msecs int)
	create index TMPTRACE1_IDX on #TMPTRACE1 (procname)

	create table #TMPTRACE2 (procname varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS, linenumber int, msecs int)
	create index TMPTRACE2_IDX on #TMPTRACE2 (procname, linenumber)

	create table #TMPTRACE3 (id int identity(1,1) primary key, procname varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS, linenumber int, msecs int, pct float(24), linetext varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS)
	--create index TMPTRACE3_IDX on #TMPTRACE3 (procname, linenumber, msecs)

	create table #TMPTRACE4 (id int identity(1,1) primary key, procname varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS, linenumber int, msecs int, pct float(24), linetext varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS)
	--create index TMPTRACE4_IDX on #TMPTRACE4 (procname, linenumber, msecs)

	-- declare cursors
	declare trace_curs1 cursor FAST_FORWARD for
		select procname, msecs from #TMPTRACE1 where procname is not null order by 2 desc

	-- populate our temp tables
	set @sql = 'insert #TMPTRACE1 select objectname, sum(cpu) from ' + @traceTable +
	           ' where cpu > 0 group by objectname order by 2 desc'
	execute (@sql)
	set @sql = 'insert #TMPTRACE2 select objectname, linenumber, sum(cpu) from ' + @traceTable +
	           ' where cpu > 0 group by objectname, linenumber order by 3 desc'
	execute (@sql)

	open trace_curs1
	fetch next from trace_curs1 into @proc_name, @msecs
	while @@fetch_status = 0
	begin
		insert #TMPTRACE4 (procname, linenumber, msecs, pct, linetext)
			values (@proc_name, 0, @msecs, 0, '')
		truncate table #TMPTRACE3
		insert #TMPTRACE3 (procname, linenumber, msecs, pct, linetext)
			select '', tmp.linenumber, tmp.msecs, (tmp.msecs * 100.0 / @msecs) as pct, trace.textdata as linetext
				from #TMPTRACE2 tmp
				join tvclone5 trace on tmp.procname = trace.objectname
				 and tmp.linenumber = trace.linenumber
				where tmp.procname = @proc_name
				order by tmp.linenumber asc

		insert #TMPTRACE4 (procname, linenumber, msecs, pct, linetext)
			select distinct '' as procname, linenumber, msecs, pct, linetext
				from #TMPTRACE3
				order by linenumber asc
		fetch next from trace_curs1 into @proc_name, @msecs
	end
	close trace_curs1
	deallocate trace_curs1

	select * from #TMPTRACE4 order by id asc
	
	drop table #TMPTRACE1
	drop table #TMPTRACE2
	drop table #TMPTRACE3
	drop table #TMPTRACE4
	
end
