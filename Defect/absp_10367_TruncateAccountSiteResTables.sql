if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_10367_TruncateAccountSiteResTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_10367_TruncateAccountSiteResTables;
end
go

create procedure absp_10367_TruncateAccountSiteResTables
as
begin
	--0010367: System Snapshot should not include Primary Account and Primary Site results
	declare @tableName varchar(120);
	declare @sql varchar(max);
	declare @inList varchar(max);

	--Tuncate the Account/Site Node res tables
	declare TruncateCurs cursor local for
		select rtrim(TableName) from DictTbl where FrndlyName like 'Primary Account%' or FrndlyName like 'Primary Site%';
	open TruncateCurs;
	fetch TruncateCurs into @tableName;
	while @@FETCH_STATUS=0
	begin
		set @sql = 'truncate table dbo.' + @tableName;
		print @sql;
		exec (@sql);
		fetch TruncateCurs into @tableName;
	end
	close TruncateCurs;
	deallocate TruncateCurs;

	----Delete entries from AvailableReport
	set @sql='select AnalysisRunKey from dbo.AnalysisRunInfo where SiteKey <> 0 or AccountKey <> 0';
	exec absp_Util_GenInList @inList output, @sql;

	delete from dbo.AnalysisRunInfo where SiteKey <> 0 or AccountKey <> 0;

	if len(@inList)>0
	begin
		set @sql='delete from dbo.AvailableReport where AnalysisRunKey ' + @inList;
		exec (@sql);
	end
end
