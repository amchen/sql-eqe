if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getLockId') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_getLockId
end
go

create procedure absp_getLockId @Node_Key INT ,@Node_Type INT ,@Extra_Key INT ,@dbKey INT = 0, @dbName varchar(120) = '', @debugFlag INT = 0 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure generates the lockid for a given nodekey based on the parent 
node and returns the lock id.

Returns:       Returns a resultset containing the generated lock Id for the given node.

=================================================================================
</pre>
</font>
##BD_END

##PD  Node_Key  ^^ The key for the node for which the lockId is to be generated.
##PD  Node_Type ^^ The type of the node for which the lockId is to be generated.
##PD  Extra_Key ^^ An integer value passed to the next procedure absp_CreateTreeMap.
##PD  dbKey ^^ database key or databaseID
##PD  dbName    ^^ databaseName used for RDB database
##PD  debugFlag ^^ A flag value used for debugging.

##RS  lockId    ^^ The generated lock id for the given node.
*/
begin try
   declare @me varchar(max)
   declare @debug int -- to handle sql type work
  -- put other variables here
   declare @msg varchar(max)
   declare @sql varchar(max)
   declare @cleanupSql varchar(max)
   declare @nodeKey int
   declare @curRefKey int
   declare @nodeType int -- to handle sql type work
   declare @extraKey int
   declare @lockId varchar(max)
   declare @parentKey int
   declare @parentType int
   declare @strLockId varchar(max)
   declare @nsql nvarchar(max)
   declare @isRDB int
   declare @rdbName varchar(120)
   declare @rdbID int
   declare @NonRDBConstant int
   ---- Create the variables for the random number generation
   declare @exist int
   declare @lockSessionKey int
   
   set nocount on;
   
   -------------- begin --------------------
            
   -- initialize standard items
   set @me = 'absp_getLockId: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   set @lockId = ''
   
 
   ---- Get the unique lock sessionID
    select @lockSessionKey  = 1 + coalesce(max(LockSessionKey), 0)  from [commondb].dbo.LockSession
   insert into [commondb].dbo.LockSession (LockSessionKey) values(@lockSessionKey)

   
   set @cleanupSql =  'delete from [commondb].dbo.LockTreeMap where LockSessionKey = ' + rtrim(str(@lockSessionKey)) + 
   ';delete from [commondb].dbo.LockIDInfo where LockSessionKey = ' + rtrim(str(@lockSessionKey)) +
	 ';delete from [commondb].dbo.LockSession where LockSessionKey = ' + rtrim(str(@lockSessionKey)) 

   --print ' cleanup = ' + @cleanupSql
      
   ---------------------------------------------------------------------------------------------
   --the stored procedure is executed within an EDB database, we try to get lockID for EDB database
   ---------------------------------------------------------------------------------------------
   if DB_NAME() != 'commondb' or @Node_Type < 100
   begin
   
     if @dbKey <= 0
        set @dbName =  ltrim(rtrim(DB_NAME()))
     else
        select @dbName = ltrim(rtrim(DB_NAME)) from CFLDRINFO where cf_ref_key = @dbKey  
     
     if @Node_Type = 7
     begin
      execute @Node_Type  = absp_Util_GetProgramType @Node_Key
     end
     
     set @nsql = 'execute [' + @dbName + ']..absp_CreateLockTreeMap ' + ltrim(str(@lockSessionKey)) + ',' + 
				ltrim(str(@Node_Key)) + ',' + ltrim(str(@Node_Type)) + ',' +ltrim(str(@Extra_Key))+ ',0,1,0,'''',' + ltrim(str(@debugFlag))
	 exec sp_executesql @nsql
 --    execute absp_CreateLockTreeMap @lockSessionKey,@Node_Key,@Node_Type,@Extra_Key,0,1,0,'',@debugFlag
     
     set @nsql = N'select @exist = 1 from [commondb].dbo.LockTreeMap'
     --print @nsql
     exec sp_executesql @nsql, N'@exist int OUTPUT', @exist OUTPUT
            
     if @exist != 1 -- no data found in Table LockTreeMap
     begin
        select @lockId
        --print ' cleanup = ' + @cleanupSql
  	    execute ( @cleanupSql )
        return 
     end
     
    -- The first entry in the table is for the Currency Folder (after we query TMP_TREEMAP with order by
    -- AUTOKEY desc ). This is the special case since the node id for the Currency Node is only the NodeKey
    --select PARENT_KEY as @parentKey, PARENT_TYPE as @parentType, CHILD_KEY as @nodeKey from #TMP_TREEMAP  where CHILD_KEY= Node_key and CHILD_TYPE = Node_type;    	
    -- Also to identify which currency DB the node resides on, the currency reference key in CFLDRINFO will be added to the key set of the currency node Id.
    -- This means from now on instead of containing only the @nodeKey, the currency node Id will be equal to currencyNodeType(=0) + ':' + @curRefkey + ':' + @nodeKey
     set @nsql = N'select distinct @nodeKey = childKey from [commondb].dbo.LockTreeMap where parentKey=0 and parentType=0 and LockSessionKey = ' + rtrim(str(@lockSessionKey))
     print @nsql
     exec sp_executesql @nsql, N'@nodeKey int OUTPUT', @nodeKey OUTPUT

     select @curRefkey = CF_REF_KEY from CFLDRINFO where FOLDER_KEY = @nodeKey and DB_NAME=@dbName
     set @sql = ' insert into [commondb].dbo.LockIDInfo values (' + rtrim(str(@lockSessionKey)) +',''0:' + ltrim(rtrim(str(@curRefkey))) + ':' + ltrim(rtrim(str(@nodeKey)))+ ''')'
	 --print @sql
     execute(@sql)
     set @strLockId = '0:' + ltrim(rtrim(str(@curRefkey))) + ':' + ltrim(rtrim(str(@nodeKey)))

     execute absp_generateLockIDInfo @lockSessionKey,@nodeKey,0,0,@strLockId
     
     set @sql = 'select rtrim(ltrim(lockId)) as LockId from [commondb].dbo.LockIDInfo where LockSessionKey = ' + rtrim(str(@lockSessionKey))
     --print @sql
     execute (@sql)
   
   end -- if DB_NAME() != 'commondb'
   
   ---------------------------------------------------------------------------------------------------------------
   -- else if the stored procedure is executed within commondb, we try to get lockID for RDB database from commondb
   --------------------------------------------------------------------------------------------------------------
   else -- if DB_NAME() = 'commondb' 
   begin
       -- verify if the database is RDB
       set @NonRDBConstant = 0
       -- get the correct databaseID for the RDB database using the given RDB database Name
       if @dbKey < 7 -- excluding system databases, eqcatsystem and commondb
       begin
          -- first is to test if given @dbName is valid
          set @rdbID = @NonRDBConstant
          select @rdbID = database_id from sys.databases where name=@dbName
          --print '@rdbID=' + str(@rdbID)

          set @isRDB = 0
          -- test if @dbname is a RDB database
          if @rdbID != @NonRDBConstant  and OBJECT_ID('[' + @dbName + '].dbo.RQEVersion','U') IS NOT NULL and
            OBJECT_ID('[' + @dbName + '].dbo.RdbInfo','U') IS NOT NULL
          begin
            set @nsql = N'select @isRDB = 1 from [' + @dbName + '].dbo.RQEVersion where DbType =''RDB'''
            --print @nsql
            exec sp_executesql @nsql, N'@isRDB int OUTPUT', @isRDB OUTPUT
          end
          
          -- if @dbname is a RDB database, obtain the dbKey or databaseID
          if @isRDB = 1
            set @dbKey = @rdbID
          else
          -- @dbname is not valid return
          begin
            select @lockId
            --print ' cleanup = ' + @cleanupSql
            execute ( @cleanupSql )
            return
          end
       end --if @dbKey < 7
       
       else --if @dbKey >= 7
       begin
          set @rdbName = 'notRDB'
          -- get a valid @dbName using given databaseID=dbKey
          select @rdbName = rtrim(name) from sys.databases where database_id=@dbKey 
          
          -- test if @rdbName is a RDB database
          -- print '@rdbName=' + @rdbName
          set @isRDB = 0
          if  @rdbName != 'notRDB' and OBJECT_ID ('[' + @rdbName + '].dbo.RQEVersion','U') IS NOT NULL and
            OBJECT_ID('[' + @rdbName + '].dbo.RdbInfo','U') IS NOT NULL
          begin
             set @nsql = N'select @isRDB = 1 from [' + @rdbName + '].dbo.RQEVersion where DbType =''RDB'''
             --print @nsql
             exec sp_executesql @nsql, N'@isRDB int OUTPUT', @isRDB OUTPUT
          end

          -- obtain @dbName if @rdbName is a RDB database
          if @isRDB = 1
            set @dbName = @rdbName
          else
            set @rdbName = 'notRDB'

          -- @rdbName is invalid, try to get databaseID from given @dbName
          if  @rdbName = 'notRDB' 
          begin
             -- test if @dbName is a RDB type
             set @isRDB = 0

             if OBJECT_ID ('[' + @dbName + '].dbo.RQEVersion','U') IS NOT NULL and
              OBJECT_ID('[' + @dbName + '].dbo.RdbInfo','U') IS NOT NULL
             begin 	
              set @nsql = N'select @isRDB = 1 from [' + @dbName + '].dbo.RQEVersion where DbType =''RDB'''
              --print @nsql
              exec sp_executesql @nsql, N'@isRDB int OUTPUT', @isRDB OUTPUT
             end

             if @isRDB = 0
             begin
               select @lockId
               --clean up
               execute(@cleanupSql)
               return
             end
            
            -- if @dbName is valid, get @dbKey = databaseID
            set @rdbID = @NonRDBConstant
            select @rdbID = database_id from sys.databases where name=@dbName

            if  @rdbID = @NonRDBConstant
            begin
              select @lockId
              -- clean up
              --print ' cleanup = ' + @cleanupSql
              execute ( @cleanupSql )
              return
            end 
            else
            begin
              set @dbKey = @rdbID
            end 
            
         end  --if  @rdbName = 'notRDB' 
         
       end --if @dbKey >= 7

      --print ' @isRDB =' + str(@isRDB)
      --print '@databaseID =' + str(@dbKey)
      --print '@dbName =' + @dbName
      
       execute absp_CreateLockTreeMap @lockSessionKey,@Node_Key,@Node_Type,@Extra_Key,0,1,@dbKey,@dbName,@debugFlag
       
       set @nsql = N'select @exist = 1 from [commondb].dbo.LockTreeMap where LockSessionKey= ' + rtrim(str(@lockSessionKey))
       exec sp_executesql @nsql, N'@exist int OUTPUT', @exist OUTPUT

       if @exist != 1 -- no data found in LockTreeMap
       begin       
        select @lockId        
        -- clean up the temp table
        -- print ' cleanup = ' + @cleanupSql
		   execute ( @cleanupSql )
       	return 
       end

      -- The first entry in the table is for the Currency Folder (after we query TMP_TREEMAP with order by
      -- AUTOKEY desc ). This is the special case since the node id for the Currency Node is only the NodeKey
      --select PARENT_KEY as @parentKey, PARENT_TYPE as @parentType, CHILD_KEY as @nodeKey from #TMP_TREEMAP  where CHILD_KEY= Node_key and CHILD_TYPE = Node_type;    	
      -- Also to identify which currency DB the node resides on, the currency reference key in CFLDRINFO will be added to the key set of the currency node Id.
      -- This means from now on instead of containing only the @nodeKey, the currency node Id will be equal to currencyNodeType(=0) + ':' + @curRefkey + ':' + @nodeKey
       set @nsql = N'select distinct @nodeKey = childKey  from [commondb].dbo.LockTreeMap where parentKey = ' + rtrim(str(@dbKey)) + ' and parentType = 101 and LockSessionKey=' + 
 rtrim(str(@lockSessionKey))
       exec sp_executesql @nsql, N'@nodeKey int OUTPUT', @nodeKey OUTPUT     
       set @sql = ' insert into [commondb].dbo.LockIDInfo values (' + rtrim(str(@lockSessionKey)) + ', ''101:' + ltrim(rtrim(str(@dbKey))) + ':' + ltrim(rtrim(str(@nodeKey)))+ ''')'
       --print @sql
       execute(@sql)
       set @strLockId = '101:' + ltrim(rtrim(str(@dbKey))) + ':' + ltrim(rtrim(str(@nodeKey)))
       execute absp_generateLockIDInfo @lockSessionKey,@nodeKey,101,0,@strLockId,@debugFlag
            
       set @sql = 'select rtrim(ltrim(lockId)) as LockId from [commondb].dbo.LockIDInfo where LockSessionKey=' +  rtrim(str(@lockSessionKey))
	     --print @sql
	   execute(@sql)
    
   end -- else if DB_NAME() = 'commondb' 
      
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_MessageEx @msg
   end
   
   -- clean up the temp table
   --print ' cleanup = ' + @cleanupSql
	 execute ( @cleanupSql )


end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
	--print 'aborted cleanup = ' + @cleanupSql
	execute ( @cleanupSql )	
end catch   