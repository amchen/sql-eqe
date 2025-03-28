if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PopulateFilterStats') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateFilterStats
end
 go

create procedure absp_PopulateFilterStats @category varchar(100), @tableName varchar(100),@filterTblName varchar(120), @nodeKey int, @nodeType int,@userKey int
as
begin
	set nocount on
	
	declare @cnt int;
	declare @filteredTableName varchar(200);
	declare @sql nvarchar(max);
	declare @invCnt varchar(2000);
	declare @exposureKeyList varchar(max);
	
	--Get exposureKeys--
	select @exposureKeyList=Value from ExposureDataFilterInfo where nodeKey=@nodeKey and NodeType=@nodeType and CategoryID=1 ;
	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType


	exec absp_GetFilteredTableName @filteredTableName out, @filterTblName,@nodeKey,@nodeType,@userKey;

	--Total Rows--
	select  @cnt= ROWCNT  from SYSINDEXES where ID=object_id(@filteredTableName) and INDID<2;
	
	--Invalid rows--
	set @invCnt=0;
	if @category='Policy Filter'
	begin
		set @invCnt=0;
	end
	else
	begin
		set @sql='select @invCnt=count(*) from ' + @tableName + ' A inner join ' + @filteredTableName + ' B '+
			' on A.' + @tableName +'RowNum=B.'+ @tableName +'RowNum and IsValid=0';
		if @exposureKeyList<>'' set @sql = @sql + ' and A.ExposureKey ' + @exposureKeyList
		exec sp_Executesql @sql,N'@invCnt int out',@invCnt out;
	end
	

	Insert into FilteredStatReport (NodeKey,NodeType,Category,DisplayLabel,InvalidCount,ValidCount,TotalCount)values (@nodeKey,@NodeType,@category,'Number of ' + @category,@invCnt,@cnt-@invCnt,@cnt);
  
end
	  
  
 


 
