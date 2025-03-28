if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttrib_Set') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttrib_Set;
end
go

create procedure absp_InfoTableAttrib_Set   @nodeType integer,
											@nodeKey integer,
											@attributeName varchar(25),
											@attributeSetting bit,
											@databaseName varchar(125) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the attribute of the related INFO table with the given AttributeSetting (0 = Off or 1 = On)
     for the given Node.


Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^ The type of node for which the attribute is to be set
##PD  @nodeKey ^^  The key of node for which the attribute is to be set
##PD  @attributeName  ^^ The attribute which is to be set. It can be REPLICATE, READONLY, LOCKED, INVALIDATING
##PD  @attributeSetting ^^ The bit value of the attribute (0 = Off or 1 = On)
##PD  @databaseName ^^ The database name
*/

as
begin
	set nocount on;

	declare @attrib integer;
	declare @attribVal integer;
	declare @updateFlg integer;
	declare @setting bit;
	declare @attribute varchar(25);
	declare @dbName varchar(125);
	declare @dbType varchar(3);
	declare @sqlStmt varchar(max);
	declare @nsqlStmt nvarchar(max);

	set @attrib = 0;
	set @updateFlg = 0;

	if @databaseName = ''
		set @dbName = ltrim(rtrim(DB_NAME()));
	else
		set @dbName = ltrim(rtrim(@databaseName));

	--Enclose within square brackets
	execute absp_getDBName @dbName out, @dbName;

	--Get attributes for given node--
	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit);
	insert into @TableVar exec absp_InfoTableAttribAllGet  @nodeType , @nodeKey, @dbName;

	declare curs cursor for
		select A.ATTRIBUTE, A.SETTING, B.ATTRIBVAL  from @TableVar A
		   inner join ATTRDEF B on A.ATTRIBUTE = B.ATTRIBNAME;
	open curs
	fetch curs into @attribute, @setting, @attribVal;
	while @@fetch_status=0
	begin
		if @attribute = @attributeName
		begin
			if  @attributeSetting <> @setting
			begin
				--Settings need to be modified --
				set @setting = @attributeSetting;
				set @updateFlg = 1;
			end
		end

		set @attrib = @attrib + @setting * @attribVal;
		fetch curs into @attribute, @setting, @attribVal;
	end
	close curs
	deallocate curs

	if @updateFlg = 0
	begin
		--Nothing to update
		return;
	end

	--Check for RDB
	set @nsqlStmt = N'select top 1 @dbType=DbType from '+ @dbName + '..RQEVersion';
	execute sp_executesql @nsqlStmt,N'@dbType varchar(3) output',@dbType=@dbType output;
	if (@dbType = 'RDB' and @nodeType < 101)
		set @nodeType = 101;

	--Update ATTRIB column of the required INFO table--
	if @nodeType = 12
		UPDATE CFLDRINFO set ATTRIB = @attrib where CF_REF_KEY = @nodeKey;
	else
	begin
		set @sqlStmt = 'declare @attrib integer;'

		if @nodeType = 0
			set @sqlStmt = @sqlStmt +
				'update '+ @dbName +'..FLDRINFO set ATTRIB ='+rtrim(str(@attrib))+' where FOLDER_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 13
			set @sqlStmt = @sqlStmt +
				'update '+ @dbName +'..CURRINFO set ATTRIB ='+rtrim(str(@attrib))+' where CURRSK_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 1
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..APRTINFO set ATTRIB ='+rtrim(str(@attrib))+' where APORT_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 2
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..PPRTINFO set ATTRIB ='+rtrim(str(@attrib))+' where PPORT_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 3 or @nodeType =23
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..RPRTINFO set ATTRIB ='+rtrim(str(@attrib))+' where RPORT_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 7 or @nodeType =27
			set @sqlStmt = @sqlStmt +
				'update '+ @dbName +'..PROGINFO set ATTRIB ='+rtrim(str(@attrib))+' where PROG_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 10 or @nodeType =30
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..CASEINFO set ATTRIB ='+rtrim(str(@attrib))+' where CASE_KEY='+rtrim(str(@nodeKey));
		else if  @nodeType = 64
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..ExposureInfo set ATTRIB ='+rtrim(str(@attrib))+' where ExposureKey='+rtrim(str(@nodeKey));
		else if  @dbType = 'RDB' and (@nodeType = 101 or @nodeType = 102 or @nodeType = 103)
			set @sqlStmt =  @sqlStmt +
				'update '+ @dbName +'..RdbInfo  set ATTRIB ='+rtrim(str(@attrib))+' where NodeType='+rtrim(str(@nodeType)) +' and rdbInfoKey=' + rtrim(str(@nodeKey));
		execute(@sqlStmt);
	end
end
