if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CopyCurrInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CopyCurrInfo
end
go

create procedure absp_Util_CopyCurrInfo
    @rc varchar(255) output,
    @sourceDb varchar(255),
    @destDb varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure copies currency, exchange rate, and user lookups from the source database to the 
destination database 

Returns:      successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDb ^^ copy exchrate data etc. from this database
##PD  @destDb ^^  to this database


##RD  @rc ^^ successful or error messages.
*/
AS
begin

	set nocount on

	declare @cmd varchar(max)
	declare @status int
	declare @tableName varchar(255)
	declare @collist varchar(max)
	declare @cloneName varchar(255)
	declare @baseTblName varchar(255)

	-- start of stuff for testing
	-- declare @sourceDb varchar(255)
	-- declare @destDb varchar(255)
	-- declare @rc varchar(255)
	
	-- set @sourceDb = 'BigCanOfWorms'
	-- set @destDb = 'BestCanDo'
	-- end of stuff for testing
	set @rc = ''
	set @status = 0

	-- use a temp table to hold table names in the correct order to avoid foreign key constraint violations
	if exists (select 1 from tempdb..sysobjects where id = OBJECT_ID('tempdb.dbo.#CurrInfoTableNames')) 
	begin 
		drop table #CurrInfoTableNames 
	end

	create table #CurrInfoTableNames (orderId int identity, tablename varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS)

	-- do separate inserts to get correct order for tables with foreign key constraints
	insert into #CurrInfoTableNames (tablename) values ('EXCHRATE');
	insert into #CurrInfoTableNames (tablename) values ('CURRINFO');

	-- insert the other tables 
	insert into #CurrInfoTableNames (tablename) 
		select TABLENAME from dbo.absp_Util_GetTableList('Currency.Info')

	--insert lookups
	insert into #CurrInfoTableNames (TABLENAME) select CLONENAME from DICTCLON where CF_DB in('Y','L')

	--insert autolookups
	insert into #CurrInfoTableNames (TABLENAME) 	
		select TABLENAME from DICTLOOK where TABLENAME not in (select TABLENAME from DICTCLON)
 
	begin try
		begin transaction

			declare curs cursor local fast_forward 
			for
				select TABLENAME from #CurrInfoTableNames order by orderId asc 

			open curs 
			fetch next from curs into @tableName 
			while @@fetch_status  = 0 	
			begin 
				set @cmd =  'if exists (select 1 from [' + @destDb + '].Sys.Tables where name = '''+@tableName+''') '
				set @cmd = @cmd + 'delete from [' + @destDb + '].dbo.' + @tableName
				exec (@cmd)
				fetch next from curs into @tableName  	
			end 
			close curs 
			deallocate curs 

			declare curs2 cursor local fast_forward 
			for
				select TABLENAME from #CurrInfoTableNames order by orderId desc 

			open curs2 
			fetch next from curs2 into @tableName 
			while @@fetch_status  = 0 	
			begin 

				set @cmd = ''
				set @baseTblName=''

				--For _U table get basetablename
				select @baseTblName = TABLENAME from DICTCLON where CLONENAME = @tableName
				if @baseTblName = ''
					set @baseTblName=@tableName
				--Check if table exists
				set @cmd =  'if exists (select 1 from [' + @destDb + '].Sys.Tables where name = '''+@tableName+''') '
				
				if exists (select 1 from dictcol where fieldtype = 'A' and tablename = @tableName)
				begin
					set @cmd = @cmd + 'set identity_insert [' + @destDb + '].dbo.' + @tableName + ' on ;'
				end

				-- get list of columns for this table
				set @collist = ''
				exec absp_Migr_GenReloadTableList @collist output, @baseName = @baseTblName
				
				-- build insert statement and run it
				set @cmd = @cmd + ' insert into [' + @destDb + '].dbo.' + @tableName + 
					' (' + @collist +
				  	') select * from ' + '[' + @sourceDb + '].dbo.' + @tableName  
				exec (@cmd)

				fetch next from curs2 into @tableName  	
			end 
			close curs2 
			deallocate curs2 

			-- Mantis 427 fixup currency schema key in destination database
			set @cmd = 'update [' + @destDb + '].dbo.fldrinfo set currsk_key = (select currsk_key from [' + @sourceDb +
			     	'].dbo.fldrinfo where longname = ''' + @sourceDb + ''') where longname = ''' + @destDb	+ ''''
			exec (@cmd)
			set @cmd = 'update commondb.dbo.cfldrinfo set currsk_key = (select currsk_key from [' + @sourceDb +
			     	'].dbo.fldrinfo where longname = ''' + @sourceDb + ''') where longname = ''' + @destDb	+ ''''
			exec (@cmd)

			-- copy analysis model selections 
			set @cmd = 'delete from [' + @destDb + ']..AnalysisModelSelection'
			exec (@cmd)
			set @cmd = 'insert into [' + @destDb + ']..AnalysisModelSelection select * from [' + @sourceDb + ']..AnalysisModelSelection'
			exec (@cmd) 
		commit

	end try
	begin catch
		rollback
		set @rc = 'Error importing settings from  ' + @sourceDb + ' to ' + @destDb + ': ' + ERROR_MESSAGE()
		set @status = -1
	end catch

	return @status
end
