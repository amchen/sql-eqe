if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateTableScript') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CreateTableScript
end
go

create procedure absp_Util_CreateTableScript
	@ret_sqlScript  varchar(max) output,
	@baseTableName  varchar(120) ,
	@newTableName   varchar(120) = '' ,
	@dbSpaceName    varchar(300) = '' ,
	@makeIndex      int = 0 ,
	@addDfltVal     int = 0 ,
	@autoKeyFlag    int = 0 ,
	@destDbName		varchar(300) = ''
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a SQL script in an OUTPUT parameter to create a table optionally in a given dbSpace. Inputs are
the base table name and the new table name. If the newTableName is empty, the baseTableName
is used. The procedure uses the table field definitions in DICTCOL.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @ret_sqlScript ^^ (OUTPUT PARAM)The SQL script to create a table optionally in a given dbSpace
##PD  @baseTableName ^^ Base Table Name as Input Parameter
##PD  @newTableName ^^ New Table Name as Input Parameter
##PD  @dbSpaceName  ^^ dbSpaceName as Input Parameter
##PD  @makeIndex    ^^ Whether To Include Create Index Script As Input Parameter
##PD  @addDfltVal   ^^ Whether To Add Default Value as Input Parameter
##PD  @autoKeyFlag  ^^ Whether To Add Auto Incremented Key as Input Parameter

*/
begin

	set nocount on
	set ANSI_PADDING on

	/*
	This will return an SQL script to create a table optionally in a given dbSpace.
	Inputs are the base table name and the new table name.
	If the newTableName is empty, the baseTableName is used.
	The procedure uses the table field definitions in DICTCOL.

	makeIndex = 0, do not include create index script
	makeIndex = 1, include create index script
	makeIndex = 2, only create index script
	*/
	declare @sSql              varchar(max)
	declare @sSql2             varchar(max)
	declare @sSql3             varchar(max)
	declare @columnlist	       varchar(8000)
	declare @targetTableName   varchar(120)
	declare @dfltString        varchar(40)
	declare @NonClustered	   varchar(20)

	declare @msg               varchar(255)
	declare @curs2_FNAME       varchar(120)
	declare @curs2_FIELDWIDTH  smallint
	declare @curs2_FIELDTYPE   char(1)
	declare @curs2_DEFAULTVAL  varchar(15)
	declare @curs2_NULLABLE    char(1)
	declare @curs2_FIELDSTRING varchar(80)
	declare @curs2_NULLSTRING  varchar(40)
	declare @curs3_NDX         varchar(300)
	declare @curs3_ISU         char(1)
	declare @curs3_ISCL        char(1)

	create table #IDXSORTED
	(
		TABLENAME   varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS,
		INDEXNAME   varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ISUNIQUE    char(1)      COLLATE SQL_Latin1_General_CP1_CI_AS,
		ISCLUSTERED char(1)      COLLATE SQL_Latin1_General_CP1_CI_AS
	)

	set @baseTableName = rtrim(ltrim(@baseTableName))
	set @dbSpaceName = rtrim(ltrim(@dbSpaceName))

	-- return error string if @baseTableName does not exist in DICTTBL
	if not exists(select 1 from DICTTBL where TABLENAME = @baseTableName)
	begin
		set @msg = 'Error: Table ' + @baseTableName + ' not found in DICTTBL'
		execute absp_MessageEx @msg
		set @sSql = 'Util_CreateTableScript_ERROR_' + @baseTableName + '_NOT_IN_DICTTBL'
		set @ret_sqlScript = @sSql
		return
	end

	-- return error string if @baseTableName does not exist in DICTCOL
	if not exists(select 1 from DICTCOL where TABLENAME = @baseTableName)
	begin
		set @msg = 'Error: Table ' + @baseTableName + ' not found in DICTCOL'
		execute absp_MessageEx @msg
		set @sSql = 'Util_CreateTableScript_ERROR_' + @baseTableName + '_NOT_IN_DICTCOL'
		set @ret_sqlScript = @sSql
		return
	end

	-- handle case we do not need a separate target table
	set @targetTableName = @newTableName
	if len(@targetTableName) = 0
	begin
		set @targetTableName = @baseTableName
	end

	-- check if table has a clustered index
	if exists (select 1 from DICTIDX where ISCLUSTER='Y' and TABLENAME=@baseTableName)
		begin
			set @NonClustered = 'NONCLUSTERED '
		end
	else
		begin
			set @NonClustered = ''
		end

	-- begin our create SQL statement
	if @destDbName = ''
		set @sSql = 'SET ANSI_PADDING OFF;SET ANSI_NULL_DFLT_ON ON;SET ANSI_NULLS ON;'
	else
	begin
		-- make sure the database is bracketed since it can contain spaces
		set @destDbName = replace(@destDbName,'[','')
		set @destDbName = replace(@destDbName,']','')
		set @destDbName = '[' + @destDbName + ']'
		set @sSql = 'use ' + @destDbName + ' SET ANSI_PADDING OFF;SET ANSI_NULL_DFLT_ON ON;SET ANSI_NULLS ON;'
	end

	set @sSql = @sSql + ' create table ' + Ltrim(Rtrim(@targetTableName)) + ' ('

	-- add auto incrementing key as first column
	if (@autoKeyFlag > 0)
	begin
		set @sSql = @sSql + ' AUTOKEY_IPKDA, '
	end

	-- for each table, get its field parameters
	declare curs2 cursor FAST_FORWARD FOR
		select rtrim(ltrim(FIELDNAME)) as FNAME, FIELDWIDTH, FIELDTYPE,
            rtrim(DEFAULTVAL) as DEFAULTVAL, NULLABLE,
			case FIELDTYPE
				when 'A' then 'INT IDENTITY(1,1)'
				when 'B' then 'VARBINARY (MAX) '
                when 'C' then
                    case when FIELDWIDTH > 1 then
						'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH))) + ') '
                    else
                        'CHAR (1) '
                    end
				when 'F' then 'FLOAT (24) '
				when 'G' then 'FLOAT (53) '
				when 'I' then 'INT '
				when 'K' then 'INT '
				when 'N' then 'BIGINT '
				when 'S' then 'SMALLINT '
				when 'T' then 'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH))) + ') '
				when 'U' then 'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH + 10))) + ') '
				when 'V' then case when FIELDWIDTH >= 6000 then 'VARCHAR (MAX) ' else 'VARCHAR (5999) ' end
			end as FIELDSTRING,
			case NULLABLE
				when 'N' then 'NOT NULL ' else ''
			end as NULLSTRING

		from DICTCOL
		where TABLENAME = @baseTableName
		order by FIELDNUM asc

	-- Check if default value is required, then set the default value from DICTCOL.DEFAULTVAL field
	-- else set the default value for FieldType 'A', 'G', 'I', 'S'. The addDfltVal is implemented to use
	-- from absp_QA_MakeWCeUnitPPort
	open curs2
		fetch next from curs2 into
		@curs2_FNAME,
		@curs2_FIELDWIDTH,
		@curs2_FIELDTYPE,
		@curs2_DEFAULTVAL,
		@curs2_NULLABLE,
		@curs2_FIELDSTRING,
		@curs2_NULLSTRING

		while @@FETCH_STATUS = 0
		begin
			set @dfltString = ISNULL(@curs2_DEFAULTVAL, '')

			if (@dfltString = '[N/A]' or @dfltString = 'NA')
				set @dfltString = ''

			if (@curs2_FIELDTYPE = 'A' or @curs2_FIELDTYPE = 'B')
				begin
					-- No default values for these types
					set @dfltString = ''
				end
			else if (@curs2_FIELDTYPE = 'C' or @curs2_FIELDTYPE = 'K' or @curs2_FIELDTYPE = 'T' or @curs2_FIELDTYPE = 'V')
				begin
					set @dfltString = 'DEFAULT ''' + ltrim(rtrim(@dfltString)) + ''''
				end
			else
				begin
					if (@dfltString = '') set @dfltString = '0';
					set @dfltString = 'DEFAULT ' + ltrim(rtrim(@dfltString)) + '';
				end

			set @sSql = @sSql + @curs2_FNAME + ' ' + @curs2_FIELDSTRING + rtrim(@dfltString) + ', ';

			fetch next from curs2 into
				@curs2_FNAME,
				@curs2_FIELDWIDTH,
				@curs2_FIELDTYPE,
				@curs2_DEFAULTVAL,
				@curs2_NULLABLE,
				@curs2_FIELDSTRING,
				@curs2_NULLSTRING
		end
	close curs2
	deallocate curs2

	if (@autoKeyFlag > 0)
		set @sSql2 = ''
	else
		-- Get primary key
		exec absp_Util_CreateTableScriptPK @sSql2 output, @baseTableName, @newTableName, @isAlterTable=0

	if len(@sSql2) > 0
		set @sSql = @sSql + @sSql2 + ')'
	else
		-- at end of loop we have dangling comma , so remove it
		set @sSql = left(@sSql, len(ltrim(rtrim(@sSql))) - 1) + ')'

	-- replace auto incrementing key
	if (@autoKeyFlag > 0)
	begin
		set @sSql = replace(@sSql, 'PRIMARY KEY ', '')
		set @sSql = replace(@sSql, 'AUTOKEY_IPKDA', 'AUTOKEY INTEGER IDENTITY(1,1) PRIMARY KEY')
	end

	if (@dbSpaceName <> '')
	begin
		if not exists(select 1 from SYSFILEGROUPS where GROUPNAME = @dbSpaceName)
		begin
			-- no such dbspace name
			set @sSql = ''
			set @ret_sqlScript = @sSql
			return
		end
		set @sSql = @sSql + ' ON ' + @dbSpaceName
	end

	-- if we need to create the index script, add it here
	if (@makeIndex > 0)
	begin
		-- makeIndex = 2 means return just the create index script
		if @makeIndex = 2
			begin
				set @sSql = ''
			end
		else
			begin
				set @sSql = @sSql + '; '
			end

		-- get each distinct index name order by name
		truncate table #IDXSORTED
		insert into #IDXSORTED
			select TABLENAME, INDEXNAME, ISUNIQUE, ISCLUSTER
				from DICTIDX
				where TABLENAME = @baseTableName
				  and IsInclude <> 'Y'
				  and IsPrimary <> 'Y'
				order by INDEXNAME asc

		-- get each sorted distinct index name
		declare curs3 cursor fast_forward for
			select distinct rtrim(ltrim(INDEXNAME)) as NDX, ISUNIQUE as ISU, ISCLUSTERED as ISCL
				from #IDXSORTED
				where TABLENAME = @baseTableName
				order by NDX, ISCL, ISU asc

		open curs3
			fetch next from curs3 into @curs3_NDX, @curs3_ISU, @curs3_ISCL

			while @@FETCH_STATUS = 0
			begin
				set @sSql = @sSql + 'CREATE '

				if (@curs3_ISU = 'Y') begin
					set @sSql = @sSql + 'UNIQUE '
				end

				if (@curs3_ISCL = 'Y') begin
					set @sSql = @sSql + 'CLUSTERED '
				end

				set @sSql =	@sSql + 'INDEX ' + @curs3_NDX + ' ON ' + @targetTableName

				-- start the SQL statement
				set @sSql2 = ' ( @columnlist )';

				-- create comma separated list
				set @columnlist = NULL;
				select @columnlist = COALESCE(@columnlist + ',', '') + t.FieldName
				  from DictIdx t
				  where IndexName = @curs3_NDX
				    and IsInclude <> 'Y'
				    and IsPrimary <> 'Y'
				  order by FieldOrder

				-- replace @values
				set @sSql2 = replace(@sSql2, '@columnlist', @columnlist);

				if (@dbSpaceName <> '')
				begin
					if not exists(select 1 from SYSFILEGROUPS where GROUPNAME = @dbSpaceName)
					begin
						-- no such dbspace name
						set @sSql = ''
						set @ret_sqlScript = @sSql
						return
					end
					set @sSql = @sSql + ' ON ' + @dbSpaceName
				end

				-- get INCLUDE columns for the index
				exec absp_Util_CreateIndexIncludeScript @sSql3 output, @curs3_NDX

				set @sSql = @sSql + @sSql2 + @sSql3 + ';';

				fetch next from curs3 into @curs3_NDX, @curs3_ISU, @curs3_ISCL
			end
		close curs3
		deallocate curs3
	end
	-- end of make index

	drop table #IDXSORTED

	-- return the resulting script
	set @ret_sqlScript = ltrim(rtrim(@sSql))
	set ANSI_PADDING off

end
