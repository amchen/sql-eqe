if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureWhereClause') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureWhereClause
end
 go

create procedure absp_GenerateExposureWhereClause @whereClause varchar(max) output,@nodeKey int, @nodeType int ,@category varchar(120),@tableName varchar(120),@findRepl int=0,@alias varchar(10) =''					
as
begin
	set nocount on
	declare @fieldName varchar(50);
	declare @filterType varchar(50);
	declare @operation varchar(max);
	declare @value varchar(max);
	declare @refTableName varchar(120);
	declare @refFieldName varchar(120);
	declare @refKeyFieldName varchar(120);
	declare @sql varchar(max);
	declare @inList varchar(max);
	declare @exposureKeyList varchar(max);
	
	set @refFieldName ='';
	set @refTableName  ='';
	set @refKeyFieldName  ='';
	set @exposureKeyList ='';
	
	set @whereClause ='';
	if @alias<>'' set @alias = @alias + '.'

	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType
   	if @exposureKeyList='' return;
 	
	if @findRepl=0
		declare curFltr cursor  for 
			select FilterType,FieldName,Operation,Value from ExposureDataFilterInfo A 
				inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID and FilterType='P'
				where NodeKey=@NodeKey and NodeType=@nodeType and Category=@category
	else
		declare curFltr cursor  for 
				select FilterType,FieldName,Operation,Value from ExposureDataFilterInfo A 
						inner join ExposureCategoryDef B on A.CategoryID =B.CategoryID
				where NodeKey=@NodeKey and NodeType=@nodeType and Category=@category and FilterType in('G','P', 'W')
	open curFltr
	fetch curFltr into @filterType,@fieldName,@operation,@value
	while @@FETCH_STATUS =0
	begin
		if @operation= 'in' set @value='('+@value +')'
		if @operation= 'not in' set @value='('+@value +')'

		--Special handling for policy condition--
		if @fieldName='PolicyConditionNameKey'
		begin
			set @sql = 'select PolicyConditionNameKey from PolicyConditionName where ConditionName ' + @operation + ' ' + @value ;
			set @sql = @sql + ' and ExposureKey ' + @exposureKeyList
			exec absp_Util_GenInListString @value out, @sql;
			if @value='' set @value=('-9999999')
			set @operation='in'
			set @value = '('+@value +')'
		end
		------------------
		
		select @refTableName=RefTableName, @refFieldName=RefFieldName,  @refKeyFieldName=RefKeyFieldName from DictExpEdit	
			where TableName=@tableName and FieldName=@fieldName 
	
		if @refTableName <>'' and  @fieldName<>'PolicyConditionNameKey'
		begin
			set @sql='select ' + @refKeyFieldName + ' from ' + @refTableName + ' where ' + @refFieldName + ' ' + @operation + ' ' + @value;
			exec absp_Util_GenInListString @InList out, @sql;
			if @inList=''
				set @whereClause = ' 1=0 and ';
			else
			begin
				set @whereClause = @whereClause + @alias + @fieldName +' in(' + @inList+')  and ';
			end
		end
		else
		begin
			set @whereClause = @whereClause + @alias + @fieldName +' ' + @operation + ' ' + @value + ' and ';
		end
		fetch curFltr into @filterType,@fieldName,@operation,@value
	end
	close curFltr	
	deallocate curFltr
	

	if len(@whereClause)> 0 
		set @whereClause=  LEFT(@whereClause,(LEN(@whereClause)-4))
end


