if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_Util_UnloadData') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_Util_UnloadData;
end
go

create procedure  absp_Util_UnloadData
    @unloadType     char(1),
    @unloadText     varchar(MAX),
    @outFile        varchar(255),
    @delimiter      varchar(2) = '|',
    @whereClause    varchar(255) = '',
    @groupByClause  varchar(255) = '',
    @havingClause   varchar(255) = '',
    @orderByClause  varchar(255) = '',
    @excludeColumns varchar(255) = '',
	@userName		varchar(100) = '',
	@password		varchar(100) = ''
/*
====================================================================================================
Purpose:        This procedure will unload data from a table or query to an outfile.
				If an unload query is passed in, all database objects must be fully-qualified,
				database.dbo.table, since it is executed as is with the following exception:
					For ASA, .dbo. is replace with .dba.
					For SQL2005, .dba. is replaced with .dbo.
                There are optional parameters for where clause, group by clause, having clause,
                order by clause, and columns to exclude, are only applicable to unload table.
                The char columns will be rtrim() to remove trailing spaces.
Returns:        0 on success, non-zero on failure

Example:        exec absp_Util_UnloadData
                    @unloadType='t',
                    @unloadText='esdl',
                    @outFile='c:\esdl_unload.txt',
                    @excludeColumns='USER_EQ_ID,COMP_DESCR,STORY_MIN,STORY_MAX',
                    @whereClause='str_eq_id > 9000 and str_eq_id < 9020 and country_id=''00''',
                    @orderByClause='STR_EQ_ID desc'
====================================================================================================

##PD  @unloadType ^^ The unload type, T for table, Q for query
##PD  @unloadText ^^ The table name or query based on the unload type
##PD  @outFile ^^ The output filename, must be fully-qualified by drive letter or UNC path
##PD  @delimiter ^^ The delimiter character for the outfile, default is bar "|"
##PD  @whereClause ^^ An optional where clause
##PD  @groupByClause ^^ An optional group by clause
##PD  @havingClause ^^  An optional having clause
##PD  @orderByClause ^^ An optional order by clause
##PD  @excludeColumns ^^ Optional columns to exclude from a table
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication
*/
as
begin

    declare @me             varchar(255);    -- Procedure Name
    declare @msg            varchar(max);
    declare @sSql           varchar(7999);   -- xp_cmdshell only works with varchar(num), not varchar(max)
    declare @columnName     varchar(100);
    declare @columnType     varchar(20);
    declare @dbName         varchar(255);
    declare @dbNameString   varchar(255);
    declare @dbNameBracket  varchar(255);
    declare @hostName       varchar(255);
    declare @excludeCols    varchar(500);
    declare @rowCount       int;
    declare @maxRows        int;
    declare @retCode        int;
    declare @bFirstColumn   bit;

    declare @pos            int;
    declare @tpos           int;
    declare @dot            int;
    declare @tname          varchar(max);
    declare @outputFile     varchar(255);
    declare @use_xpcs       int;

    set NOCOUNT ON;

    set ANSI_PADDING on;

    set IMPLICIT_TRANSACTIONS OFF;
    set @delimiter = ltrim(rtrim(@delimiter));
    set @retCode = 1;
    set @me = 'absp_Util_UnloadData';
    set @msg = @me + ': starting';
    exec absp_Util_Log_Info @msg, @me;

    -- create temp table
    create table #TMPCOLUMNS (
        COLNO int IDENTITY (1,1) PRIMARY KEY NOT NULL,
        CNAME varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
        CTYPE varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
        CLENGTH int
    );

    -- get database name
    set @dbName = db_name();
    set @dbNameString = @dbName;
    set @dbNameBracket = '[' + @dbName + ']';

    -- unload via Table
    if (upper(@unloadType) = 'T')
    begin
        -- get column names and types
        set @sSql = 'insert into #TMPCOLUMNS (CNAME, CTYPE, CLENGTH) select NAME as CNAME, TYPE_NAME(USER_TYPE_ID) as CTYPE, convert(int, MAX_LENGTH) as CLENGTH ' +
                    'from SYS.ALL_COLUMNS ' +
                    'where OBJECT_ID = OBJECT_ID(''' + @unloadText + ''') ';

        if (len(@excludeColumns) > 0)
        begin
            set @excludeCols = '''' + replace(@excludeColumns, ',', ''',''') + '''';
            set @sSql = @sSql + 'and NAME not in (' + @excludeCols + ') ';
        end

        set @sSql = @sSql + 'order by COLUMN_ID asc';
        execute(@sSql);

        -- build the select query
        set @sSql = 'select ';
        set @bFirstColumn = 1;
        set @rowCount = 1;

        select @maxRows = max(COLNO) from #TMPCOLUMNS;

        while (@rowCount <= @maxRows)
        begin
            select @columnName = CNAME, @columnType = CTYPE from #TMPCOLUMNS where COLNO = @rowCount;

            if (@bFirstColumn = 0)
            begin
                set @sSql = @sSql + ',';
            end

            if (charindex('char', @columnType) > 0)
            begin
                set @sSql = @sSql + ' case when len (' + @columnName + ') > 0 then rtrim(' + @columnName + ') else '' '' end ';
            end
            else
            begin
                set @sSql = @sSql + @columnName;
            end
            set @bFirstColumn = 0;
            set @rowCount = @rowCount + 1;
        end

        -- add from table clause
        set @sSql = @sSql + ' from ' + @dbNameBracket + '.dbo.' + @unloadText;

        -- add where clause
        if (len(@whereClause) > 1)
        begin
            set @sSql = @sSql + ' where ' + @whereClause;
        end

        -- add group by clause
        if (len(@groupByClause) > 1)
        begin
            set @sSql = @sSql + ' group by ' + @groupByClause;
        end

        -- add having clause
        if (len(@havingClause) > 1)
        begin
            set @sSql = @sSql + ' having ' + @havingClause;
        end

        -- add order by clause
        if (len(@orderByClause) > 1)
        begin
            set @sSql = @sSql + ' order by ' + @orderByClause;
        end

        drop table #TMPCOLUMNS;

        set @unloadType = 'Q';
        set @unloadText = @sSql;
    end

    -- unload via Query
    if (upper(@unloadType) = 'Q')
    begin
		-- replace database owner with correct user name for DBMS
		set @unloadText = replace(@unloadText, '.dba.', '.dbo.');
		set @unloadText = replace(@unloadText, '.DBA.', '.dbo.');
		set @unloadText = replace(@unloadText, '..', '.dbo.');

		-- check if table names in the query are fully-qualified,
		-- the query may have multiple tables separated by commas or subqueries
		-- We cannot remove extra blanks since the database name can have two or
		-- more embedded blanks and this causes the bcp not to work
        set @unloadText = replace(replace(replace(@unloadText,' , ', ','),' ,', ','), ', ', ',');

        set @dbName = @dbNameBracket + '.dbo.';

		set @pos=0;
		while @pos<=len(@unloadText)
		begin
			--search for tablename
			set @pos=charindex(' from ', @unloadText,@pos+1);
			if @pos=0
				break;
            --there may/may not be a Clause
			if charindex(' ',@unloadText,@pos+6)=0
				set @tName=ltrim(substring(@unloadText,@pos+6,len(@unloadText)));
		    else
        		set @tName=ltrim(substring(@unloadText,@pos+6,(charindex(' ',@unloadText,@pos+6)-(@pos+6))));

			--If not fully qualified, add dbName and dbOwnerName
			set @dot=charindex('.', @unloadText);
			if @dot>0
				set @dot=charindex('.', @unloadText,@dot+1);
			if @dot=0
			begin
				set @tname=@dbName+@tname;
			end

			--There may be multiple comma separated tables
			set @tpos=0;
			while @tpos <=len(@tname)
			begin
				set @tpos =charindex(',',@tname,@tpos+1);
				if @tpos=0
					break;
				if substring(@tname,@tpos+1,len(@dbName))<>@dbName
					set @tname=substring(@tname,1,@tpos)+@dbName+substring(@tname, @tpos+1, len(@tname));
			end
			if charindex(' ',@unloadText,@pos+6)=0
				set @unloadText = substring(@unloadText,1,@pos+5) +@tname;
			else
			    set @unloadText = substring(@unloadText,1,@pos+5) +@tname + substring(@unloadText,charindex(' ',@unloadText,@pos+6),len(@unloadText));
	   	end
        -- get hostname
        select @hostName = @@servername;

		set @outputFile = @outFile;
		if (right(@outFile, 1) <> '"' and left(@outFile, 1) <> '"')
			set @outputFile = '"' + @outFile + '"';

		exec @use_xpcs = absp_Util_IsUseXPCmdShell;

		if (@use_xpcs = 1)
		begin
			-- build xp_cmdshell execution string

			-- SDG__00021748 -- We Extract 2 Valid Records During a SQL Server Import for the Following File, "4 Records in SVK - 2 good 2 bad.txt"
			-- The file has two records having a LOCATOR with accented characters.
			-- In order to retain the accented characters, the code page must be changed.   Use -C1252 to change the code page to 1252.

			set @sSql = 'bcp "' + @unloadText + '" queryout ' + @outputFile + ' -S ' + @hostName + ' -c -C1252 -t "' + @delimiter + '"';

			exec absp_Util_Log_Info 'The bcp statement without authentication information :', @me;
			exec absp_Util_Log_Info @sSql, @me;

			if len (@userName)>0 and len (@password)>0
				set @sSql = @sSql + ' -U ' + @userName + ' -P ' + @password;
			else
				set @sSql = @sSql + ' -T';

			-- execute the unload via xp_cmdshell
			exec @retCode = xp_cmdshell @sSql, no_output;
		end
		else
		begin
			-- execute the unload vis CLR
			exec @retCode = systemdb.dbo.clr_Util_UnloadData @unloadText, @outFile, @delimiter, 0, 0, @hostName, @dbNameString, @userName, @password;
			set @msg = 'exec @retCode = systemdb.dbo.clr_Util_UnloadData ''' + @unloadText + ''',''' + @outFile + ''',''' + @delimiter +
			           ''',0,0,''' + @hostName + ''',''' + @dbNameString + ''',''' + @userName + ''',''' + @password + ''';';

			if (@retCode <> 0)
			begin
				exec absp_Util_Log_Info @msg, @me;
				select systemdb.dbo.clr_Util_GetError(@retCode);
			end
		end

        set @msg = @me + ': complete';
        exec absp_Util_Log_Info @msg, @me;
    end

    If @@TRANCOUNT > 0 COMMIT TRANSACTION;
	set IMPLICIT_TRANSACTIONS ON;
	set ANSI_PADDING off;

    return @retCode;
end
