if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDownloadInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDownloadInfo
end
 go

create procedure absp_GetDownloadInfo @dbRefKey int, @userKey int, @reportTypeKey int, @nodeKey int, @nodeType int,@exposureKey int=0,@accountKey int=0,@siteKey int=0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      The procedure returns the DownloadInfo for the given node.
Returns:       None
=================================================================================
</pre>
</font>
##BD_END
*/
begin
	set nocount on
	declare @columnName varchar(120);
	declare @sql nvarchar(max);
	declare @parentType int;
	declare @parentKey int;

	--Get the columnName from the Node Info--
	select @columnName = Case @nodeType
		when 0  then 'FolderKey'
		when 1  then 'AportKey'
		when 2  then 'PportKey'
		when 8  then 'PolicyKey'
		when 23 then 'RportKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		when 102 then 'RdbInfoKey'
		when 103 then 'RdbInfoKey'
		when 4 then 'AccountKey'
		when 9 then 'SiteKey'
		else ''
	end;
	
	-- guard against empty column name and return an empty result set
	if @columnName = ''
	begin
		select * from DownloadInfo where DownloadKey = -99999
		return
	end
	
	--Get parent from exposuremap
	if @nodeType = 4 or @nodeType = 9
	begin
		set @sql = 'select @parentKey=ParentKey,@parentType=ParentType from ExposureMap where ExposureKey  = ' + dbo.trim(cast(@exposureKey as varchar(20)));
		execute sp_executesql @sql,N'@parentKey int output, @parentType int output',@parentKey output, @parentType output
		if @parentType = 2
			set @columnName = 'PportKey';
		else
			set @columnName = 'ProgramKey';

		set @sql = 'select * from DownloadInfo where ' + @columnName + ' = ' + cast(@parentKey as varchar(30)) +
					' and NodeType = ' + cast(@nodeType as varchar(10));
	end
	else 
		set @sql = 'select * from DownloadInfo where ' + @columnName + ' = ' + cast(@nodeKey as varchar(30)) + ' and NodeType = ' + cast(@nodeType as varchar(10));

	if @exposureKey>0
		set @sql = @sql + ' and ExposureKey = ' +  cast(@exposureKey as varchar(30));
	if @accountKey>0
		set @sql = @sql + ' and AccountKey = ' +  cast(@accountKey as varchar(30));
	if @siteKey>0
		set @sql = @sql + ' and SiteKey = ' +  cast(@siteKey as varchar(30));

	set @sql=@sql + ' and UserKey = ' +  cast(@userKey as varchar(30));
	
	--Get all reports if ReportType<=0--
	if @reportTypeKey>0
		set @sql=@sql + ' and ReportTypeKey = ' +  cast(@reportTypeKey as varchar(30));

	set @sql = @sql + ' and DBRefKey= ' + dbo.trim(cast(@dbRefKey as varchar(30)))+ ' order by DownloadKey';

	print @sql;
	exec(@sql);
end; 