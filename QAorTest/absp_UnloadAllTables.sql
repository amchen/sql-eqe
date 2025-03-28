if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_UnloadAllTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_UnloadAllTables
end
go

create procedure  absp_UnloadAllTables 	@rootPath  varchar(255),
					@serverName varchar(200)='',
					@dbName varchar(130)='',
					@userName varchar(100)='',
					@password varchar(100)='',
					@excludeTableName varchar(120)='',
					@customQueryTableName varchar(120)='',
					@excludeColListTableName varchar(120)=''
as
/*
====================================================================================================
Purpose:

This procedure unloads all tables present in dicttbl under a specified path. It also creates a folder
structure by their respective tabletype entries in dicttbl. It needs to be run from systemdb.

Returns: zero on success, non-zero on failure
====================================================================================================
@rootPath ^^ The root path under which the folder structure will be created.
@userName ^^ The userName - in case of SqlServer Authentication.
@password ^^ The password - in case of SqlServer Authentication.
*/

begin
	declare @me				varchar(255)
	declare @msg				varchar(max)
	declare @retVal				integer
	declare @outPath			varchar(255)
	declare @colInList			varchar(max)
	declare @sqlCol				varchar(max)
	declare @sqlUnloadStmt			nvarchar(max)
	declare @tableName			varchar(255)
	declare @tableType			varchar(255)
	declare @tableNamePrefix		varchar(255)
	declare @colInListForOrderBy 	varchar(max)
	declare @sqlColForOrderBy		varchar(max)
	declare @dbType					varchar(10)
	declare @sql				nvarchar(max)
	declare @query				nvarchar(max)
	declare @sSql                varchar(7999)
	declare @tmpPath		varchar(255)
	declare @auth                varchar(1000)
	declare @dictTblName		varchar(50)
	declare @dictColName		varchar(50)
	declare @retCode int
	declare @filePath varchar(1000);
	declare @delimiter varchar(2)
	declare @dbName2 varchar(130)
	declare @customQuery int;
	declare @queryString nvarchar(max);
	declare @excludeCols varchar(max);
	declare @excludeColExists int;
	declare @excludeTableList varchar(max);
	declare @custQryTblExists int;
	declare @tableToUnloadExists int;

	-- Start
	set @me = 'absp_UnloadAllTables'

	set @dictTblName ='systemdb..DICTTBL'
	set @dictColName ='systemdb..DICTCOL'
	set @delimiter ='|'
	--Enclose within square brackets--
	if @dbName <>''
	   execute absp_getDBName @dbName out, @dbName
	else
	   set @dbName=DB_NAME()

	set @dbName2=SUBSTRING (@dbName,2,len(@dbName)-2)

	if @serverName =''
		set @serverName=@@serverName

	if @dbName ='[systemdb]'
		set @dbType='SYS_DB'
	else if @dbName ='[commondb]'
		set @dbType='COM_DB'
	else if right(@dbName,4) ='_IR]'
		set @dbType ='CF_DB_IR'
	else
		set @dbType ='CF_DB'

	if len (@userName)>0 and len (@password)>0
		set @auth = ' -U ' + @userName + ' -P ' + @password
	else
		set @auth =   ' -T'

	-- In case of a remote server bcp the dicttbl/dictcol of remote server to local server
	--as we cannot query from a remote server without using a linked server

	set @serverName=replace(@serverName,'\\','\')
	if @serverName <>'['+ @@serverName +']' and @serverName <>  @@serverName
	begin
		--Unload DICTTBL--
		set @sqlUnloadStmt = 'select * from systemdb..DICTTBL'
		set @sSql = 'bcp "' + @sqlUnloadStmt + '" queryout ' + @rootPath + '\DictTbl.txt -S ' + @serverName + ' -c -C1252 -t "' + @delimiter + '" ' + @auth
		exec  @retCode= xp_cmdshell @sSql, no_output
		--Load it in local server--
		set @sSql = 'bcp systemdb..DICTTBL_REMOTE in ' + @rootPath + '\DictTbl.txt -S ' + @@serverName + ' -c -C1252 -t "' + @delimiter + '"  -T'
		exec  @retCode= xp_cmdshell @sSql, no_output
		set @tmpPath=@rootPath + '\DictTbl.txt'
		exec absp_Util_DeleteFile @tmpPath

		--Unload DICTCOL--
		set @sqlUnloadStmt = 'select * from systemdb..DICTCOL'
		set @sSql = 'bcp "' + @sqlUnloadStmt + '" queryout ' + @rootPath + '\DictCol.txt -S ' + @serverName + ' -c -C1252 -t "' + @delimiter + '" ' + @auth
		exec  @retCode= xp_cmdshell @sSql, no_output
		--Load it in local server--
		set @sSql = 'bcp systemdb..DICTCOL_REMOTE in ' + @rootPath + '\DictCol.txt -S ' + @@serverName + '  -c -C1252 -t "' + @delimiter + '"  -T'
		exec  @retCode= xp_cmdshell @sSql, no_output
		set @tmpPath=@rootPath + '\DictCol.txt'
		exec absp_Util_DeleteFile @tmpPath

		set @dictTblName =  @dictTblName + '_REMOTE'
		set @dictColName = @dictColName + '_REMOTE'
	end


	--Check if custom query table exists--
	--===================================--
	set @custQryTblExists=0
	if exists (select 1 from Sys.tables where name=@customQueryTableName) set @custQryTblExists=1

	--Check if excludecol table exists--
	--===================================--
	set @excludeColExists=0
	if exists (select 1 from Sys.tables where name=@excludeColListTableName) set @excludeColExists=1;

	--Check if there is % in ExcludeTables--
	--====================================--
	set @excludeTableList='';
	create table #TMP_EXCLUDELIST(TableName varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS)

	if exists (select 1 from Sys.tables where name=@excludeTableName)
	begin
		exec('insert into  #TMP_EXCLUDELIST  select TableName from ' + @excludeTableName);

		set @sql = 'declare c1 cursor fast_forward global for select TableName from ' + @excludeTableName + ' where charindex(''%'',tablename)>0'
		exec(@sql);
		open c1
		fetch next from c1 into @tableName
		while @@FETCH_STATUS = 0
		begin
			exec( 'insert into   #TMP_EXCLUDELIST  select Name from ' + @dbName + '.Sys.tables where name like ''' + @tableName + '''');
			fetch next from c1 into @tableName
		end
		close c1
		deallocate c1

		exec('delete from   #TMP_EXCLUDELIST   where  charindex(''%'',tablename)>0');

		--In the ExcludetableList add the temp tables created for unloading--
		set @sql= 'insert into  #TMP_EXCLUDELIST   select Name from Sys.tables where name in(''TMPTBL'',''DICTTBL_REMOTE'',''DICTCOL_REMOTE'',''' + @excludeTableName + ''',''' + @customQueryTableName + ''',''' + @excludeColListTableName + ''')';
		exec(@sql)

		set @sql='select TableName from   #TMP_EXCLUDELIST';
		exec absp_Util_GenInListString @excludeTableList out, @sql, 'C'
	end

	if @excludeTableList<>''

		set @sql='declare curs cursor fast_forward global for select ltrim(rtrim(TABLENAME)) as TABLENAME, ltrim(rtrim(TABLETYPE)) as TABLETYPE from '
	                 + @dictTblName + ' where ' + @dbType + ' in (''Y'',''L'') and TableName not in (' + @excludeTableList + ')'
	else
		set @sql='declare curs cursor fast_forward global for select ltrim(rtrim(TABLENAME)) as TABLENAME, ltrim(rtrim(TABLETYPE)) as TABLETYPE from '
	                  + @dictTblName + ' where ' + @dbType + ' in (''Y'',''L'') '


	--Add catalogs--
	set @sql = @sql + ' union ' +' select name as TABLENAME,''CATALOG'' AS TABLETYPE from '

	set @sql=@sql + ' sys.system_views ' +
		' where name in (''TABLES'',''COLUMNS'', ''INDEXES'', ''VIEWS'', ''PROCEDURES'',''TRIGGERS'',''DEFAULT_CONSTRAINTS'',''foreign_keys'')
				and [schema_id] = schema_id(''sys'') '
	--Add functions--
	set @sql = @sql + ' union  select ''Functions'' as TABLENAME,''CATALOG'' AS TABLETYPE from sys.objects WHERE type IN (''FN'', ''IF'', ''TF'')' +
		' order by TABLETYPE, TABLENAME'
	exec(@sql)

	open curs
	fetch next from curs into @tableName, @tableType
	while @@FETCH_STATUS = 0
	begin
			--create outpath
			set @outPath = @rootPath + '\' + @tableType
			exec @retVal = absp_Util_CreateFolder @outPath

			if @retVal <> 0
			begin
				set @msg = 'Unable to create folder ' + @outPath
				exec absp_Util_Log_Info @msg, @me
				return @retVal
			end


			--compose full filename
			set @filePath =  dbo.trim(@outPath) + '\' + dbo.trim(@tableName) + '.txt'

			--If table has a custom query, unload using the custom query--
			--==========================================================--
			set @customQuery=0;
			if @custQryTblExists=1
			begin
				set @sqlUnloadStmt='';
					set @queryString='select @sqlUnloadStmt=' + @customQueryTableName +' from ' + @customQueryTableName + ' where TableName=''' + @tableName + '''';
					execute sp_executesql @queryString, N'@sqlUnloadStmt varchar(max) output', @sqlUnloadStmt output
					if len(@sqlUnloadStmt)>0
					begin
						set @sqlUnloadStmt=replace(@sqlUnloadStmt,' dbo.', ' '+@dbName +'.dbo.');
						set @customQuery=1;
					end
			end

			--If table has an exclude column list, exclude the columns
			--==========================================================--
			if @excludeColExists=1
			begin
				set @excludeCols='';
				set @queryString='select @excludeCols=' + @excludeColListTableName +' from ' + @excludeColListTableName + ' where TableName=''' + @tableName + '''';

				exec sp_executesql @queryString,N'@excludeCols varchar(max) out', @excludeCols out
				if len(@excludeCols)>0 	set @excludeCols='''' + replace(@excludeCols,',',''',''')+ ''''
			end


			--generate columnlist...and set up table name qualifier
			if  @tableType<>'CATALOG' and @customQuery=0
			begin
				set @sqlCol = 'select ''rtrim('' + rtrim(FIELDNAME) + '')'' from ' + @dictColName + ' where TABLENAME = ''' + @tableName + ''''

				if len(@excludeCols)>0 set @sqlCol=@sqlCol + ' and FIELDNAME not in (' + replace(@excludeCols,' ','') + ')';
				set @sqlCol=@sqlCol +  ' order by FIELDNUM'

				set @sqlColForOrderBy =  'select  rtrim(FIELDNAME)  from ' + @dictColName + ' where TABLENAME = ''' + @tableName + ''''
				if len(@excludeCols)>0 set @sqlColForOrderBy=@sqlColForOrderBy + ' and FIELDNAME not in (' +  @excludeCols + ')';
				set @sqlColForOrderBy=@sqlColForOrderBy +' order by FIELDNUM'


				exec absp_Util_GenInListString @colInListForOrderBy out, @sqlColForOrderBy, 'N'
				exec absp_Util_GenInListString @colInList out, @sqlCol, 'N'
				set @tableNamePrefix =   @dbName+'.dbo.'

			end
			else if @tableType='CATALOG' and @customQuery=0
			begin
				set @sqlCol = 'select ''rtrim(c.'' + rtrim(name) + '')''   from systemdb.sys.system_columns where [object_id] = ' +
					'(select [object_id] from sys.system_objects  where name = ''' + @tableName +
					''' and [schema_id] = schema_id(''sys''))' +
					' and name in (''name'',''column_id'',''max_length'',''precision'',''scale'',''collation_name'',''is_identity'')' ;

				if len(@excludeCols) > 0
					set @sqlCol=@sqlCol + ' and name not in (' + @excludeCols + ')';

				set @sqlCol=@sqlCol +  ' order by column_id';

				if @serverName <>'['+ @@serverName +']' and @serverName <>  @@serverName
				begin
					-- In case of a remote server
					if exists(select 1 from  systemdb.sys.tables where name ='TMPTBL') drop table  systemdb..TMPTBL
					create table systemdb..TMPTBL (NAME varchar(120));
					set @sSql = 'bcp "' + @sqlCol + '" queryout ' + @rootPath + '\Column.txt -S ' + @serverName +  ' -c -C1252 -t "' + @delimiter + '" ' + @auth
					print @sSql;
					exec  @retCode= xp_cmdshell @sSql, no_output;

					set @sSql = 'bcp systemdb.dbo.TMPTBL in ' + @rootPath + '\Column.txt -S ' + @@serverName + '  -c -C1252 -t "' + @delimiter + '"  -T';
					print @sSql;
					exec  @retCode= xp_cmdshell @sSql, no_output;
					set @tmpPath=@rootPath + '\Column.txt';
					exec absp_Util_DeleteFile @tmpPath;

					set @sqlCol='select NAME from systemdb..TMPTBL';
					if len(@excludeCols)>0 set @sqlCol=@sqlCol + ' where name not in (' +  @excludeCols + ')';
				end

				if  @tableName='COLUMNS'
					set @colInListForOrderBy  = ' t.name, c.column_id';
				else if @tableName='INDEXES'
					set @colInListForOrderBy  = ' t.name, c.index_id';
				else if @tableName='DEFAULT_CONSTRAINTS'
					set @colInListForOrderBy  = 'c.schema_id, Nm, c.parent_column_id';
				else
					set @colInListForOrderBy  = ' c.name';

				exec absp_Util_GenInListString @colInList out, @sqlCol, 'N';
				set @tableNamePrefix = @dbName+'.sys.';
			end

			--create sql statement for unload
			if @customQuery=0
			begin
				if @tableName='PROCEDURES'
				begin
					set @sqlUnloadStmt = 'select Upper(Name), [systemdb].dbo.trimx(Definition) from ' + @tableNamePrefix + @tableName +
						' c inner join ' + @tableNamePrefix + 'sql_modules d on name=object_name(d.object_id, DB_ID(''' + @dbName2 +''')) ' +
						' and schema_name(c.schema_id)=''dbo'' ';
				end
				else if @tablename='VIEWS'
				begin
					set @sqlUnloadStmt = 'select Upper(Name), [systemdb].dbo.trimx(lower(Definition)) from ' + @tableNamePrefix + @tableName +
						' c inner join ' + @tableNamePrefix + 'sql_modules d on name=object_name(d.object_id, DB_ID(''' + @dbName2 +''')) ' +
						' and schema_name(c.schema_id)=''dbo'' ';
				end
				else if @tablename='Functions'
				begin
					set @sqlUnloadStmt = 'select Upper(Name), [systemdb].dbo.trimx(Definition) from ' + @tableNamePrefix + 'objects c inner join ' +
						@tableNamePrefix + 'sql_modules d on name=object_name(d.object_id, DB_ID('''+ @DBname2+''')) and type in (''FN'',''TF'') ';
				end
				else if @tablename='Triggers'
				begin
					set @sqlUnloadStmt = 'select Upper(Name), [systemdb].dbo.trimx(lower(Definition)) from ' + @tableNamePrefix + 'triggers c inner join ' +
						@tableNamePrefix + 'sql_modules d on name=object_name(d.object_id,  DB_ID(''' + @dbName2 +''')) ';
				end
				else if @tableType='CATALOG' and (@tableName='INDEXES' or @tableName='COLUMNS')
				begin
					if @tableName='INDEXES'
						set @colInList = replace (@colInList,'rtrim(c.name)', 'case when left(rtrim(c.name),4)=''PK__'' then left(rtrim(upper(c.name)), CHARINDEX (''_'',RTRIM(c.name),5)-1) else rtrim(upper(c.name)) end');

					set @sqlUnloadStmt = 'select rtrim(Upper(t.Name)) as OBJ_NAME,' + @colInList + ' from ' + @tableNamePrefix + @tableName +
						' c inner join ' + @tableNamePrefix + 'tables t on c.object_id = t.object_id ' +
						' and schema_name(t.schema_id)=''dbo'' ' +
						' order by ' + @colInListForOrderBy;
				end
				else
				begin
					if @tableName='DEFAULT_CONSTRAINTS'
						set @colInList = replace (@colInList,'rtrim(c.name)', 'left(Upper(c.name),len(c.name)-charindex(''__'' , reverse(c.name),0)-1) AS Nm');

					set @sqlUnloadStmt = 'select ' + @colInList + ' from ' + @tableNamePrefix + @tableName + ' c ';

					if @tableName='TABLES' or @tableName='DEFAULT_CONSTRAINTS'
						set @sqlUnloadStmt = @sqlUnloadStmt+' where schema_name(c.schema_id)=''dbo'' order by 1, 9, 10';
				end
			end

			--finally call the proc to do the unload
			if @tableName in('PROCEDURES','VIEWS','Functions','TRIGGERS')
			begin
				set @sSql = 'bcp "@sqlUnloadStmt" queryout "@filePath" -S ' + @serverName + ' -c -C1252 -t "' + @delimiter + '" ' + @auth
				exec absp_UnloadSysCatalogs @sqlUnloadStmt, @sSql, @outPath,@tableName,@excludeTableList
			end
			else
			begin
				--Check for tables in Dicttbl which do not exist--like Version
				if @tableType<>'Catalog'
				begin
					set @tableToUnloadExists=0;
					set @query='select @tableToUnloadExists=1 from ' + @dbName + '.Sys.Tables where Name =''' + @tableName + ''''
					exec sp_executesql @query,N'@tableToUnloadExists int out',@tableToUnloadExists out
				end
				else
					set @tableToUnloadExists=1;

				--execute bcp query--
				if @tableToUnloadExists=1
				begin
					set @sSql = 'bcp "' + @sqlUnloadStmt + '" queryout "' + @filePath + '" -S ' + @serverName + ' -c -C1252 -t "' + @delimiter + '" ' + @auth
					print @sSql
					exec  @retCode= xp_cmdshell @sSql, no_output
				end
			end

			if exists(select 1 from  systemdb.sys.tables where name ='TMPTBL') drop table  systemdb..TMPTBL

		fetch next from curs into @tableName, @tableType
	end
	close curs
	deallocate curs

	return @retVal
end
