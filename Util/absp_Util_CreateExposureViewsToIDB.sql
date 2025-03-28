if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateExposureViewsToIDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateExposureViewsToIDB;
end
go

create procedure absp_Util_CreateExposureViewsToIDB
	@JobKey integer = 0

/*
====================================================================================================
Purpose:	This procedure drops tables in Exposure.Report list in EDB and creates views
			to respective tables in IDB.
Returns:	None
====================================================================================================
*/

AS
begin
	set nocount on;

	declare @sql nvarchar(1000);
	declare @curTable varchar(120);
	declare @IDBname varchar(128);
	declare @strText varchar(200);

	-- This is only executed on the EDB
	if exists (select 1 from RQEVersion where DbType='EDB' and RQEVersionKey=1)
	begin

		set @IDBname = DB_NAME() + '_IR';

		-- check if views need to be recreated
		select @strText = OBJECT_DEFINITION(object_id('ExposureValue'));
		set @strText = ISNULL(@strText, '');

		if (select charindex(@IDBname, @strText)) = 0
		begin

			declare MyCursor cursor fast_forward for
				select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Report') where TableName <> 'ExposureReport';

			open MyCursor
			fetch next from MyCursor into @curTable
			while @@fetch_status = 0
			begin

				-- drop tables in EDB
				if exists (select 1 from sys.tables where name = @curTable)
				begin
					set @sql = 'drop table ' + @curTable;
					print @sql;
					exec sp_executesql @sql;
				end

				-- drop views to IDB (in case the database name was changed)
				if exists (select 1 from sys.views where name = @curTable)
				begin
					set @sql = 'drop view ' + @curTable;
					print @sql;
					exec sp_executesql @sql;
				end

				-- create views to IDB
				if not exists (select 1 from sys.views where name = @curTable)
				begin
					set @sql = 'create view @curTable as select * from [@IDBname]..@curTable';
					set @sql = replace(@sql,'@IDBname',@IDBname);
					set @sql = replace(@sql,'@curTable',@curTable);
					print @sql;
					exec sp_executesql @sql;
				end

				fetch next from MyCursor into @curTable;

			end

			close MyCursor;
			deallocate MyCursor;
		end
	end
end

-- exec absp_Util_CreateExposureViewsToIDB;
