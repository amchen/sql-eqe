if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureInnerJoinForOrderBy') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureInnerJoinForOrderBy
end
 go

create procedure absp_GenerateExposureInnerJoinForOrderBy @innerJoinStr varchar(max) output, @nodeKey int, @nodeType int,@category varchar(120),@tableName varchar(120)
as
begin
	set nocount on
	
	declare @sql varchar(max);
	declare @fieldName varchar(50);
	declare @lookupTableName varchar(120);
	declare @cacheTypeDefId int;
	declare @valueList varchar(max);
	declare @lookupIdColName varchar(120);
	declare @lookupDescColName varchar(120);
	declare @exposureKeyList varchar(max);
	declare @lookupFlag int;
	declare @operation varchar(50);
	declare @isCountrySpecific varchar(1);

	set @innerJoinStr ='';
	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType

	declare curSort cursor  for 
		select FieldName from ExposureDataSortInfo A inner join ExposureCategoryDef B 
			on A.CategoryID =B.CategoryID
			where NodeKey=@NodeKey and NodeType=@nodeType and Category=@category
	open curSort
	fetch curSort into @fieldName
	while @@FETCH_STATUS =0
	begin
		set @lookupFlag=2;
		set @lookupTableName='';
		
		--Get Column names for auto lookups
		select @lookupTableName=RefTableName,@lookupIdColName=RefKeyFieldName,@lookupDescColName=RefFieldName from DictExpEdit A inner join ExposureCategoryDef B	 
			on A.TableName=B.TableName and  Category=@category and A.FieldName=@fieldName
		--If not get Column Names for lookups	
		
		if @lookupTableName=''	
		begin
			select @lookupTableName=LookupTableName,@lookupIdColName=LookupFieldName,@lookupDescColName=LookupDisplayColName ,@cacheTypeDefId=A.CacheTypeDefID,
				 @isCountrySpecific= IsCountrySpecific
				 from DictCol A inner join CacheTypeDef B on A.CacheTypeDefID=B.CacheTypeDefId where A.TableName=@tableName and A.FieldName=@fieldName
				 and B.CacheTypeDefID>0

			if   @fieldName='CurrencyCode' begin break;end
			set @lookupFlag=1;	
		end
		if @lookupTableName=''	
			set @lookupFlag=0;
				
		 --Check if a filter has been applied on this column--
		 set @valueList='';
		 select @operation =operation, @valueList=Value from ExposureDataFilterInfo P inner join ExposureCategoryDef  R
			on P.CategoryID =R.CategoryID where NodeKey=@nodeKey and NodeType=@nodeType and FieldName=@fieldName 
			and Category=@category
				
		if len(@valueList)>0 and @lookupFlag>0
		begin
			--Special handling for PolicyCondition--
			if @fieldName='PolicyConditionNameKey'
			begin
				if @operation in('in','not in')  set @valueList='(' +  @valueList + ')'
				 
				set @sql = 'insert into #PolicyConditionName select distinct PolicyConditionNameKey,ConditionName from ' + @lookupTableName  +
				' where ConditionName ' + @operation +  @valueList
			end
			else
			begin
			set @sql = 'insert into #' + @lookupTableName +'('+@lookupIdColName+',' + @lookupDescColName + ')'+
				' select distinct ' + @lookupIdColName +',' + @lookupDescColName+ ' from ' + @lookupTableName  +
				' where ' + @lookupIdColName  +  ' in(' +  @valueList + ')'
			end
				print @sql
			exec(@sql);			 
		end
		else if  @lookupFlag=1
		begin
			if @isCountrySpecific ='Y'
			begin
					set @sql = 'insert into #' + @lookupTableName +'('+@lookupIdColName+',' + @lookupDescColName + ',' + + 'Country_ID)'+
					' select distinct ' + @lookupIdColName  +',' + @lookupDescColName+ ',Country_Id from ' + @lookupTableName  + ' where ' + @lookupIdColName +' in
					(select LookupId from ExposureCacheInfo where ExposureKey ' +@exposureKeyList + ' and CacheTypeDefId='+ cast (@cacheTypeDefID as varchar(30)) + ')';
			end
			else
			begin
				set @sql = 'insert into #' + @lookupTableName +'('+@lookupIdColName+',' + @lookupDescColName + ')'+
					' select distinct ' + @lookupIdColName  +',' + @lookupDescColName+ ' from ' + @lookupTableName  + ' where ' + @lookupIdColName +' in
					(select LookupId from ExposureCacheInfo where ExposureKey ' +@exposureKeyList + ' and CacheTypeDefId='+ cast (@cacheTypeDefID as varchar(30)) + ')';
			end	
			exec(@sql);
		end
		else  if  @lookupFlag=2
		begin
				--For Autolookups
			--Special handling for PolicyCondition--
			if @fieldName='PolicyConditionNameKey'
			begin
				set @sql = 'insert into #PolicyConditionName select PolicyConditionNameKey,ConditionName from ' + @lookupTableName  +
				 + ' where ExposureKey ' +@exposureKeyList;
			end
			else
			begin
				--set @sql = 'insert #' + @lookupTableName +
					--'select Distinct * from  ' + @lookupTableName  + ' where ExposureKey ' +@exposureKeyList;
					set @sql=''
			end
			exec(@sql);	
		end
		if @tableName='PolicyFilter' and @lookupFlag>0
			set @innerJoinStr=@innerJoinStr +' inner Join #'+ @lookupTableName +' B on F.' + @fieldName + ' = B.'+@lookupIdColName
		else if  @lookupFlag>0
		begin
			if @isCountrySpecific ='Y'
			begin
				set @innerJoinStr=@innerJoinStr +' left outer Join #'+ @lookupTableName +' '+ @lookupTableName +' on ' + @tableName + '.' + @fieldName + ' = '+ @lookupTableName + '.'+@lookupIdColName +
					' and ' + @tableName + '.CountryCode='+ @lookupTableName + '.Country_ID'--Fixed defect 10964
			end
			else
			begin
				set @innerJoinStr=@innerJoinStr +' inner Join #'+ @lookupTableName +' '+ @lookupTableName +' on ' + @tableName + '.' + @fieldName + ' = '+ @lookupTableName +'.'+@lookupIdColName
			end

		end
		fetch curSort into @fieldName 
	end
	close curSort	
	deallocate curSort	

end