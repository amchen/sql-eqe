if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_CreateRdbNode') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CreateRdbNode;
end
go

create procedure absp_CreateRdbNode
	@mdfPath varchar(256),
	@ldfPath varchar(256),
	@dbName  varchar(120),
	@userName varchar(120) = '',
	@groupKey int = 0,
	@attrib int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will create an RDB using a couple of names you give me
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @mdfPath ^^ The path to where to create the MDF file
##PD  @ldfPath ^^ The path to where to create the LDF file
##PD  @dbName  ^^ The name you want the databae to have
*/

as

begin
	set nocount on;

	-- a few variables we need
	declare @myMDbFolder varchar(max);	-- where the .mdf files end up
	declare @myLDbFolder varchar(max);	-- where the .ldf files end up
	declare @myRdbName varchar(max);	-- what your RDB is called
	declare @sql nvarchar(max);			-- statements we execute
	declare @groupName varchar(50);
	declare @rqeVersion varchar(25);

    --set attrib bit based on where the rdb database is create from
	if DB_NAME() ='commondb' set @attrib = 32

	-- path where you want your RDBs
	set @myMDbFolder = @mdfPath;
	set @myLDbFolder = @ldfPath;
	set @myRdbName = @dbName;

	select @rqeVersion = max(RQEVersion) from systemdb..RQEVersion;

	-- get the create database part
	select @sql = ScriptText from DatabaseCreateScript where DbType='RDB' and ScriptStepNum = 1;

	-- rename the pieces
	set @sql = replace(@sql, '@DatabaseMDFPath', @myMDbFolder);
	set @sql = replace(@sql, '@DatabaseLDFPath', @myLDbFolder);
	set @sql = replace(@sql, '@DatabaseName', @myRdbName);

	execute(@sql);	-- do it!

	declare curs_1 cursor fast_forward for select ScriptText from DatabaseCreateScript where DbType='RDB' and ScriptStepNum > 1;
	open curs_1;
	fetch next from curs_1 into @sql;
	while @@fetch_status = 0
	begin
		-- we need to be in there to create tables there
		set @sql = replace(@sql, '@DatabaseName', @myRdbName);
		set @sql = replace(@sql, '@RQEVersion', @rqeVersion);
		set @sql = replace(@sql, '''', '''''');
		set @sql = 'use ' + quotename(@myRdbName) + '; exec(''' + @sql + ''')';
		execute(@sql);	-- do it!
		fetch next from curs_1 into @sql;
	end
	close curs_1;
	deallocate curs_1;

	-- update RDBINFO
	set @groupName = ''
	set @sql ='use [commondb]; select @groupName = Group_Name from usergrps where Group_Key = ' + ltrim(rtrim(str(@groupKey)))
    EXEC sp_executesql @sql,N'@groupName varchar(50) output',@groupName output

	set @sql = 'use ' + quotename(@myRdbName) + '; exec(''update RDBINFO set SourceDatabaseName = ''''' + rtrim(@myRdbName) + ''''', CreatedBy = ''''' + @userName + ''''', UserGroup = ''''' + rtrim(@groupName) + ''''' where LongName = DB_NAME()'')';
	execute(@sql);

	-- SET RECOVERY SIMPLE
	set @sql = 'use master; exec(''ALTER DATABASE [@DatabaseName] SET RECOVERY SIMPLE'')';
	set @sql = replace(@sql, '@DatabaseName', @myRdbName);
	execute(@sql);

	-- SET READ_COMMITTED_SNAPSHOT ON
	set @sql = 'use master; exec(''ALTER DATABASE [@DatabaseName] SET READ_COMMITTED_SNAPSHOT ON'')';
	set @sql = replace(@sql, '@DatabaseName', @myRdbName);
	execute(@sql);

	-- make the database available on the treeview
	if @attrib > 0
	begin
		exec absp_Util_AttachRDBLogical @myRdbName;
	end
end

--exec absp_CreateRdbNode 'D:\WCeDB\RDB', 'D:\WCeDB\RDB', 'RDB_test';
