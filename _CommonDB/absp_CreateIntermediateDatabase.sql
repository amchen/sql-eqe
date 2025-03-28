if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_CreateIntermediateDatabase') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CreateIntermediateDatabase;
end
go

create procedure absp_CreateIntermediateDatabase
	@mdfPath varchar(256),
	@ldfPath varchar(256),
	@dbName  varchar(120)
	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will create an intermediate database. 
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
	declare @actualIDBName varchar(max);	-- what your IDB is called
	declare @sql nvarchar(max);		-- statements we execute
	declare @rqeVersion varchar(20);
	declare @rqeColNames varchar(1000);
	
	select @rqeVersion = RQEVERSION from systemdb..RQEVERSION;
	
    	-- path where you want your IDBs
	set @myMDbFolder = @mdfPath;
	set @myLDbFolder = @ldfPath;
	set @actualIDBName = @dbName + '_IR'; -- The actual database script has the _IR appended to the end of the user provided name.
	set @rqeColNames = ' DbType,SchemaVersion,RQEVersion,FlCertificationVersion,VersionDate,Build,PatchVersion,HotfixVersion,ScriptUsed ';

	-- get the create database part
	select @sql = ScriptText from systemdb..DatabaseCreateScript where DbType='IDB' and ScriptStepNum = 1;

	-- rename the pieces
	set @sql = replace(@sql, '@DatabaseMDFPath', @myMDbFolder);
	set @sql = replace(@sql, '@DatabaseLDFPath', @myLDbFolder);
	set @sql = replace(@sql, '@DatabaseName', @dbName);
	--print @sql;
	execute(@sql);	-- do it!
	
	-- Create Account related tables
	select @sql = ScriptText from systemdb..DatabaseCreateScript where DbType='IDB' and ScriptStepNum = 2;
	set @sql = replace(@sql, '''', '''''');
	set @sql = 'use ' + quotename(@actualIDBName) + '; exec(''' + @sql + ''')';
	exec absp_Util_LogIt @sql, 4, 'createIDB', 'C:\Temp\log.log';
	--print @sql;
	execute(@sql);	-- do it!
	
	-- Insert an entry in RQEVERSION table
	set @sql = ' insert into ' + @actualIDBName + '..RqeVersion (' + @rqeColNames + ') select top 1 ' + @rqeColNames + ' from systemdb..RQEVersion';
	--execute(@sql);
	
	-- Run all the procedures to load rest of the stuff
	declare curs_1 cursor fast_forward for select ScriptText from systemdb..DatabaseCreateScript where DbType='IDB' and ScriptStepNum > 2;
	open curs_1;
	fetch next from curs_1 into @sql;
	while @@fetch_status = 0
	begin
		-- we need to be in there to create tables there
		set @sql = replace(@sql, '@DatabaseName', @actualIDBName);
		set @sql = replace(@sql, '@RQEVersion', @rqeVersion);
		set @sql = 'use ' + quotename(@actualIDBName) + '; ' + @sql ;
		--print @sql;
		execute(@sql);	-- do it!
		fetch next from curs_1 into @sql;
	end
	close curs_1;
	deallocate curs_1;

	-- SET RECOVERY SIMPLE
	set @sql = 'use master; exec(''ALTER DATABASE [@DatabaseName] SET RECOVERY SIMPLE'')';
	set @sql = replace(@sql, '@DatabaseName', @actualIDBName);
	execute(@sql);

	-- SET READ_COMMITTED_SNAPSHOT ON
	set @sql = 'use master; exec(''ALTER DATABASE [@DatabaseName] SET READ_COMMITTED_SNAPSHOT ON'')';
	set @sql = replace(@sql, '@DatabaseName', @actualIDBName);
	execute(@sql);
end

