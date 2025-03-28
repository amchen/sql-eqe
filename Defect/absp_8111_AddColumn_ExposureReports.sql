if exists(select * from SYSOBJECTS where ID = object_id(N'absp_8111_AddColumn_ExposureReports') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_8111_AddColumn_ExposureReports;
end
go

create procedure  absp_8111_AddColumn_ExposureReports
as

begin

	declare @cnt1 int;
	declare @cnt2 int;
	declare @sql nvarchar(max);
	declare @sql2 varchar(max);
	declare @msg varchar(max);
	declare @fieldnames varchar(max);
	declare @hasIdentity int;
	declare @objName nvarchar(2000)
	declare @newName nvarchar(2000)
	declare @colCnt int;
	declare @newColCnt int;
	declare @exposureReportKey int;
	declare @exposureKey int;
	declare @parentKey int;
	declare @parentType int;

	set nocount on
	begin try
			--Add column to ExposureReport--

			--Check if table  exists --
			if not exists(select 1 from sys.objects where object_name(object_id)= 'ExposureReport')
				return;

			if exists (select 1 from sys.columns where object_name(object_id)= 'ExposureReport' and name ='NumBuildings')
				return;

			--Get column list--
			set @sql='select name from sys.columns  where OBJECT_NAME(object_id)=''ExposureReport'' order by column_id'
			exec absp_Util_GenInList @fieldNames out , @sql, 'S'
			set @fieldNames= replace(replace(replace(@fieldNames, ' ) ',''),'in ( ',''),'''','')

			--create backup--
			if exists(select 1 from sys.tables where name='ExposureReport_Backup')
				drop table ExposureReport_Backup;

			exec sp_rename 'ExposureReport','ExposureReport_Backup';
			print 'backup created'

			--create table with indexes--
			exec systemdb..absp_Util_CreateTableScript @sql out, 'ExposureReport','','',1;
			exec (@sql);
			print 'table created'

			--transfer table data--
			--To make sure migration does not take forever, move the data by chunking on distinct ExposureReportKey,ExposureKey,ParentKey,ParentType.
			select ExposureReportKey,ExposureKey,ParentKey,ParentType into #TMPTbl from ExposureReport_Backup group by ExposureReportKey,ExposureKey,ParentKey,ParentType
			while exists(select top (1) 1 from #TMPTbl)
			begin
				--Get the first chunk--
				select top(1) @exposureReportKey=ExposureReportKey,@exposureKey=ExposureKey,@parentKey=ParentKey,@parentType=ParentType from #TMPTbl
				set @sql = 'insert into ExposureReport(' + @fieldnames + ') select ' + @fieldnames + '  from ExposureReport_Backup' +
						' where ExposureReportKey=' + cast(@exposureReportKey as varchar(10)) +
						' and ExposureKey=' + cast(@exposureKey as varchar(10)) +
						' and ParentKey=' + cast(@parentKey as varchar(10)) +
						' and ParentType=' + cast(@parentType as varchar(10));

				exec(@sql);
				delete from #TMPTbl
					where ExposureReportKey=@exposureReportKey and ExposureKey=@exposureKey and ParentKey=@parentKey and ParentType=@parentType
			end
			print 'rows inserted'
			-----

			select top (1)  @cnt2 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= 'ExposureReport_Backup' and INDID<2 order by indid desc,rowcnt desc;

			if @cnt1<>@cnt2 raiserror ('Error Inserting column',16,1);

		end try
		begin catch
			set @msg=Error_Message();
			print @msg
			raiserror (@msg,16,1);
			return
		end catch

		print 'drop backup'
		--drop backup--
		if exists(select 1 from sys.objects where name='ExposureReport_Backup')
			drop table ExposureReport_Backup

	return 0
end;