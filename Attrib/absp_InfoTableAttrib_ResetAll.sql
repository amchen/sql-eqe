if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttrib_ResetAll') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttrib_ResetAll;
end
go

create procedure absp_InfoTableAttrib_ResetAll 	@databaseName varchar(125) = '', @resetBrowserRegenAttrib int=1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the attribute bits in the all INFO tables


Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @databaseName ^^ The database name
*/

as
begin
	set nocount on;

	declare @dbName varchar(125);
	declare @dbType varchar(3);
	declare @sqlStmt varchar(max);
	declare @nsqlStmt nvarchar(max)
	declare @setting bit;
	declare @nodeKey int;
	declare @nodeType int;
	declare @attrBit bit;
	declare @tableName varchar(100);
	declare @colName varchar(100);
	declare @sql nvarchar(max);
	declare @regenAttrExists int;
	
	set @setting=0;
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
	
    if @dbType = 'RDB'
    begin
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..RdbInfo set Attrib = 32;'
		execute(@sqlStmt);
    end
    else
    begin
		if @resetBrowserRegenAttrib=0
		begin
			set @regenAttrExists=0;
			set @sql='select @regenAttrExists=1 from ' + @dbName + '.sys.procedures where name=''absp_InfoTableAttribGetBrowserDataRegenerate'''
			exec sp_executesql @sql,N'@regenAttrExists int out',@regenAttrExists out
			if @regenAttrExists=1
			begin
				--Fixed defect 10166
				--The BrowserDataRegen attribute is getting set and thuhs the regeneration button disappears during database copy--
				--Exclude setting the attribute--
				create table #PORTFOLIO_LIST (NodeKey int, NodeType int, AttrBit bit)
				exec('insert into #PORTFOLIO_LIST select Pport_Key,2,0 from  ' + @dbName + '..PprtInfo union select Prog_Key,27,0 from ' + @dbName + '..ProgInfo')
				select * into #TMP_PPORTLIST from #PORTFOLIO_LIST
				
				declare c1 cursor for select NodeKey,NodeType from #TMP_PPORTLIST
				open c1
				fetch c1 into @nodeKey,@nodeType
				while @@fetch_Status=0
				begin		
					set @sql = 'exec ' + @dbName +'..absp_InfoTableAttribGetBrowserDataRegenerate  @setting  out, ' + str(@nodeType) + ',' + str(@nodeKey)		
					exec sp_executesql @sql,N'@setting bit out',@setting out
					update #PORTFOLIO_LIST set AttrBit=@setting where NodeKey=@nodeKey and NodeType=@nodeType
					
					fetch c1 into @nodeKey,@nodeType
				end
				close c1
				deallocate c1
			end
		end
 
 	    set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..CFLDRINFO set Attrib = 32 where DB_NAME = '''+ @dbName +''';'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..FLDRINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..CURRINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..APRTINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..PPRTINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..RPRTINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..PROGINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..CASEINFO set Attrib = 0;'
		set @sqlStmt = @sqlStmt + ' update ' + @dbName + '..ExposureInfo set Attrib = 0;'
		execute(@sqlStmt);
		
		if @resetBrowserRegenAttrib=0 and @regenAttrExists=1
		begin
			--set regen bit back--
			declare c1 cursor for select NodeKey,NodeType,AttrBit from #PORTFOLIO_LIST
			open c1
			fetch c1 into @nodeKey,@nodeType,@attrbit
			while @@fetch_Status=0
			begin
				if @nodetype=2 
				begin
					set @tableName='PprtInfo' 
					set @colName='Pport_Key';
				end
				else
				begin
					set @tableName='ProgInfo';
					set @colName='Prog_Key';
				end
				if @attrbit=1 
				begin
					set @sqlStmt=  ' update ' + @dbName + '..' + @tableName + ' set Attrib = 131072 where ' + @colNAME + '=' + CAST(@nodeKey AS VARCHAR(30));
					exec(@sqlStmt);
				end
				fetch c1 into @nodeKey,@nodeType,@attrbit
			end
			close c1
			deallocate c1
		end
	end 
end
