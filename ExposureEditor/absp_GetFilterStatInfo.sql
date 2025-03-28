if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetFilterStatInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetFilterStatInfo
end
 go

create procedure absp_GetFilterStatInfo @nodeKey int, @nodeType int,@financialModelType int=0,@userkey int=1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

		This procedure returns the statistics for all categories based on the filter applied
		for the given node.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END


*/
as
begin
	set nocount on
	
	declare @InProgress int;	
	declare @tableName varchar(200);
	declare @sql nvarchar(max);
	declare @financialmodeltype2 int;
	declare @tableExists int;
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	
	if @InProgress=1 
	begin
		select 0 as Category,0 as InvalidCount,0 as ValidCount,0 as TotalCount
		return;
	end
	
	--Check financial model type--
	set @tableName='FilteredAccount_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
    	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 
    	if @tableExists = 1
    	begin     
		set @sql = 'select top(1) @financialmodeltype2=financialmodeltype from ' +  @tableName;
		exec sp_executesql @sql,N'@financialmodeltype2 int out',@financialModelType2 out; 
	
		if @financialModelType=@financialModelType2
		begin
			select A.Category,InvalidCount,ValidCount,TotalCount 
				from FilteredStatReport A inner join ExposureCategoryDef B
				on A.Category =B.Category
				where NodeKey=@nodeKey and NodeType=@nodeType
				order by DisplayOrder;
			return;
		end
		else
		begin
			--In case of invalid records there may be no rows in filtered account table. 
			if exists(select 1 from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=3 and Value='Invalid Records')
			begin
				--get the table name having invalid rec to check the financial model
				set @tableName='';
				select top (1) @tableName=tableName  from FilteredStatReport  A inner join ExposureCategoryDef B on
					A.Category=B.Category where InvalidCount>0 and NodeKey=@nodeKey and NodeType=@nodeType
				
				if @tableName<>''
				begin
					set @tableName='Filtered' + @tableName + '_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) 
						+ '_'+dbo.trim(cast(@nodeKey as varchar(10)));
					
					set @sql = 'select top(1) @financialmodeltype2=financialmodeltype from ' +  @tableName;
					exec sp_executesql @sql,N'@financialmodeltype2 int out',@financialModelType2 out; 
	
					if @financialModelType=@financialModelType2
					begin
						select A.Category,InvalidCount,ValidCount,TotalCount 
						from FilteredStatReport A inner join ExposureCategoryDef B
						on A.Category =B.Category
						where NodeKey=@nodeKey and NodeType=@nodeType
						order by DisplayOrder;
						return;
					end
				end
				
			end
		end
	end
	
	select 0 as Category,0 as InvalidCount,0 as ValidCount,0 as TotalCount
	
end
