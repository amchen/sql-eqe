if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_AnnotationHelper') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_AnnotationHelper;
end
go

create procedure absp_Migr_AnnotationHelper
	@finalScript varchar(max) out,
	@scriptText varchar(max),
	@tableName varchar(130),
	@RQEVersion varchar(25),
	@debug int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure generates the actual script by replacing the annotations.
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @finalScript ^^ The script that is to be returned
##PD  @scriptText ^^ The script with annotations
##PD  @tableName ^^ The tableName which is to be created
##PD  @debug ^^ The debug flag@aaa
*/

as

begin
	set nocount on;

	declare @sql varchar(max);
	declare @indexName varchar(255);
	declare @indexScript varchar(max);
	declare @strSql varchar(max);
	declare @pos int;
	declare @pos2 int;
	declare @startPos int;
	declare @errMsg varchar(100);
	declare @crlf varchar(2);
	declare @tab char(1);
	declare @annotation varchar(50);
 	declare @SysRQEVersion varchar(25);

	declare @Annotable table (Annotation varchar(50));

	-- Init variables
	set @crlf = char(10) + char(13);
	set @tab  = char(9);
	set @finalScript = @scriptText;

	select top (1) @SysRQEVersion = RQEVersion from systemdb.dbo.RQEVersion order by RQEVersionKey desc;

	-- Init annotation table
	insert @Annotable values ('@Columns');
	insert @Annotable values ('@CreateIndex');
	insert @Annotable values ('@CreateTable');
	insert @Annotable values ('@DropIndex');
	insert @Annotable values ('@DropTable');
	insert @Annotable values ('@TableName');

	insert @Annotable values ('@LoadProcedures');	-- Loads all procedures, views, and triggers
	insert @Annotable values ('@LoadViews');		-- Loads views only
	insert @Annotable values ('@LoadTriggers');		-- Loads triggers only

	insert @Annotable values ('@RQEVersion');		-- The current RQEVersion of the migration
	insert @Annotable values ('@DatabaseName');		-- The current name of the database
	insert @Annotable values ('@SysRQEVersion');	-- The RQEVersion from systemdb database (target version)


	-- Loop through annotations
	declare cursa1 cursor fast_forward for
		select Annotation from @Annotable order by Annotation;
	open cursa1;
	fetch cursa1 into @annotation;
	while @@FETCH_STATUS = 0
	begin
		set @sql = '';

		-- Is annotation used
		if charindex(@annotation, @finalScript) > 0
		begin
			if @annotation = '@Columns'
				begin
					exec systemdb..absp_DataDictGetFields @sql out, @tableName, 0;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@CreateIndex'
				begin
					--CreateIndexScript--
					exec systemdb..absp_Util_CreateTableScript @strSql out, @tableName, '', '', 2;
					if @debug <> 0 exec absp_MessageEx @strSql;

					--Add if not exists before create index--
					set @startPos = 0;
					set @pos = charindex(';', @strSql);
					while @pos > 0
					begin
						set @indexScript = substring(@strSql, @startPos, @pos + 1 - @startPos);
						set @pos2 = charindex(' INDEX ', @indexScript);
						set @indexName = substring(@indexScript, @pos2+7, (charindex(' ', @indexScript, @pos2+7))-(@pos2+7));
						set @startPos = @pos+1;
						set @pos = charindex(';', @strSql, @pos+1);
						set @sql = @sql + 'if not exists (select 1 from sys.indexes where name=''' + @indexName + ''') ' + @indexScript + @crlf;
						if @debug <> 0 exec absp_MessageEx @sql;
					end
				end
			else if @annotation = '@CreateTable'
				begin
					exec systemdb..absp_Util_CreateTableScript @sql out, @tableName, '', '', 0;
					if @debug <> 0 exec absp_MessageEx @sql;
					set @sql = 'if not exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME=''' + @tableName + ''' and TABLE_SCHEMA =''dbo'')' + @crlf + @tab + 'begin ' + @crlf + @tab + @sql + ';' + @crlf + @tab + 'end' + @crlf + @tab;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@DropIndex'
				begin
					declare curs2 cursor for
						select IndexName from DictIdx where TableName=@tableName and FieldOrder=1 and IsPrimary <> 'Y' order by IndexName;
					open curs2;
					fetch next from curs2 into @indexName;
					while @@fetch_status = 0
					begin
						set @indexScript = 'drop index ' + rtrim(@tableName) + '.' + @indexName + ';';
						set @sql = @sql + 'if exists (select 1 from sys.indexes where name=''' + @indexName + ''') ' + @indexScript + @crlf;
						if @debug <> 0 exec absp_MessageEx @sql;
						fetch next from curs2 into @indexName;
					end
					close curs2;
					deallocate curs2;
				end
			else if @annotation = '@DropTable'
				begin
					set @sql = 'if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME=''' + @tableName + ''') drop table ' + @tableName + ';' + @crlf;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@TableName'
				begin
					set @sql = @tableName;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@LoadProcedures'
				begin
					set @sql = 'exec absp_Migr_LoadProcedure ''DB_NAME()'', ''@RQEVersion'';';
					set @sql = replace(@sql, '@RQEVersion',   @RQEVersion);
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@LoadViews'
				begin
					set @sql = 'exec absp_Migr_LoadProcedure ''DB_NAME()'', ''@RQEVersion'', ''V'';';
					set @sql = replace(@sql, '@RQEVersion',   @RQEVersion);
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@LoadTriggers'
				begin
					set @sql = 'exec absp_Migr_LoadProcedure ''DB_NAME()'', ''@RQEVersion'', ''T'';';
					set @sql = replace(@sql, '@RQEVersion',   @RQEVersion);
					set @sql = @tableName;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@RQEVersion'
				begin
					set @sql = @RQEVersion;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@SysRQEVersion'
				begin
					set @sql = @SysRQEVersion;
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else if @annotation = '@DatabaseName'
				begin
					set @sql = 'DB_NAME()';
					if @debug <> 0 exec absp_MessageEx @sql;
				end
			else
				begin
					set @errMsg = 'ERROR: Unknown Annotation';
					exec absp_MessageEx @errMsg;
					raiserror (@errMsg, 19, 1) with seterror;
				end

			set @finalScript = replace(@finalScript, @annotation, @sql);
		end
		fetch cursa1 into @annotation;
	end
	close cursa1;
	deallocate cursa1;

	if @debug <> 0 exec absp_MessageEx @finalScript;
end
/*
declare @finalScript varchar(max);
exec  absp_Migr_AnnotationHelper
	@finalScript out,
	@scriptText='@DropIndex @DropTable @CreateTable @CreateIndex',
	@tableName='StructureCoverage',
	@debug=0;
print @finalScript;
*/
