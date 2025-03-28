if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetPolicyBrowserData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetPolicyBrowserData
end
 go

create procedure absp_GetPolicyBrowserData @nodeKey int, @nodeType int, @financialModelType int, @pageNum int,@pageSize int=1000,@exposureKey int =-1,@accountKey int =-1 ,@userKey int=1,@debug int=0				
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
	declare @fieldNames varchar(max);
	declare @errorStr varchar(100);
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1 
	begin
		select T1.*,'' as AccountNumber,'' as LineOfBusinessName,'' as ErrorMessage,0 as PageNumber,0 as RowNum from Policy T1 where 1=0; 
		return;
	end
	
	set @startRowNum=0;
	set @errorStr='''Undetermined. Please view the Import Exception report for more details.'''
	
	set @tableName='FilteredPolicy_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 
	
	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin
		if @exposureKey<>-1 --For relational view get the start Row num
		begin
			set @sql = 'select top(1) @startRowNum=RowNum from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec absp_MessageEx @sql			
			exec sp_executesql @sql,N'@startRowNum int out' ,@startRowNum out

			set @sql = 'select @rowCnt=count(*) from ' + @tableName + '  T1 where  T1.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T1.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))+
					' and T1.FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
			exec sp_executesql @sql,N'@rowCnt int out' ,@rowCnt out
			if @rowCnt>=@pageSize
			begin
				set @pgNum=@rowCnt /@pageSize;
				if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
				if @pgNum<@pageNum set @pageNum=1
				set @startRowNum=@startRowNum +((@pageNum - 1) * @pageSize);
			end	
			
		end
		else
		begin
			select @rowCnt=TotalCount from FilteredStatReport where category='Policies' and nodeKey=@nodeKey and NodeType=@nodeType

			--Calculate rowNum to be displayed from--
			set @pgNum=@rowCnt /@pageSize;
			if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
			if @pgNum<@pageNum set @pageNum=1

			set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
			
		end	
		set @endRowNum = @startRowNum + @pageSize

		--For Invalid Records, display Error message--
		if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
		begin
			 --create temporary table to hold 100 rows
			 select * into #TmpPol from Policy where 1=2;
			 execute absp_DataDictGetFields @fieldNames output, 'Policy',0;
			 
			 set identity_insert #TmpPol on
			 set @sql = 'insert into #TmpPol (' + @fieldNames + ') select T1.*	from Policy T1 inner join ' + @tableName + ' T2 
				on T1.PolicyRowNum=T2.PolicyRowNum ' +
				'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
				' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;
			if @exposureKey<>-1
				set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))

			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
			set identity_insert #TmpPol off
			 
			 --Get the Error messages for the above records--
			 select distinct A.ExposureKey, SourceId,UserRowNumber,MessageText into #TmpErrorWarning from ImportErrorWarning A 
				inner join #TmpPol B on A.ExposureKey=B.ExposureKey and A.SourceID =B.InputSourceID and A.UserRowNumber =B.InputSourceRowNum
			 
			 --Concatenate rows--
			 select distinct
				ExposureKey,SourceID ,UserRowNumber,
				STUFF(
					(SELECT      '^' + A.MessageText 
						FROM      #TmpErrorWarning AS A
					WHERE      A.ExposureKey=B.ExposureKey and A.SourceID =B.SourceID and A.UserRowNumber =B.UserRowNumber
					FOR XML PATH('')), 1, 1, '') AS ErrorMessage
				into #TmpErrorMsg
				FROM  #TmpErrorWarning as B

			--Get the final query--		 
		 	set @sql = 'select distinct T1.*, AccountNumber,L.Name as LineOfBusinessName,isnull(ErrorMessage,' + @errorStr + ') as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum from #TmpPol T1 '+
		 			 ' inner join ' + @tableName + ' T2 on T1.PolicyRowNum=T2.PolicyRowNum '+
		 			 ' left outer join #TmpErrorMsg E on T1.ExposureKey=E.ExposureKey and T1.InputSourceID =E.SourceID and T1.InputSourceRowNum =E.UserRowNumber '+
					 ' inner join LineOfBusiness L on T1.LineOfBusinessID=L.LineOfBusinessID '
			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
		end
		else
		begin	
			set @sql = 'select distinct T1.*, AccountNumber,L.Name as LineOfBusinessName,'''' as ErrorMessage,' +dbo.trim(cast(@pageNum as varchar(30))) + ' as PageNumber,RowNum from Policy T1 inner join ' + @tableName + ' T2 
					on T1.PolicyRowNum=T2.PolicyRowNum ' +
					 ' inner join LineOfBusiness L on T1.LineOfBusinessID=L.LineOfBusinessID '+
					'  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) + 
					' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30))) ;

			if @exposureKey<>-1
				set @sql=@sql + ' and T2.ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and T2.AccountKey =' + dbo.trim(cast(@accountKey as varchar(30)))

			set @sql = @sql + ' order by RowNum'
			if @debug=1 exec absp_MessageEx @sql
			exec(@sql)
		end
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*,'' as AccountNumber,'' as LineOfBusinessName,'' as ErrorMessage,0 as PageNumber,0 as RowNum from Policy T1 where 1=0; 
			
	end
end
