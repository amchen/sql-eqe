if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetTotalRowCount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetTotalRowCount
end
 go

create procedure absp_GetTotalRowCount @category varchar(50), @nodeKey int, @nodeType int, @financialModelType int, @exposureKey int,@accountKey int, @userKey int=1, @debug int=0						
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql varchar(max);
	
	select @category = case @category 
		when 'Accounts' then 'Account'
		when 'Policies' then 'Policy'
		when 'Structures' then 'Structure'
		when 'Structure Coverages' then 'StructureCoverage'
		when 'Structure Features' then 'StructureFeature'
		when 'Policy Conditions' then 'PolicyCondition'
		when 'Policy Filter' then 'PolicyFilter'
		when 'Site Conditions' then 'SiteCondition'
		when 'Account Reinsurance' then 'AccountReinsurance'
		when 'Policy Reinsurance' then 'PolicyReinsurance'
		when 'Policy Reinsurance' then 'PolicyReinsurance'
		when 'Site Reinsurance' then 'SiteReinsurance'
	else
		''
	end
		
	set @tableName='Filtered' + @category + '_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	
	set @sql = 'select count(*) as totalRows from ' + @tableName + ' where ExposureKey=' + dbo.trim(cast(@exposureKey as varchar(30))) + ' and AccountKey =' + dbo.trim(cast(@accountKey as varchar(30))) + ' and FinancialModelType=' + dbo.trim(cast(@financialModelType as varchar(30)));
				
	exec absp_MessageEx @sql
	exec(@sql)
end