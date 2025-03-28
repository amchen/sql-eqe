if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetReportFilterInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetReportFilterInfo
end
 go

create procedure absp_GetReportFilterInfo @nodeKey int,@nodeType int, @exposureKey int=-1,@accountKey int=-1,@snapshotKey int =0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure gets report filter information for the given node.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin try
	set nocount on
	
	declare @sql varchar(max);
	declare @columnName varchar(100);
	declare @schemaname varchar(50);
					
	select @columnName = Case @nodeType
		when 0  then 'FolderKey'
		when 1  then 'AportKey'
		when 2  then 'Pportkey'
		when 4  then 'AccountKey'
		when 8  then 'PolicyKey'
		when 9  then 'SiteKey'
		when 23 then 'RPortKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		when 64 then 'ExposureKey'
		else ''
	end;
	
	if @columnName = '' return;
	if @snapshotKey = 0 
		set @schemaName='dbo';
	else
		set @schemaName = dbo.trim('Snapshot_' + dbo.trim(cast(@snapShotKey as varchar(10))));
	
	
	set @sql='select A.TableName,B.CacheTypeName, A.LookupID, A.LookupUserCode, A.Description,''N'' as DefaultRow 
	 			from ' + @schemaName + '.ReportFilterInfo A inner join CacheTypeDef B 
	 			on A.CacheTypeDefID=B.CacheTypeDefID
	 			where ' + @columnName + ' = ' + cast(@nodeKey as varchar(30)) + ' and NodeType=' +  cast(@nodeType as varchar(30));
		
	if @nodeType=4 	set @sql = @sql + ' and ExposureKey=' + cast(@exposureKey as varchar(30));
	if @nodeType=9 	set @sql = @sql + ' and ExposureKey=' + cast(@exposureKey as varchar(30)) + ' and AccountKey = ' + cast(@accountKey as varchar(30)) ;
	set @sql = @sql + ' order by case Description when ''XXX'' then '' All Countries'' else Description end asc';
	exec absp_MessageEx @sql 
	exec (@sql)
	
	
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
