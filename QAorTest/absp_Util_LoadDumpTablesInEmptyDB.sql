if exists(select * from sysobjects where id = object_id(N'absp_Util_LoadDumpTablesInEmptyDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_LoadDumpTablesInEmptyDB
end

go
create procedure absp_Util_LoadDumpTablesInEmptyDB @pathToLoadTbls varchar(max),@debugFlag int = 1 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:    	This procedure loads all the tables DUMPTBLS table into an empty database.

Returns:    Nothing

====================================================================================================

</pre>
</font>

##BD_END

##PD  pathToLoadTbls  ^^ The path from where records of tables will be loaded into databse.
##PD  debugFlag  ^^ The flag which is used to show mwssage or not.

*/ 
as
begin
   declare @me varchar(max)
   declare @msg varchar(max)
   declare @sql varchar(max)
   declare @bAbout int
   declare @tablename varchar(100)
   
  set @me = 'absp_Util_LoadDumpTablesInEmptyDB: '
   set @msg = @me+'starting'
   set @sql = ''
   if @debugFlag > 0
   begin
      execute absp_messageEx @msg
   end
   exec @bAbout = absp_Util_IsBackupInProgress
   if @bAbout = 0
   begin
      declare curs_dumpTables cursor fast_forward for select distinct TABLE_NAME as TBLNAME from DUMPTBLS
      open curs_dumpTables
      fetch next from curs_dumpTables into @tablename
      while @@FETCH_STATUS = 0
      begin
         set @pathToLoadTbls = ltrim(rtrim(@pathToLoadTbls)) + '\' + ltrim(rtrim(@tablename)) + '.txt'
         exec absp_Util_LoadData @tablename, @pathToLoadTbls, '|'
         set @sql = 'load table '+@tablename+' from '''+@pathToLoadTbls+'\\'+@tablename+'.txt'' delimited by ''|'' format ascii quotes off '
         if @debugFlag > 0
         begin
            execute absp_messageEx @sql
         end
         fetch next from curs_dumpTables into @tablename
      end
      close curs_dumpTables
      deallocate curs_dumpTables
   end
   else
   begin
      set @msg = @me+'Backup is in Progress. Wait for backup to complete to LoadDumpTables.'
      print @msg
      execute absp_messageEx @msg
   end
   if @debugFlag > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end



