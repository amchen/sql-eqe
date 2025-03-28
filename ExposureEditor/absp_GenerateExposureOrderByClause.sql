if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureOrderByClause') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureOrderByClause
end
 go

create procedure absp_GenerateExposureOrderByClause @orderByClause varchar(max) output, @nodeKey int, @nodeType int,@category varchar(120),@tableName varchar(120),@defaultOrderBy varchar(8000)					
as
begin
	set nocount on

	declare @fieldName varchar(50);
	declare @orderBy varchar(50);
	declare @displayNameCol varchar(120);
	set @orderByClause ='';

	set @defaultOrderBy =', ' + @defaultOrderBy  + ',';
	declare curSort cursor  for 
		select FieldName,OrderBy from ExposureDataSortInfo A inner join ExposureCategoryDef B
			on A.CategoryID =B.CategoryID
			where NodeKey=@NodeKey and NodeType=@nodeType and Category=@category
	open curSort
	fetch curSort into @fieldName,@orderBy
	while @@FETCH_STATUS =0
	begin

		if @fieldName='FeatureType' 
			set @fieldName='FeatureCode'
			
		set  @displayNameCol='';
		select @displayNameCol= RefFieldName from DictExpEdit where TableName= @tableName and FieldName=@fieldName
		if  @displayNameCol=''
			select @displayNameCol=LookupDisplayColName
				 from DictCol A inner join CacheTypeDef B on A.CacheTypeDefID=B.CacheTypeDefId where A.TableName=@tableName and A.FieldName=@fieldName
				 and B.CacheTypeDefID>0 and B.CacheTypeDefID<>3 --CurrencyCode
				 
			select @displayNameCol= LookupDisplayColName from CacheTypeDef  where LookupTableName = @tableName and lookupfieldname=@fieldName
		if @displayNameCol<>'' set @fieldName=@displayNameCol ;


		if charIndex(', '+@fieldName+',',@defaultOrderBy )>0
		begin
			set @defaultOrderBy =REPLACE (@defaultOrderBy,@fieldName+',','');

		end
	
		IF @displayNameCol =''
			set @orderByClause = @orderByClause + @tableName+'.'+@fieldName+' ' + @orderBy + ',';
		else if charindex ('Reinsurance',@category)>0 and @fieldName='Name'
			set @orderByClause = '';--@orderByClause + 'TrtyTag.' +  @fieldName+' ' + @orderBy + ',';
		ELSE 
		begin
			set @orderByClause = @orderByClause + @fieldName+' ' + @orderBy + ',';
		end

		fetch curSort into @fieldName,@orderBy
	end
	close curSort	
	deallocate curSort	
	if len(@orderByClause)=0 
		set @orderByClause = substring(@defaultOrderBy,2,LEN(@defaultOrderBy)-2)
	else
		set @orderByClause=left(@orderByClause,len(@orderByClause)-1) +left(@defaultOrderBy,len(@defaultOrderBy)-1);
		
end