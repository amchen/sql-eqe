if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_createLockTreeMap') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_createLockTreeMap
end
go

create procedure
absp_createLockTreeMap @lockSessionKey int,@Node_Key int,@Node_Type int,@Extra_Key int,@createTmpTable int = 0,@recursive int = 1,@databaseID int = 0,@dbName varchar(120) = '',@debugFlag int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates a given table with the parent Tree Hierarchy data for a given
Node Key and Node Type.

Returns:       Nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  @lockSessionKey ^^ The lock session key.
##PD  @Node_Key       ^^ The key for the node.
##PD  @Node_Type      ^^ The type of the node.
##PD  @Extra_Key      ^^ An integer value.
##PD  @createTmpTable ^^ A flag value used for creating a temporary table if required(default set to 0)
##PD  @recursive      ^^ A flag value used for recursive loop(default set to 1).
##PD  @databaseID     ^^ system databaseID for RDB database (not used by EDB database)
##PD  @dbName         ^^ RDB database name (not used by EDB database)
##PD  @debugFlag      ^^ A flag value used for debugging(default set to 0).

*/
as
begin try

set nocount on

/*
This procedure will try to find the TreeHierarchy for a given Node Key and Node Type.
If the parent node type is not curreny node then we need to recurse thru
the parent nodes until the currency node is encountered.
First add the currency node in ##TMP_TREEMAP table then add the other nodes in
correct order.

This is a generic procedure that we create a table containing all the parent-child relation


*/
  -- standard declares
   -- Procedure Name
   -- for messaging
   declare @me varchar(max)
   declare @debug int -- to handle sql type work
   declare @msg varchar(max) -- to handle sql type work
   -- put other variables here
   declare @sql nvarchar(4000)
   declare @sql1 varchar(max)
   declare @parentKey int
   declare @parentType int
   declare @isCurrNode int
   declare @extraKey int
   declare @isPasteLink int
   declare @isExists int
   declare @msgText varchar(max)
   declare @curs1 cursor

  -- initialize standard items
   set @me = 'absp_CreateLockTreeMap: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   set @sql1 = ''
  -- intialize other variables here
   set @parentKey = 0
   set @parentType = 0
   set @isCurrNode = 0
   set @extraKey = -1
   if @debug > 0
   begin
      execute absp_MessageEx @msg
   end


   ---------------------------------------------------------------------------------------------
   --the stored procedure is executed within an EDB database, we try to get lockID for EDB database
   ---------------------------------------------------------------------------------------------
   if DB_NAME() != 'commondb'
   begin
       if @Node_Type = 12 
       begin
		      set @node_type = 0
       end	
       -- Fixed code to handle Multi-Treaty Node
       if @Node_Type = 0
       begin

          set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey,ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
          ' select ' + rtrim(str(@lockSessionKey)) +',FOLDER_KEY, 0 , '+rtrim(str(@Extra_Key))+', '+
          rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+' from FLDRMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))

          if @debug > 0
          begin
             set @msgText = 'Node type = 0; Query = '+@sql
             execute absp_MessageEx @msgText
          end
          execute(@sql)
          set @extraKey = 0

       end -- if @Node_Type = 0

        if @Node_Type = 1
        begin
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey,ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select ' + rtrim(str(@lockSessionKey)) +',FOLDER_KEY, 0, '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from FLDRMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
              if @debug > 0
              begin
                set @msgText = 'Node type = 1; Query = '+@sql
                execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

        end -- if @Node_Type = 1

        if @Node_Type = 2
        begin
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select ' + rtrim(str(@lockSessionKey)) +',FOLDER_KEY, 0, '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from FLDRMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
              if @debug > 0
              begin
                 set @msgText = 'Node type = 2; Check FLDRMAP; Query = '+@sql
                 execute absp_MessageEx @msgText
              end
              execute(@sql)

              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select '+ rtrim(str(@lockSessionKey)) +',APORT_KEY, 1, '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from APORTMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
              if @debug > 0
              begin
                 set @msgText = 'Node type = 2; Check APORTMAP; Query = '+@sql
                 execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

        end --if @Node_Type = 2

        if @Node_Type = 3 or @Node_Type = 23
        begin
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select '+ rtrim(str(@lockSessionKey)) +',FOLDER_KEY, 0, '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from FLDRMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))

              if @debug > 0
              begin
                    set @msgText = 'Node type = 3; Check APORTMAP; Query = '+@sql
                    execute absp_MessageEx @msgText
              end
              execute(@sql)

              set @sql = ' insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select '+ rtrim(str(@lockSessionKey)) +',APORT_KEY, 1, '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from APORTMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
              if @debug > 0
              begin
                    set @msgText = 'Node type = '+str(@Node_Type)+' ; Check APORTMAP; Query = '+@sql
                    execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

         end --if @Node_Type = 3 or @Node_Type = 23

         if @Node_Type = 7
         begin
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select '+ rtrim(str(@lockSessionKey)) +',RPORT_KEY, 3 , '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
              ' from RPORTMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
              if @debug > 0
              begin
                       set @msgText = 'Node type = 7; Query = '+@sql
                       execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

         end --if @Node_Type = 7

         if @Node_Type = 27
         begin
               set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
               ' select '+ rtrim(str(@lockSessionKey)) +',RPORT_KEY, 23 , '+rtrim(str(@Extra_Key))+', '+rtrim(str(@Node_Key))+', '+rtrim(str(@Node_Type))+', '+rtrim(str(@Extra_Key))+
               ' from RPORTMAP where CHILD_KEY = '+rtrim(str(@Node_Key))+' and CHILD_TYPE = '+rtrim(str(@Node_Type))
               if @debug > 0
               begin
                        set @msgText = 'Node type = 27; Query = '+@sql
                        execute absp_MessageEx @msgText
               end
               execute(@sql)
               set @extraKey = 0

         end --if @Node_Type = 27

       if @Node_Type = 10
       begin
              select   @parentKey = PROG_KEY, @parentType = 7  from caseinfo where CASE_KEY = @Node_Key
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' values ('+rtrim(str(@lockSessionKey)) +','+str(@parentKey)+', '+str(@parentType)+', '+str(@Extra_Key)+', '+str(@Node_Key)+', '+str(@Node_Type)+', '+str(@Extra_Key)+')'
              if @debug > 0
              begin
                 set @msgText = 'Node type = 10; Query = '+@sql
                 execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

       end --if @Node_Type = 10

       if @Node_Type = 30
       begin
               select   @parentKey = PROG_KEY, @parentType = 27  from caseinfo where CASE_KEY = @Node_Key
               set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
               ' values ('+rtrim(str(@lockSessionKey)) +','+str(@parentKey)+', '+str(@parentType)+', '+str(@Extra_Key)+', '+str(@Node_Key)+', '+str(@Node_Type)+', '+str(@Extra_Key)+')'
               if @debug > 0
               begin
                  set @msgText = 'Node type = 30; Query = '+@sql
                  execute absp_MessageEx @msgText
               end
               execute(@sql)
               set @extraKey = 0

       end --if @Node_Type = 30
       
        if @Node_Type = 4
        begin
 
              set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
              ' select '+ rtrim(str(@lockSessionKey)) +',' + 'ParentKey, parentType, 0, '+str(@Node_Key)+', '+str(@Node_Type)+', '+str(@Extra_Key)+
              ' from ExposureMap where exposureKey = '+str(@Extra_Key)
              if @debug > 0
              begin
                set @msgText = 'Node type = 4; Query = '+@sql
                execute absp_MessageEx @msgText
              end
              execute(@sql)
              set @extraKey = 0

       end --if @Node_Type = 4

       if not exists (select 1 from NodeDef where Node_Type=@Node_Type)
       begin
             set @msgText = 'Invalid Node Type '+ltrim(rtrim(str(@Node_Type)))
             execute absp_MessageEx @msgText
       end

       set @sql = ' select distinct parentKey, parentType, parentExposureKey from [commondb].dbo.LockTreeMap where ChildKey = '+str(@Node_Key)+' and ChildType = '+str(@Node_Type)  + ' and LockSessionKey = ' + rtrim(str(@LockSessionKey))
       --print @sql
       
       if @debug > 0
       begin
          set @msgText = 'Query = '+@sql
          execute absp_MessageEx @msgText
       end

       if(@recursive = 1)
       begin
           --    execute('declare curs1 cursor global for '+@sql )
           set @sql = 'set @curs1 = cursor static for ' + @sql  + ' ; open @curs1'
           exec sp_executesql @sql, N'@curs1 cursor OUTPUT', @curs1 OUTPUT
           fetch next from @curs1 into @parentKey,@parentType,@extraKey

           while @@Fetch_Status = 0
           begin

             if @parentKey > 0
             begin

              set @sql1 = ' exec absp_CreateLockTreeMap  '+rtrim(str(@LockSessionKey)) +', ' +rtrim(str(@parentKey))+', '+rtrim(str(@parentType))+', '+rtrim(str(@extraKey))+' '
              if @debug > 0
              begin
                 execute absp_MessageEx @sql1
              end
              execute(@sql1)

            end --if @parentKey > 0

            fetch next from @curs1 into @parentKey,@parentType,@extraKey

          end --while @@Fetch_Status = 0

          close @curs1
          deallocate @curs1

       end --if(@recursive = 1)

   end -- if DB_NAME() != 'commondb'

   ---------------------------------------------------------------------------------------------------------------
   -- else if the stored procedure is executed within commondb, we try to get lockID for RDB database from commondb
   --------------------------------------------------------------------------------------------------------------
   else -- if DB_NAME() = 'commondb'
   begin

       if @Node_Type = 101
       begin
          set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
          ' select ' + rtrim(str(@lockSessionKey)) +','+ STR(@databaseID) +', 101, '+ str(@Extra_Key)+', rdbInfoKey, nodeType, '+str(@Extra_Key)+
           ' from [' + @dbName + '].dbo.rdbinfo where rdbInfoKey=' +str(@Node_Key) + ' and nodetype=' +str(@Node_Type)

          if @debug > 0
          begin
             set @msgText = 'Node type = 101; Query = '+@sql
             print @msgText
          end
          execute(@sql)
          set @extraKey = 0

       end --if @Node_Type = 101
       else
       begin
		   if @Node_Type = 102 or @Node_Type = 103
		   begin
			   set @sql = 'insert into [commondb].dbo.LockTreeMap (LockSessionKey, ParentKey, ParentType, ParentExposureKey, ChildKey, ChildType, ChildExposureKey) '+
			   ' select '+ rtrim(str(@lockSessionKey)) +',1, 101 , '+str(@Extra_Key)+', rdbInfoKey, nodeType, '+str(@Extra_Key)+
				' from [' + @dbName + '].dbo.rdbInfo where nodeType = ' +str(@Node_Type) + ' and rdbInfoKey =  ' +str(@Node_Key)
			  if @debug > 0
			  begin
				  set @msgText = 'Node type = ' + str(@Node_Type) + '; Query = '+@sql
				  print @msgText
			  end
			  execute(@sql)
			  set @extraKey = 0

		   end --@Node_Type = 102 or @Node_Type = 103

		   else
		   begin
				 set @msgText = 'Unknown Node Type '+str(@Node_Type)
				 execute absp_MessageEx @msgText
		   end
		end
      --select * from #TMP_TREEMAP

       set @sql = ' select distinct parentKey, parentType, parentExposureKey from [commondb].dbo.LockTreeMap where ChildKey = '+str(@Node_Key)+' and childType = '+str(@Node_Type) +' and LockSessionKey = ' + rtrim(str(@LockSessionKey))

      if @debug > 0
      begin
            set @msgText = 'Query = '+@sql
            print @msgText
      end

      if @recursive = 1
      begin

         -- execute('declare curs1 cursor global for '+@sql )
         set @sql = 'set @curs1 = cursor static for ' + @sql  + ' ; open @curs1'
         --print '@sql=' + @sql
         exec sp_executesql @sql, N'@curs1 cursor OUTPUT', @curs1 OUTPUT
         fetch next from @curs1 into @parentKey,@parentType,@extraKey

         while @@Fetch_Status = 0
         begin
             if @parentKey > 0
             begin
                set @sql1 = ' exec absp_CreateLockTreeMap '+rtrim(str(@LockSessionKey)) +', '+str(@parentKey)+', '+str(@parentType)+', '+str(@extraKey)+ ', 0, 1, ' + str(@databaseID) + ', ''' + @dbName + ''', 0'
                if @debug > 0
                begin
                   print '@sql1= ' + @sql1
                end
                execute(@sql1)

             end --if @parentKey > 0

            fetch next from @curs1 into @parentKey,@parentType,@extraKey

         end --while @@Fetch_Status = 0

         close @curs1
         deallocate @curs1

      end --if @recursive = 1

   end -- else if DB_NAME() = 'commondb'

  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_MessageEx @msg
   end

end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
	delete from [commondb].dbo.LockTreeMap where LockSessionKey = @LockSessionKey
end catch  