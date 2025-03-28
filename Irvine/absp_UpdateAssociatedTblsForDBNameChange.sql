if exists(select * from sysobjects where id = object_id(N'absp_UpdateAssociatedTblsForDBNameChange') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateAssociatedTblsForDBNameChange
end
 go
create procedure absp_UpdateAssociatedTblsForDBNameChange @sourceDbName varchar(130), @targetDbName varchar(130)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will update all tables having column "DB_NAME" when we modify DB_NAME
in CFLDRINFO

Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDbName ^^  DB_NAME value which is to be modified
##PD  @targetDbName ^^  DB_NAME value to be used as modified name

*/
begin

   set nocount on

   declare @curs_tableName	varchar(120)
   declare @sql 		nvarchar(max)
   declare @cfRefKey 		int
   declare @hasCfRefKey 	int
   declare @updatedTblsList 	varchar(max)
   declare @cursTbls1 		cursor

   set @cfRefKey = 0
   set @updatedTblsList = ''

  select @cfRefKey = CF_REF_KEY from CFLDRINFO where DB_NAME = '''' + @targetDbName + ''''

  set @updatedTblsList = '''CFLDRINFO'', ''RQEVersion'', ''Version'''

  print @updatedTblsList

  -- get all tables having column "DB_NAME" except CFLDRINFO and VERSION
  set @sql = 'select DICTCOL.TABLENAME from DICTCOL, DICTTBL where DICTTBL.TABLENAME = DICTCOL.TABLENAME and DICTCOL.FIELDNAME = ''DB_NAME'' and DICTCOL.TABLENAME not in (' + @updatedTblsList+') and DICTTBL.COM_DB <> ''N'''

  begin
  execute ('declare cursTbls cursor global for  ' + @sql)

  open cursTbls
  fetch next from cursTbls into @curs_tableName
  while @@fetch_status = 0
  begin
     set @hasCfRefKey = 0

     select @hasCfRefKey = 1 from DICTCOL where TABLENAME = @curs_tableName and FIELDNAME = 'CF_REF_KEY'

     set @sql = 'update ' + dbo.trim(@curs_tableName) + ' set DB_NAME = ''' + @targetDbName + ''''

     if (@hasCfRefKey = 1)
     	set @sql = @sql + ', CF_REF_KEY = ' + dbo.trim(str(@cfRefKey))

     set @sql = @sql + ' where DB_NAME = ''' + @sourceDbName + ''''

     print @sql
     execute(@sql)

     set @updatedTblsList = @updatedTblsList + ', ''' + @curs_tableName + ''''

     fetch next from cursTbls into @curs_tableName
  end
  close cursTbls
  deallocate cursTbls

  end

	-- Create Exposure.Report views to IDB because that is where they are now populated
	set @sql = N'exec ' + quotename(@targetDbName) + '..absp_Util_CreateExposureViewsToIDB';
	execute(@sql);

end
