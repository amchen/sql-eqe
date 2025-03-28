if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ExposureCountUpdate') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_ExposureCountUpdate;
end
go

create procedure absp_ExposureCountUpdate @ExposureKey int
as
BEGIN TRY

	set nocount on;

	declare @sql nvarchar(max);
	declare @CategoryID int;
	declare @curs1_DISPLAYNAME varchar(100);
	declare @curs1_WhereClause varchar(200);
	declare @curs1_TABLENAME varchar(100);
	declare @HasIsValidCol int;
	declare @NodeKey int;
	declare @NodeType int;
	declare @counter int;
	declare @cntTotal int;
	declare @cntValid int;

	-- Check parameters
	if (@ExposureKey < 1)
	begin
		exec absp_Migr_RaiseError 1, 'absp_ExposureCountUpdate: Invalid ExposureKey';
		return;
	end

	--get the Node Key and Type
	select @NodeKey=ParentKey, @NodeType=ParentType from ExposureMap where ExposureKey=@ExposureKey;

	--loop Exposure categories
	declare curs1 cursor fast_forward for
		select CategoryID,Category,TableName,HasIsValidCol,WhereClause from ExposureCategoryDef where CategoryOrder > 0 order by CategoryID;

	open curs1 fetch next from curs1 into @CategoryID, @curs1_DISPLAYNAME, @curs1_TABLENAME, @HasIsValidCol, @curs1_WhereClause;
	while @@FETCH_STATUS = 0
	begin
		--init
		set @cntTotal=-1;
		set @cntValid=-1;

		--Get Total Records
		set @sql = 'select @counter=count(*) from ' + @curs1_TABLENAME + ' where ExposureKey=' + cast(@ExposureKey as varchar) + @curs1_WhereClause;
		execute sp_executesql @sql,N'@counter int output',@counter output;
		set @cntTotal=isnull(@counter,0);

		--Get Valid Records
		if (@HasIsValidCol = 1) begin --If 1, append the IsValid=1 filter
			set @sql = @sql + ' and IsValid=1';
			execute sp_executesql @sql,N'@counter int output',@counter output;
		end
		set @cntValid=isnull(@counter,0);

		--first try to update it
		update ExposureCount
			set ValidCount = @cntValid, TotalCount = @cntTotal
			where CategoryID = @CategoryID
				and ExposureKey=@ExposureKey;

		--record does not exist, insert it
		if (@@rowcount = 0) begin
			insert ExposureCount (NodeKey, NodeType, ExposureKey, CategoryID, Category, TableName, ValidCount, TotalCount)
				values (@NodeKey, @NodeType, @ExposureKey, @CategoryID, @curs1_DISPLAYNAME, @curs1_TABLENAME, @cntValid, @cntTotal);
		end

		fetch next from curs1 into @CategoryID, @curs1_DISPLAYNAME, @curs1_TABLENAME, @HasIsValidCol, @curs1_WhereClause;
	end;
	close curs1;
	deallocate curs1;

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH

/*
exec absp_ExposureCountUpdate 1
select * from ExposureCount
*/
