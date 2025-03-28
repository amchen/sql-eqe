if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_SplitSystemTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SplitSystemTables;
end
go

create procedure absp_Util_SplitSystemTables

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure splits system lookup tables in systemdb into [tablename]_S, and [tablename]_U
and create the views for system lookup tables in the user database where this procedure is executed from


Returns:       None
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDB	^^source DB : either systemdb or commondb

*/
AS
begin

set nocount on

declare @tableName varchar(120)
declare @cloneName varchar(120)
declare @dbSysBit char(1)
declare @dbComBit char(1)
declare @dbCfBit char(1)
declare @sql nvarchar(max)
declare @sql2 nvarchar(max)
declare @userDB varchar(120)
declare @curTableName varchar(120)

    	set @userDB = DB_NAME()
    	if(@userDB = 'systemdb' or @userDB = 'commondb')
    	begin
    		print 'This stored procedure must be executed on a user database not systemdb or commondb database!'
    		return
    	end

	if exists (SELECT 1 FROM [systemdb].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='DICTCLON')
	begin
		set @sql='use systemdb declare curs1 cursor fast_forward global for ' +
		' select DICTCLON.tablename, clonename, sys_db, com_db, cf_db from dictclon inner join DICTTBLX on DICTCLON.TABLENAME = DICTTBLX.TABLENAME ' +
		' where type not in (''a'', ''p'') union ' +
		'select DICTCLON.tablename, clonename, sys_db, com_db, cf_db from dictclon where DICTCLON.TABLENAME =''D0410''' +
		' order by DICTCLON.tablename '
		exec(@sql)

		open curs1
		fetch next from curs1 into @tableName, @cloneName, @dbSysBit, @dbComBit, @dbCfBit
		while @@fetch_status = 0
		begin

			if @dbSysBit='L'
			begin
				select @sql = 'use systemdb ' +
				' IF NOT EXISTS (SELECT * FROM [systemdb].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @cloneName  + ''') ' +
				' begin ' +
				' exec absp_Migr_MakeCopyTable '''', ''_S'','''',''' + @tableName +''',0,''systemdb'' ' +
				' end '
				print @sql
				exec sp_executesql @sql

				-- remove user trans_id from D0410_S
				if ltrim(rtrim(@tableName)) = 'D0410'
				begin
					select @sql = 'use systemdb ' +
					' IF EXISTS (SELECT * FROM [systemdb].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @cloneName  + ''') ' +
					' delete from [systemdb].dbo.' + @cloneName  + ' where TRANS_ID not in(57,58,59,10001,10002) '
					print @sql
					exec sp_executesql @sql
				end
			end
			if @dbCfBit='Y'
			begin
				select @sql = 'use systemdb ' +
				--' declare @sqlout varchar(2000) ' +
				' IF NOT EXISTS (SELECT * FROM [' + @userDb + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @cloneName  + ''') ' +
				' exec absp_Migr_MakeCopyTable '''', ''_U'','''',''' + @tableName +''',0,''' + @userDb + ''' '
				print @sql
				exec sp_executesql @sql

				-- remove system trans_id from D0410_S
				if ltrim(rtrim(@tableName)) = 'D0410'
				begin
					select @sql = 'use systemdb ' +
					' IF EXISTS (SELECT * FROM [' + @userDb + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @cloneName  + ''') ' +
					' delete from [' +  @userDb + '].dbo.' + @cloneName  + ' where TRANS_ID in(57,58,59,10001,10002) '
					print @sql
					exec sp_executesql @sql
				end
				else
				begin
					select @sql = 'use systemdb ' +
					' IF EXISTS (SELECT * FROM [' + @userDb + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE'' AND TABLE_NAME=''' + @cloneName  + ''') ' +
					' delete [' +  @userDb + '].dbo.' + @cloneName
					print @sql
					exec sp_executesql @sql
				end

			end
			set @curTableName = @tableName
			fetch next from curs1 into @tableName, @cloneName, @dbSysBit, @dbComBit, @dbCfBit

		end
		close curs1
		deallocate curs1
	end
end
