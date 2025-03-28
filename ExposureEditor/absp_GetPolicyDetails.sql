if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetPolicyDetails') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetPolicyDetails
end
 go

create procedure absp_GetPolicyDetails @category varchar(20),@exposureKey int, @accountKey int,@policyKey int, @nodeKey int, @nodeType int, @financialModelType int,@userKey int=1,@debug int=0					
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @attrib int;
	declare @tableExists int;
	declare @InProgress int;	
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1 return;

	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @category='Policy Reinsurance'
	begin
		--Return Policy Rein--
		set @tableName='FilteredPolicyReinsurance_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
		set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
		exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

		if @attrib=0 and @tableExists=1
		begin
			set @sql = 'select T1.*,AccountNumber,PolicyNumber,R.Name as ReinsurerName,T.Name  as TreatyTagName,RowNum from Reinsurance T1 inner join ' + @tableName + ' T2 
				on T1.ReinsuranceRowNum=T2.ReinsuranceRowNum 
				 inner join Reinsurer R on T1.ReinsurerID=R.ReinsurerID 
				 inner join TreatyTag T on T1.TreatyTagID=T.TreatyTagID 
				where T1.ExposureKey=' + 
				cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30))+ ' and T1.PolicyKey =' + cast(@policyKey as varchar(30));
			set @sql = @sql + ' order by RowNum'
			exec absp_MessageEx @sql
			exec(@sql)
		end
		else
		begin
			--BrowserData needs to be regenerated--
			select T1.*,'' as AccountNumber,'' as PolicyNumber,'' as ReinsurerName,'' as TreatyTagName,0 from Reinsurance T1 where 1=0; 
		end
	end
	else
	begin
		--Return Policy Condition--
		set @tableName='FilteredPolicyCondition_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
		set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
		exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

		if @attrib=0 and @tableExists=1
		begin

			set @sql = 'select distinct T1.*,T2.AccountNumber,PolicyNumber,CSLCoverageName,T3.ConditionName as PolicyConditionName,T2.CurrencyCode as CurrencyCode,RowNum from PolicyCondition T1 inner join ' + @tableName + ' T2 
					on T1.PolicyConditionRowNum=T2.PolicyConditionRowNum ' + 
					' left outer join PolicyConditionName T3 on T1.ExposureKey=T3.ExposureKey and T1.AccountKey=T3.AccountKey and T1.PolicyConditionNameKey=T3.PolicyConditionNameKey ' +
					' where T1.ExposureKey=' + 
					cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30))+ ' and T1.PolicyKey =' + cast(@policyKey as varchar(30));
			set @sql = @sql + ' order by RowNum'
			exec absp_MessageEx @sql
			exec(@sql)
		end
		else
		begin
			--BrowserData needs to be regenerated--
			select T1.*,'' as AccountNumber,'' as PolicyNumber,'' as CSLCoverageName,'' as PolicyConditionName,'' as CurrencyCode,0 as RowNum from PolicyCondition T1 where 1=0; 
		end
	end
end