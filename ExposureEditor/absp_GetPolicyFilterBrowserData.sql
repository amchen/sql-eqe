if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetPolicyFilterBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetPolicyFilterBrowserData
end
 go

create procedure absp_GetPolicyFilterBrowserData @nodeKey int, @nodeType int,@financialModelType int, @pageNum int,@pageSize int=1000,@userKey int=1,@debug int=0					
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @startRowNum int;
	declare @endRowNum int;
	declare @rowCnt int;
	declare @attrib int;
	declare @pgNum int;
	declare @tableExists int;
	declare @InProgress int;	
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1 
	begin
		select 0 as PolicyFilterRowNum,0 as ExposureKey,0 as AccountKey,0 as PolicyConditionNameKey,0 as StructureKey,
			'' as PolicyConditionName,'' as AccountNumber,'' as StructureNumber,'' as StructureName,'' as SiteNumber,0 as PageNumber,0 as Rownum from Structure T1 where 1=0; 

		return;
	end
	
	set @tableName='FilteredPolicyFilter_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 
	
	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin
		select @rowCnt=TotalCount from FilteredStatReport where Category='Policy Filter' and nodeKey=@nodeKey and NodeType=@nodeType

			--Calculate rowNum to be displayed from--
			set @pgNum=@rowCnt /@pageSize;
			if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
			if @pgNum<@pageNum set @pageNum=1

			set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
			set @endRowNum = @startRowNum + @pageSize 

			set @sql = 'select distinct T1.PolicyFilterRowNum,T1.ExposureKey,T1.AccountKey,T1.PolicyConditionNameKey,T1.StructureKey, 
					ConditionName as PolicyConditionName,AccountNumber,
					StructureNumber,StructureName,SiteNumber,' +dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum from ' + @tableName + ' T1  inner join  PolicyConditionName T2
						on T1.PolicyConditionNameKey=T2.PolicyConditionNameKey and T1.ExposureKey=T2.ExposureKey and T1.AccountKey=T2.AccountKey ' +
						'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
						' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			set @sql = @sql + ' order by RowNum'
			print @sql
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
		end
		else
		begin
			--BrowserData needs to be regenerated--
			select 0 as PolicyFilterRowNum,0 as ExposureKey,0 as AccountKey,0 as PolicyConditionNameKey,0 as StructureKey,
			'' as PolicyConditionName,'' as AccountNumber,'' as StructureNumber,'' as StructureName,'' as SiteNumber,0 as PageNumber,0 as Rownum from Structure T1 where 1=0; 
				
	end
end
