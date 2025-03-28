if exists(select 1 from sysobjects where ID = object_id(N'absp_GenerateInsertDataByColumn') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateInsertDataByColumn
end
go

create procedure absp_GenerateInsertDataByColumn
	@table_Name varchar(120),
	@columnName varchar(8000),
	@inList     varchar(8000),
	@outputPath varchar(255) = 'C:',
	@outputTableName varchar(120)='',
	@outputFileName varchar(255)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    SQL2005
Purpose:
     This procedure generates a Result set and output file that contains
     the insert clause and data for the given table, column, and records matching the in list.
     The output filename is <table_Name>_<columnName>.txt.
     The generated insert commands can be directly executed using ISQL.

=================================================================================
</pre>
</font>
##FND_END

##PD @table_Name ^^ The table name for which the insert clause is to be generated
##PD @columnName ^^ The column name for which the insert clause is to be generated
##PD @inList ^^ The in list for the where clause
##PD @outputPath ^^ The output path, default is C:

##RD SQLCMD ^^ A result set of insert commands

*/
as
begin

    declare @columnList   varchar(max)
	declare @insertClause varchar(max)
	declare @me           varchar(max)
	declare @msg          varchar(max)
	declare @sql          varchar(max)
	declare @filename     varchar(max)
    declare @tableName    varchar(120)

	declare @indx int
	declare @name_len int
	declare @replNames varchar(max)
	declare @fieldNames varchar(max)
	declare @fieldType char(1)
	declare @sql1         varchar(max)
	declare @hasIdentity int
    -- init variables
	set @me = 'absp_GenerateInsertDataByColumn'
    set @columnList = ''

    exec absp_Util_Log_Info '-------- Begin --------', @me

	set @tableName = upper(@table_Name)

    -- select from DICTCOL
    if not exists (select 1 from DICTCOL where TABLENAME = @tableName and FIELDNAME = @columnName)
	begin
		set @msg = 'Error: Table ' + @tableName + '.' + @columnName + ' not found in DICTCOL'
        exec absp_MessageEx @msg
        select 'ERROR_' + @tableName + '.' + @columnName + '_NOT_IN_DICTCOL'
    end
    else
	begin

		-- create our tablename
		if @outputTableName=''
			set @outputTableName = @tablename
		else
			set @outputTableName = @outputTableName

		-- create our filename
		if @outputFileName=''
			set @filename = ltrim(rtrim(@outputPath)) + '\' + ltrim(rtrim(@outputTableName)) + '_' + ltrim(rtrim(@columnName)) + '.txt'
		else
			set @filename = ltrim(rtrim(@outputPath)) + '\' + @outputFileName + '.txt'

		-- create ordered column list
        select FIELDNUM, ltrim(rtrim(FIELDNAME)) as FIELDNAME into #tmp_1
			from DICTCOL where TABLENAME = @tableName order by FIELDNUM


		-- create CSV list
		set @sql = 'select FIELDNAME from #tmp_1'
		exec absp_Util_GenInListString @columnList output, @sql

		set @insertClause = 'insert into ' + ltrim(rtrim(@outputTableName)) + ' ( ' + ltrim(rtrim(@columnList)) + ' ) values ';

		-- replace commas with ticks and commas

		-- select properly formatted data from #tmp_2

		set @indx  = 1
		set @fieldNames = ''
		while @indx > 0
		begin
		select @indx = charindex(',',@columnList,-1)
		set @replNames = substring(@columnList,0,@indx)
		if (@indx = 0)
			  set @fieldNames = @fieldNames + @columnList + ' as ' + @columnList
		else
			  set @fieldNames = @fieldNames + @replNames +' as ' + @replNames +','
		select   @name_len = LEN(@columnList)
		select @columnList = right(@columnList,(@name_len -@indx))
		end

		if (len(@inList) < 1)
			set @sql = 'select ''' + @insertClause + '('' as expression1 ,'+ @fieldNames +' , '')'' as expression2  into tmp_2 from ' + @tableName;
		else
			set @sql = 'select ''' + @insertClause + '('' as expression1 ,'+ @fieldNames +' , '')'' as expression2  into tmp_2 from ' +
						@tableName + ' where ' + @columnName + ' in (' + @inList + ')';

		exec absp_Util_Log_Info @sql, @me
		execute(@sql)

		-- use unload/load table to preserve quotes on strings
		--SQL2005 does not support quotes on bcp queryout.So, we have added ticks before character type data
		--quotes on strings are required because field values are insert statement
		set @sql = 'select ''''''''+ expression1 + '''''''', '
		set @sql1 = 'select FIELDTYPE,FIELDNAME from dictcol where tablename = '''+@tableName +''' order by FIELDNUM asc'

		exec('declare curs_dictcol cursor global for '+ @sql1)
		open curs_dictcol
		fetch next from curs_dictcol into @fieldType,@fieldNames
		while @@fetch_status = 0
		begin

			if(@fieldType = 'B' or @fieldType = 'C' or @fieldType = 'V' )
				set @sql = @sql + '''''''''+'+ltrim(rtrim(@fieldNames))+'+'''''''' ,'
			else
				set @sql = @sql + ltrim(rtrim(@fieldNames)) + ','
		fetch next from curs_dictcol into @fieldType,@fieldNames
		end

		set @sql = @sql + ' expression2 , ''|'' from [@databaseName].dbo.tmp_2'
		close curs_dictcol
		deallocate curs_dictcol

		set @sql = replace(@sql, '@databaseName', DB_NAME());

		exec absp_Util_UnloadData 'q', @sql, @filename, ','

		if exists (select 1 from sysobjects where name = 'tmp_3')
			drop table tmp_3;

		create table tmp_3 (INSERT_CLAUSE varchar(max), ROW_NO int not null default 0)
        set @msg = 'if exists (select 1 from SYS.TABLES where NAME = ''' + ltrim(rtrim(@tableName)) + ''') begin'
		insert tmp_3 values (@msg, -999)

		--check required if table has identity column
		select @hasIdentity = isnull(objectproperty ( object_id(@tableName) , 'TableHasIdentity' ) , -1)
		if @hasIdentity = 1
			insert tmp_3(INSERT_CLAUSE) values ('set identity_insert '+ ltrim(rtrim(@tableName)) +' on')
		execute absp_Util_LoadData 'tmp_3', @filename, '|'

		-- strip extra quotes
		update tmp_3 set INSERT_CLAUSE=replace(dbo.trim(INSERT_CLAUSE),'''insert', '    insert')
		update tmp_3 set INSERT_CLAUSE=replace(dbo.trim(INSERT_CLAUSE),'('',', '(')
		update tmp_3 set INSERT_CLAUSE=replace(dbo.trim(INSERT_CLAUSE),',),',');')

		if @hasIdentity = 1
			insert tmp_3(INSERT_CLAUSE) values ('set identity_insert '+ ltrim(rtrim(@tableName)) +' off')
		insert tmp_3 values ('end ', 1000)

		-- unload to output file
		set @sql = 'select INSERT_CLAUSE from [@databaseName].dbo.tmp_3 order by ROW_NO';
		set @sql = replace(@sql, '@databaseName', DB_NAME());

		execute absp_Util_UnloadData 'q', @sql, @filename, '|'
		select INSERT_CLAUSE from tmp_3 order by ROW_NO
		drop table tmp_2
    end


    exec absp_Util_Log_Info '-------- End --------', @me

end
