if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DumpTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DumpTables
end
go

create  procedure absp_Util_DumpTables  @pathToUnload varchar(2000),
										@currFldrKeyList varchar(MAX),
										@debugFlag int = 1,
										@userName varchar(100) = '', 
										@password varchar(100) = '' 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure retrieves the data from dump tables into a specified location.


Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @pathToUnload 	^^  Location where the data needs to be unloaded. 
##PD  @debugFlag	^^  Whether to debug with any message (> 0 to debug)		
##PD  @userName ^^ The userName - required in case of SQL authentication
##PD  @password ^^ The password - required in case of SQL authentication
*/
as
begin
   /* 
	This procedure will unload all the tables listed in DUMPTBLS table into a given folder
	
   */
   set nocount on
   
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @msg varchar(255)
   declare @sql varchar(MAX)
   declare @curs1_TBLNAME CHAR(120)
   declare @cursCF_DBNAME varchar(128)
   declare @serverName varchar(100)
   declare @errCode int
   declare @fileName varchar(255)
   declare @tmpPathToUnload varchar(2000)
   -- initialize standard items
   set @me = 'absp_Util_DumpTables: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   execute absp_Util_DeleteFile @pathToUnload
   execute absp_Util_CreateFolder @pathToUnload
       	
   if @debug > 0
   begin
      execute absp_MessageEx @msg
   end
   -- Get the server name for bcp utility --
   select @serverName = name from SYS.SERVERS where server_id=0

   declare curs1  cursor FAST_FORWARD  FOR 
		select distinct DUMPTBLS.TABLE_NAME from DUMPTBLS, DICTTBL where DUMPTBLS.TABLE_NAME = DICTTBL.TABLENAME and (SYS_DB in ('Y', 'L') or COM_DB in ('Y', 'L')) -- to handle sql type work
   open curs1
   fetch next from curs1 into @curs1_TBLNAME
   while @@fetch_status = 0
   begin
       set @fileName=@pathToUnload + '\' + ltrim(rtrim(@curs1_TBLNAME)) + '.txt'
       --Defect SDG__00018799 - Call  absp_Util_unLoadData to unload table--
       exec @errCode =  absp_Util_unLoadData 'T',@curs1_TBLNAME,@fileName,'|', @userName=@userName,@password=@password
       if @errCode<>0 
       begin
		set @msg = @me+' '+ERROR_MESSAGE()
		exec absp_messageEx  @msg 
		return
	end
      
      fetch next from curs1 into @curs1_TBLNAME
   end
   close curs1
   deallocate curs1
   
   
   set @sql = 'select DB_NAME from CFLDRINFO where CF_REF_KEY in (' + @currFldrKeyList + ') ' 
   execute('declare cursCF cursor global FAST_FORWARD  FOR '+@sql)
   	
   	open cursCF
	fetch next from cursCF into @cursCF_DBNAME
	while @@fetch_status = 0
      	begin
   		
   	    set @tmpPathToUnload = @pathToUnload + '\' + @cursCF_DBNAME	
   	    execute absp_Util_CreateFolder @tmpPathToUnload
   	    
	    declare curs1  cursor FAST_FORWARD  FOR 
			select distinct DUMPTBLS.TABLE_NAME from DUMPTBLS, DICTTBL where DUMPTBLS.TABLE_NAME = DICTTBL.TABLENAME and CF_DB in ('Y', 'L') -- to handle sql type work
	      open curs1
	      fetch next from curs1 into @curs1_TBLNAME
	      while @@fetch_status = 0
	      begin
		  set @fileName = @tmpPathToUnload + '\' + ltrim(rtrim(@curs1_TBLNAME)) + '.txt'
		 
		  print @fileName
		  
		  --Enclose within square brackets--
   		  execute absp_getDBName @cursCF_DBNAME out, @cursCF_DBNAME
		  
		  set @sql = @cursCF_DBNAME + '..absp_Util_unLoadData ''T'', ''' + dbo.trim(@curs1_TBLNAME) + ''', ''' + dbo.trim(@fileName) + ''', ''|'', ''' + dbo.trim(@userName) + ''', ''' + dbo.trim(@password) + ''''
		  print @sql
		  execute (@sql) 

		 fetch next from curs1 into @curs1_TBLNAME
	      end
	      close curs1
	   deallocate curs1
	
	fetch next from cursCF into @cursCF_DBNAME
        end
        close cursCF
	deallocate cursCF
   
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_MessageEx @msg
   end
end


