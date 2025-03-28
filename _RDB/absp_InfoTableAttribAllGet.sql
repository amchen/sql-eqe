if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribAllGet') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribAllGet;
end
go

create procedure absp_InfoTableAttribAllGet	@nodeType integer,
											@nodeKey integer,
											@databaseName varchar(125) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets all the Attribute settings for the given node and returns as a resultset.


Returns: Resultset.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^ The type of node for which the attributes are to be seen
##PD  @nodeKey ^^  The key of node for which the attributes are to be seen

##RS  ATTRIBUTE 	^^  The name of the attribute
##RS  SETTING 	^^  The attribute setting (0 = Off or 1 = On)
*/

as
begin

	declare @attrib integer;
	declare @bitValue bit;
	declare @attributeName varchar(25);
	declare @dbName varchar(125);
	declare @dbType varchar(3);
	declare @sqlStmt varchar(max);
	declare @nsqlStmt nvarchar(max);

	set nocount on;

	create table #TMPATTRIBINFO (ATTRIBUTE varchar(25)  COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit);
	set @sqlStmt = '';

	if @databaseName = ''
		set @dbName = ltrim(rtrim(DB_NAME()));
	else
		set @dbName = ltrim(rtrim(@databaseName));

	--Enclose within square brackets
	execute absp_getDBName @dbName out, @dbName;

	--Check for RDB
	set @nsqlStmt = N'select top 1 @dbType=DbType from '+ @dbName + '..RQEVersion';
	execute sp_executesql @nsqlStmt,N'@dbType varchar(3) output',@dbType=@dbType output;
	if (@dbType = 'RDB' and @nodeType < 101)
		set @nodeType = 101;

	set @sqlStmt = 'declare @bitValue bit; declare @attributeName varchar(25);declare @attrib integer;';

	-- Get the attribute of the given node --
	if @nodeType = 12
		set @sqlStmt = @sqlStmt + 'select @attrib=ATTRIB from '+ @dbName +'..CFLDRINFO where CF_REF_KEY='+rtrim(str(@nodeKey));
	else if @nodeType = 0
		set @sqlStmt = @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..FLDRINFO where FOLDER_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 13
		set @sqlStmt = @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..CURRINFO where CURRSK_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 1
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..APRTINFO where APORT_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 2
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..PPRTINFO where PPORT_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 3 or @nodeType =23
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..RPRTINFO where RPORT_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 7 or @nodeType =27
		set @sqlStmt = @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..PROGINFO where PROG_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 10 or @nodeType =30
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..CASEINFO where CASE_KEY='+rtrim(str(@nodeKey));
	else if  @nodeType = 64
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..ExposureInfo  where ExposureKey='+rtrim(str(@nodeKey));
	else if  @nodeType = 101
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..RdbInfo where NodeType='+rtrim(str(@nodeType)) 
	else if  @nodeType = 102 or @nodeType = 103
		set @sqlStmt =  @sqlStmt +
			'select @attrib=ATTRIB from '+ @dbName +'..RdbInfo where NodeType='+rtrim(str(@nodeType)) + ' and rdbInfoKey='+rtrim(str(@nodeKey));


	-- Find the value of each attribute (bit 0,1,2,3) --
	if len(@sqlStmt) > 0
	begin
		set @sqlStmt = @sqlStmt + ' ' +
			'if @attrib is not null ' +
			'begin ' +
			'declare curs1 cursor for select ATTRIBNAME from ATTRDEF where ATTRIBNAME <> ''Undefined'' order by ATTRIB_ID ' +
			'open curs1 ' +
			'fetch curs1 into @attributeName ' +
			'while @@fetch_status=0 ' +
			'begin ' +
				'set @bitValue =  @attrib % 2 '+
				'set @attrib = @attrib/2 ' +
				'insert into #TMPATTRIBINFO (ATTRIBUTE, SETTING) values(@attributeName, @bitValue) ' +
				'fetch curs1 into @attributeName ' +
			'end ' +
			'close curs1 ' +
			'deallocate curs1 ' +
			'end ';
		execute(@sqlStmt);
	end

	select ATTRIBUTE, SETTING from #TMPATTRIBINFO;
end
