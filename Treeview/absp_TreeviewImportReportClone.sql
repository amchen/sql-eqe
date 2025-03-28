if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewImportReportClone') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewImportReportClone
end
go

create procedure absp_TreeviewImportReportClone
	@sourceExposureKey int,
	@targetExposureKey int,
	@targetDB varchar(130)=''
as

BEGIN TRY
   set nocount on;
   declare @sql nvarchar(max);
   declare @curs1_TblName varchar(100);
   declare @tabSep varchar(10);
   declare @whereClause  varchar(max);
   declare @newFldValueTrios varchar(max);
   declare @hasIdentity int;

	if (@sourceExposureKey < 1) begin --don't go any further.
		execute absp_Migr_RaiseError 1,'absp_TreeviewImportReportClone: @sourceExposureKey < 1';
	end
	if (@targetExposureKey < 1) begin --don't go any further.
		execute absp_Migr_RaiseError 1,'absp_TreeviewImportReportClone: @targetExposureKey < 1';
	end

   if (@targetDB = '')
      set @targetDB = DB_NAME();

    --Enclose within square brackets--
    execute absp_getDBName @targetDB out, @targetDB;

	set @whereClause = 'ExposureKey = '+cast(@sourceExposureKey as varchar(30));
	execute absp_GenericTableCloneSeparator @tabSep output;
	set @newFldValueTrios = 'INT'+@tabSep+'ExposureKey'+@tabSep+cast(@targetExposureKey as varchar(30));

	declare curs1 cursor DYNAMIC for
		select TABLENAME from dbo.absp_Util_GetTableList('Import.Report');
	open curs1 FETCH NEXT FROM curs1 INTO @curs1_TblName
	while @@FETCH_STATUS = 0
		begin
			select @hasIdentity = ISNULL(OBJECTPROPERTY(OBJECT_ID(@curs1_TblName), 'TableHasIdentity'), 0); --assumes identity column will always be first.
			execute absp_GenericTableCloneRecords @curs1_TblName, @hasIdentity, @whereClause, @newFldValueTrios, 0, @targetDB, 0;
			FETCH NEXT FROM curs1 INTO @curs1_TblName;
		end
	Close curs1;
	Deallocate curs1;
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
/*
absp_TreeviewImportReportClone @sourceExposureKey=2, @targetExposureKey=1234, @targetDB='build_d23'
*/
