if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_getMissingAggregationSources') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getMissingAggregationSources
end
go

create procedure absp_getMissingAggregationSources @rdbInfoKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure gets the list of detached databases or removed resultset nodes 
    that are parts of an aggregation node 

Returns:	lsit of missing databases and nodes

====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin

set nocount on
declare @sql varchar(max)
declare @msg varchar(max)
declare @RdbName varchar(120)
declare @NodeName varchar(120)
declare @SourceDBRefKey int
declare @SourceRDBInfoKey int
declare @inputSourcesCount int
declare @missingSourcesCount int

CREATE TABLE #MISSING_AGGSOURCE_TMP (
ID int identity(1,1),
dbName varchar(120),
nodeName varchar(120),
sourceDBRefKey int,
sourceRDBInfoKey int,
errMessage varchar(max) )


select @inputSourcesCount = COUNT(*)  from AggInputSources where RdbInfoKey = @rdbInfoKey

declare curs1 cursor fast_forward for
	select distinct  RdbName, LongName, SourceDBRefKey, SourceRDBInfoKey from AggInputSources where RdbInfoKey = @rdbInfoKey
    open curs1 fetch next from curs1 into @RdbName,@NodeName,@SourceDBRefKey,@SourceRDBInfoKey
    while @@FETCH_STATUS = 0
    begin
		if not exists (select 1 from sys.databases SDB where SDB.name=@RdbName)
		begin
			set @msg = 'Database "' + rtrim(@RdbName) + '" that contains Resultset "' +rtrim(@nodeName) + '" is not currently being attached.'
			insert into #MISSING_AGGSOURCE_TMP values(@RdbName,@NodeName,@sourceDBRefKey,@sourceRDBInfoKey,@msg)
		end
		else
		begin
		set @msg = '''Resultset "' +rtrim(@nodeName) + '" was not found or removed from Database "' + rtrim(@RdbName) + '".'''
		set @sql = 'if not exists(select 1 from [' + rtrim(@RdbName) + '].dbo.RdbInfo where rdbInfoKey = ' + ltrim(str(@SourceRDBInfoKey)) +') insert into #MISSING_AGGSOURCE_TMP values(''' + rtrim(@RdbName) + ''',''' +rtrim(@NodeName) +''',' + ltrim(str(@SourceDBRefKey)) + ',' + ltrim(str(@SourceRDBInfoKey)) + ',' + @msg + ')'
		--print @sql
		execute (@sql)
		end
		fetch next from curs1 into @RdbName,@NodeName,@SourceDBRefKey,@SourceRDBInfoKey
    end

    close curs1
    deallocate curs1
 
	select @missingSourcesCount = COUNT(*)  from #MISSING_AGGSOURCE_TMP

    -- if all input sources are unavailable (@inputSourcesCount = @missingSourcesCount) 
	-- return a special line to tell the client that all nput sources are missing
	if  @inputSourcesCount = @missingSourcesCount
		select 'unknown' dbName ,'unknown' nodeName,0 sourceDBRefKey ,0 sourceRDBInfoKey,'No input sources were found' errMessage
	else 
		select dbName, nodeName,sourceDBRefKey, sourceRDBInfoKey,errMessage from #MISSING_AGGSOURCE_TMP

end  