if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewImportReportDelete') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_TreeviewImportReportDelete
end
go

create procedure absp_TreeviewImportReportDelete
	@exposureKey int
as

BEGIN TRY
	set nocount on;
	declare @sqlQuery nvarchar(max);
	declare @curs1_TblName varchar(100);

	if (@exposureKey < 1) begin --don't go any further.
		execute absp_Migr_RaiseError 1,'absp_TreeviewImportReportDelete: @exposureKey < 1';
	end

	declare curs1 cursor fast_forward for
		select TABLENAME from dbo.absp_Util_GetTableList('Import.Report');
	open curs1 FETCH NEXT FROM curs1 INTO @curs1_TblName
	while @@FETCH_STATUS = 0
	begin
		set @sqlQuery='delete ' + @curs1_TblName + ' where ExposureKey=' + cast(@exposureKey as varchar(30));
		execute(@sqlQuery);
		FETCH NEXT FROM curs1 INTO @curs1_TblName;
	end
	close curs1;
	deallocate curs1;
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
/*
exec absp_TreeviewImportReportDelete @exposureKey=1
*/
