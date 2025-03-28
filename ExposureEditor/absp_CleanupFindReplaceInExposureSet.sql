if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanupFindReplaceInExposureSet') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupFindReplaceInExposureSet
end
 go

create procedure absp_CleanupFindReplaceInExposureSet @taskKey int, @nodeKey int, @nodeType int, @userKey int =1, @debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will be invoked if a Find/Replace task is cancelled.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END


*/
as
begin
	set nocount on
	declare @tableName varchar(130);
	declare @filterTableName  varchar(130);
	declare @sql  varchar(max);
	declare @status varchar(20);
	declare @chunkSize int;
	declare @tempTblName varchar(120);
	declare @replFieldName varchar(120);
	declare @replTableName varchar(120);
	
	set @chunkSize=10000;
	set @tempTblName = 'TmpReplaceInfo_' + dbo.trim(cast(@taskKey as varchar(30)));
	
	--Get replace Info--
	select @replFieldName=FieldName,@replTableName=TableName
		from   ExposureDataFilterInfo A inner join ExposureCategoryDef  B
		on A.CategoryId=B.CategoryId
		where FilterType = 'R' and len(dbo.trim(TableName))>0  


	--Rollback cancelled task--
	if exists (select 1 from sys.tables where name = @tempTblName)
	begin
		while 1=1
		begin
			set @sql = 'update top ('+ cast(@chunkSize as varchar(30)) + ')' + @replTableName + ' set ' + @replFieldName + '=oldValue ' 
					 + ' from ' + @replTableName + ' A inner join ' + @tempTblName  +' B on  A.' + @replTableName + 'RowNum = B.ExpTableRowNum' +
					 ' where Status=1 and ' + @replFieldName + '=newValue';
			if @debug=1 exec absp_MessageEx @sql;
			exec(@sql);

			if @@rowCount=0 break;
		end

		exec('drop table ' + @tempTblName );
	end
	
	--Set an attrib bit 
	if @nodeType=2
		select @status=Status from TaskInfo where PportKey=@nodeKey and NodeType=@nodeType and TaskKey=@taskKey;
	else
		select @status=Status from TaskInfo where ProgramKey=@nodeKey and NodeType=@nodeType and TaskKey=@taskKey;
	if @status='Failed'
		exec absp_InfoTableAttribSetBrowserFindReplFail @nodeType,@nodeKey,1 
	else 
		exec absp_InfoTableAttribSetBrowserFindReplCancel @nodeType,@nodeKey,1 
	
		-- clean up the find and replace info
	delete from ExposureDataFilterInfo where NodeKey=@nodeKey and NodeType=@nodeType and FilterType in('G', 'R')

	--Update TaskStepInfo	
	if @status in ('Failed','Cancelled')
		update TaskStepInfo set Status=@status where TaskKey=@taskKey and Status in ('Running','Waiting');

end
