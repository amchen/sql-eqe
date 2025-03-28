if exists ( select 1 from sysobjects where name = 'absp_GetPolicyConditionNameKey ' and type = 'P' ) 
begin
   drop procedure absp_GetPolicyConditionNameKey;
end
go

CREATE Procedure absp_GetPolicyConditionNameKey @ConditionName varchar(200),@exposureKey int, @accountKey int, @PolicyFilterRowNum int,@PolicyConditionRowNum int
as
begin
	set nocount on
	declare @policyConditionNameKey int; 
	declare @accountNumber varchar(50);
	declare @nodeKey int;
	declare @nodeType int;
	declare @tablename varchar(120);
	declare @sql varchar(max);
	
	--Check Name on policyConditionName table
	if exists(select accountKey from PolicyConditionName where ExposureKey=@exposureKey and AccountKey =@accountKey and ConditionName=@ConditionName )
	begin
		select @policyConditionNameKey=PolicyConditionNameKey from PolicyConditionName where ExposureKey=@exposureKey and AccountKey =@accountKey and ConditionName=@ConditionName 
	end
	else
	begin
		begin transaction
			select @policyConditionNameKey=isNull(max(PolicyConditionNameKey),0) from PolicyConditionName where ExposureKey=@exposureKey and AccountKey =@accountKey ;
			select @accountNumber =AccountNumber from Account where ExposureKey=@exposureKey and AccountKey =@accountKey 
			set @accountNumber=isNull(@accountNumber,'');
			
			set @policyConditionNameKey=@policyConditionNameKey+1;
			insert into PolicyConditionName(PolicyConditionNameKey,ExposureKey,AccountKey,AccountNumber,ConditionName) values(@policyConditionNameKey,@exposureKey,@accountKey,@accountNumber,@conditionName)
		commit transaction
	end			
			
	--Uppdate ConditionKey in Filtered table--
	select @nodeKey=ParentKey,@nodeType=ParentType from ExposureMap where ExposureKey=@exposureKey;
			
	if @PolicyFilterRowNum<>-1
	begin
		exec absp_GetFilteredTableName @tableName  output,'PolicyFilter', @nodeKey, @nodeType,1
		set @sql='update ' + @tablename + ' set PolicyConditionNameKey =' + cast (@policyConditionNameKey as varchar(30)) +
					' where PolicyFilterRowNum= ' + cast (@policyFilterRowNum as varchar(30));
	end
	else
	begin
		exec absp_GetFilteredTableName @tableName  output,'PolicyCondition', @nodeKey, @nodeType,1
		set @sql='update ' + @tablename + ' set PolicyConditionNameKey =' + cast (@policyConditionNameKey as varchar(30)) +
						' where PolicyConditionRowNum= ' + cast (@policyConditionRowNum as varchar(30));
	end
	exec (@sql);

	select 	@policyConditionNameKey as PolicyConditionNameKey
end

