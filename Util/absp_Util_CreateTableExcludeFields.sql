if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CreateTableExcludeFields') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateTableExcludeFields
end
go

create procedure absp_Util_CreateTableExcludeFields
	@ret_TblName    varchar(max) output,
	@baseTableName1 varchar(120),
	@newTableName   varchar(120) = '',
	@excludeFields  varchar(255) = '',
	@debug          int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This will create a randomized temporary table from a given base table, excluding the
unwanted fields and returns the new table name created

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_TblName ^^ The name of the created table. Output parameter.
##PD  @baseTableName ^^ The name of the table based on which the new table will be created
##PD  @newTableName ^^ The name based on which the new table name will be generated.
##PD  @excludeFields ^^ A set of fields of the base table that are to be excluded in the new table
##PD  @debug ^^ The debug flag.
*/
as
begin

   set nocount on

   set ANSI_PADDING on

  /*
  This will create a randomized temporary table
  optionally to exclude unwanted fields.
  Inputs are the base table name and the new table name.
  If the newTableName is empty, the baseTableName is used.
  The procedure uses the table field definitions in DICTCOL.
  */
   declare @customCols      varchar(max)
   declare @baseTableName   varchar(120)
   declare @dfltString      varchar(40)
   declare @targetTableName varchar(120)
   declare @retTableName    varchar(max)
   declare @msgTxt          varchar(max)
   declare @fName           varchar(120)
   declare @fieldWidth      smallint
   declare @fieldType       char(1)
   declare @defaultVal      varchar(100)
   declare @nullable        char(1)
   declare @fieldString     varchar(100)
   declare @nullString      varchar(100)
   declare @NonClustered    varchar(20)


   if (@debug = 1)
   begin
      set @msgTxt = 'excludeFields=' + @excludeFields
      execute absp_MessageEx @msgTxt
   end

   set @baseTableName = rtrim(ltrim(@baseTableName1))

   -- return error string if @baseTableName does not exist in DICTTBL
   if not exists(select  1 from DICTTBL where TABLENAME = @baseTableName)
   begin
      set @msgTxt = 'Error: Table ' + @baseTableName + ' not found in DICTTBL'
      execute absp_MessageEx @msgTxt
      set @customCols = 'ERROR_' + rtrim(ltrim(@baseTableName)) + '_NOT_IN_DICTTBL'
      set @ret_TblName = @customCols
      return
   end

   -- return error string if @baseTableName does not exist in DICTCOL
   if not exists(select  1 from DICTCOL where TABLENAME = @baseTableName)
   begin
      set @msgTxt = 'Error: Table ' + @baseTableName + ' not found in DICTCOL'
      execute absp_MessageEx @msgTxt
      set @customCols = 'ERROR_' + rtrim(ltrim(@baseTableName)) + '_NOT_IN_DICTCOL'
      set @ret_TblName = @customCols
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
   set @customCols = ''

   -- for each table, get its field parameters

   -- Check if default value is required, then set the default value from DICTCOL.DEFAULTVAL field
   -- else set the default value for FieldType 'A', 'G', 'I', 'S'.
   declare curs2 cursor LOCAL FAST_FORWARD for
		select rtrim(ltrim(FIELDNAME)) as FNAME, FIELDWIDTH, FIELDTYPE,
			rtrim(DEFAULTVAL), NULLABLE,
			case FIELDTYPE
			   when 'A' then 'INT IDENTITY(1,1) PRIMARY KEY ' + @NonClustered
			   when 'B' then 'VARBINARY (MAX) '
               when 'C' then
                    case when FIELDWIDTH > 1 then
                        case when COLSUBTYPE = 'U' then
                            'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH + 10))) + ') '
                        else
                            'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH))) + ') '
                        end
                    else
                        'CHAR (1) '
                    end
			   when 'F' then 'FLOAT (24) '
			   when 'G' then 'FLOAT (53) '
			   when 'I' then 'INT '
			   when 'K' then 'INT PRIMARY KEY ' + @NonClustered
			   when 'N' then 'BIGINT '
			   when 'S' then 'SMALLINT '
			   when 'T' then 'VARCHAR (' + rtrim(ltrim(str(FIELDWIDTH))) + ') '
			   when 'V' then case when FIELDWIDTH >= 6000 then 'VARCHAR (MAX) ' else 'VARCHAR (5999) ' end
			   end as FIELDSTRING,
			case when NULLABLE = 'N' then 'NOT NULL ' else ''
			end as NULLSTRING

		from DICTCOL
		where TABLENAME = @baseTableName
		order by FIELDNUM asc

   open curs2
   fetch next from curs2 into
		@fName,
		@fieldWidth,
		@fieldType,
		@defaultVal,
		@nullable,
		@fieldString,
		@nullString

   while @@fetch_status = 0
   begin

	if(charindex(ltrim(rtrim(@fName)),ltrim(rtrim(@excludeFields))) = 0)
	begin

		set @dfltString = ISNULL(@defaultVal, '')

		if (@dfltString = '[N/A]' or @dfltString = 'NA')
			set @dfltString = ''

		if (@fieldType = 'A' or @fieldType = 'B' or @fieldType = 'K')
			begin
				-- No need to set the default since its already set in the select query
				set @dfltString = ''
				set @nullable = 'Y'
			end
		else if (@fieldType = 'C' or @fieldType = 'T' or @fieldType = 'V')
			begin
				set @dfltString = 'DEFAULT ''' + ltrim(rtrim(@dfltString)) + ''''
			end
		else
			begin
				if (@dfltString = '')
					set @dfltString = '0';

				set @dfltString = 'DEFAULT ' + ltrim(rtrim(@dfltString)) + '';
			end

		set @customCols = @customCols + @fName + ' ' + @fieldString + rtrim(@dfltString) + ', ';
   	end

		fetch next from curs2 into
			@fName,
			@fieldWidth,
			@fieldType,
			@defaultVal,
			@nullable,
			@fieldString,
			@nullString
	end

   close curs2
   deallocate curs2

   -- at end of loop we have dangling comma , so remove it
   if (@customCols <> '')
   begin
     set @customCols = left(@customCols, len(@customCols) - 1)
   end

   if (@debug = 1)
   begin
      set @msgTxt = 'excludeFields=' + @customCols
      execute absp_MessageEx @msgTxt
   end

   execute absp_Util_MakeCustomTmpTable @retTableName output, @targetTableName, @customCols

   set @ret_TblName = rtrim(ltrim(@retTableName))

   set ANSI_PADDING off

end
