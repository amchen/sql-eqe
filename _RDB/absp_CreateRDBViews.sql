if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateRDBViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateRDBViews
end
go

create procedure absp_CreateRDBViews
AS

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:       This procedure creates views for the RDB database.
====================================================================================================
</pre>
</font>
##BD_END

*/

begin

   	set nocount on;

   	declare @tName    varchar(120);
	declare @sql      varchar(120);
	declare @nsql     nvarchar(max);
	declare @sysDB    char(1);
	declare @comDB    char(1);
	declare @sourceDB varchar(120);
	declare @dbType   varchar(3);

	select @dbType=DbType from RQEVersion where RQEVersionKey=1;

   	if (@dbType='RDB') begin

		create table #TABLELIST (TNAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS);
		insert into #TABLELIST values('AggBatchJob');
		insert into #TABLELIST values('BatchJob');
		insert into #TABLELIST values('BatchJobStep');
		insert into #TABLELIST values('BatchJobSettings');
		insert into #TABLELIST values('Mdl_Regn');
		insert into #TABLELIST values('NodeDef');
		insert into #TABLELIST values('ReportQuery');
		insert into #TABLELIST values('TaskInfo');
		insert into #TABLELIST values('ReportControl');
		insert into #TABLELIST values('ReportMapping');
		insert into #TABLELIST values('Message');
		insert into #TABLELIST values('UserInfo');
		insert into #TABLELIST values('JobDef');
		insert into #TABLELIST values('TemplateInfo');
		insert into #TABLELIST values('ELTMetricsDef');
		insert into #TABLELIST values('Engines');
		insert into #TABLELIST values('EngSet');
		insert into #TABLELIST values('Logs');
		insert into #TABLELIST values('EngineTiming');
		insert into #TABLELIST values('EngineTimingDetails');
		insert into #TABLELIST values('TrtyType');
		insert into #TABLELIST values('AttrDef');
		insert into #TABLELIST values('DownloadInfo');
		insert into #TABLELIST values('TaskStepInfo');
		insert into #TABLELIST values('TaskDef');
		insert into #TABLELIST values('TaskProgress');
		insert into #TABLELIST values('UserGrps');

		declare  c1 cursor for select * from #TABLELIST;
		open c1;
		fetch c1 into @tName;
		while @@fetch_status=0
		begin
			-- This query uses dynamic SQL to workaround a bug in the SQL Database Publishing Wizard program
			set @nsql = 'select @sysDB=SYS_DB,@comDB=COM_DB from systemdb.dbo.DictTbl where TableName=''' + @tName + '''';
			execute sp_executesql @nsql, N'@sysDB char(1) output, @comDB char(1) output', @sysDB output, @comDB output;

			if @sysDB in ('Y','L')
				set @sourceDB='systemdb';
			else if @comDB in ('Y','L')
				set @sourceDB='commondb';

			if exists (select 1 from sys.views where name=@tName and type='V')
			begin
				set @sql='drop view ' + @tName;
				print @sql;
				exec (@sql);
			end

			set @sql = 'create view ' + @tName + ' as select * from ' + ltrim(rtrim(@sourceDB)) +'.dbo.' + ltrim(rtrim(@tName));
			print @sql;
			exec (@sql);
			fetch c1 into @tName;
		end
		close c1;
		deallocate c1;

		drop table #TABLELIST;
	end
end
--exec absp_CreateRDBViews
