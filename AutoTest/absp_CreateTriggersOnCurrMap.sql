if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateTriggersOnCurrMap') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateTriggersOnCurrMap
end

go

create procedure absp_CreateTriggersOnCurrMap AS
begin

   set nocount on
   
   if exists(select 1 from sysobjects where name = 'On_delete_of_APORTMAP_delete_CURRMAP' and type = 'TR')
   begin
      drop trigger On_delete_of_APORTMAP_delete_CURRMAP
   end
   execute('create trigger On_delete_of_APORTMAP_delete_CURRMAP on APORTMAP
   after delete 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired on the deletion of a record in the APORTMAP table and it deletes the  
  CURRMAP record for the corresponding child pport/rport only if no map entry exists for them in
  FLDRMAP and APORTMAP.


  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
      declare @SWV_OLD_CHILD_KEY int
      declare @SWV_OLD_CHILD_TYPE smallint
      declare @SWV_Cursor_For_OLD cursor
      set @SWV_Cursor_For_OLD = cursor  for select CHILD_KEY, CHILD_TYPE from DELETED
      open @SWV_Cursor_For_OLD
      fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      while @@fetch_status = 0
      begin
         declare @childKey int
         declare @childType int
         declare @aportCount int
         declare @fldrCount int
         declare @sql varchar(max)
         execute absp_MessageEx ''TRIGGER delete_of_CURRMAP_for_APORTMAP starts''
         set @childKey = @SWV_OLD_CHILD_KEY
         set @childType = @SWV_OLD_CHILD_TYPE
    --message ''@childKey = '', @childKey, '', @childType = '',@childType;
    -- Only continue if the old FLDRMAP record was for either Primary (2) or Reinsurance portfolios (3)
     -- not allowed commit;
         if @childType = 2 or @childType = 3
         begin
      -- only delete if this is the last reference to the @childKey in both FLDRMAP and APORTMAP
            select   @fldrCount = count(*)  from fldrmap where CHILD_KEY = @childKey and CHILD_TYPE = @childType
            select   @aportCount = count(*)  from APORTMAP where CHILD_KEY = @childKey and CHILD_TYPE = @childType
      --message ''@fldrCount = '', @fldrCount, '', @aportCount = '',@aportCount;
            if @fldrCount+@aportCount = 0
            begin
        -- delete the record from CURRMAP
               set @sql = ''delete from CURRMAP where CHILD_KEY = ''+rtrim(ltrim(str(@childKey)))+'' and CHILD_TYPE = ''+rtrim(ltrim(str(@childType)))
               PRINT @sql
               execute(@sql)
            end
         end
         fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      end
      close @SWV_Cursor_For_OLD')
   if exists(select 1 from sysobjects where name = 'On_delete_of_FLDRMAP_delete_CURRMAP' and type = 'TR')
   begin
      drop trigger On_delete_of_FLDRMAP_delete_CURRMAP
   end
   execute('create trigger On_delete_of_FLDRMAP_delete_CURRMAP on fldrmap
   after delete 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired on the deletion of a record in the FLDRMAP table and it deletes the  
  CURRMAP record for the corresponding child pport/rport only if no map entry exists for them in
  FLDRMAP and APORTMAP. 


  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
      declare @SWV_OLD_CHILD_KEY int
      declare @SWV_OLD_CHILD_TYPE smallint
      declare @SWV_Cursor_For_OLD cursor
      set @SWV_Cursor_For_OLD = cursor  for select CHILD_KEY, CHILD_TYPE from DELETED
      open @SWV_Cursor_For_OLD
      fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      while @@fetch_status = 0
      begin
         declare @childKey int
         declare @childType int
         declare @aportCount int
         declare @fldrCount int
         declare @sql varchar(max)
         execute absp_MessageEx ''TRIGGER delete_of_CURRMAP_for_FLDRMAP starts''
         set @childKey = @SWV_OLD_CHILD_KEY
         set @childType = @SWV_OLD_CHILD_TYPE
    --message ''@childKey = '', @childKey, '', @childType = '',@childType;
    -- Only continue if the old FLDRMAP record was for either Primary (2) or Reinsurance portfolios (3)
     -- not allowed commit;
         if @childType = 2 or @childType = 3
         begin
      -- only delete if this is the last reference to the @childKey in both FLDRMAP and APORTMAP
            select   @fldrCount = count(*)  from fldrmap where CHILD_KEY = @childKey and CHILD_TYPE = @childType
            select   @aportCount = count(*)  from APORTMAP where CHILD_KEY = @childKey and CHILD_TYPE = @childType
      --message ''@fldrCount = '', @fldrCount, '', @aportCount = '',@aportCount;
            if @fldrCount+@aportCount = 0
            begin
        -- delete the record from CURRMAP
               set @sql = ''delete from CURRMAP where CHILD_KEY = ''+rtrim(ltrim(str(@childKey)))+'' and CHILD_TYPE = ''+rtrim(ltrim(str(@childType)))
               print @sql
               execute(@sql)
            end
         end
         fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      end
      close @SWV_Cursor_For_OLD')
   if exists(select 1 from sysobjects where name = 'On_insert_of_APORTMAP_insert_CURRMAP' and type = 'TR')
   begin
      drop trigger On_insert_of_APORTMAP_insert_CURRMAP
   end
   execute('create trigger On_insert_of_APORTMAP_insert_CURRMAP on APORTMAP
   after insert 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired on the insertion of a record in the APORTMAP table and it inserts a record
  into the CURRMAP table to map the inserted child node with the corresponding parent currency folder. 


  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
         declare @New_ChildKey int
         declare @New_ChildType smallint
         declare @cursNew cursor
         
         set @cursNew = cursor  for select CHILD_KEY, CHILD_TYPE from INSERTED
         
         open @cursNew
         fetch next from @cursNew into @New_ChildKey,@New_ChildType
         while @@fetch_status = 0
         begin
            declare @currKey int
            declare @sql varchar(max)
            declare @childKey int
            declare @childType int
            execute absp_messageEx ''TRIGGER insert_of_CURRMAP_for_APORTMAP starts''
            set @childKey = @New_ChildKey
            set @childType = @New_ChildType
            if @childType = 2 or @childType = 3
            begin 
               execute @currKey = absp_FindNodeCurrencyKey @childKey,@childType
               if not exists (select 1 from currmap where FOLDER_KEY = @currKey and CHILD_KEY= @childKey and CHILD_TYPE= @childTYPE)
               begin
      			set @sql = ''insert into CURRMAP (FOLDER_KEY, CHILD_KEY, CHILD_TYPE) ''+''values ( ''+rtrim(ltrim(str(@currKey)))+'', ''+rtrim(ltrim(str(@childKey)))+'', ''+rtrim(ltrim(str(@childType)))+'' )''
      			print @sql
      			exec (@sql)
               end    
            end
            fetch next from @cursNew into @New_ChildKey,@New_ChildType
         end
         close @cursNew
         deallocate  @cursNew
  ')
   if exists(select 1 from sysobjects where name = 'On_insert_of_FLDRMAP_insert_CURRMAP' and type = 'TR')
   begin
      drop trigger On_insert_of_FLDRMAP_insert_CURRMAP
   end
   execute('create trigger On_insert_of_FLDRMAP_insert_CURRMAP on fldrmap
   after insert 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired on the insertion of a record in the FLDRMAP table and it inserts a record
  into the CURRMAP table to map the inserted child node with the corresponding parent currency folder. . 


  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
         declare @new_Child_Key int
         declare @new_Child_Type smallint
         declare @curs1 cursor
         set @curs1 = cursor  for select CHILD_KEY, CHILD_TYPE from INSERTED
         open @curs1
         fetch next from @curs1 into @new_Child_Key,@new_Child_Type
         while @@fetch_status = 0
         begin
            declare @currKey int
            declare @sql varchar(max)
            declare @childKey int
            declare @childType int
            execute absp_messageEx ''TRIGGER insert_of_CURRMAP_for_FLDRMAP starts''
            set @childKey = @new_Child_Key
            set @childType = @new_Child_Type
            if @childType = 2 or @childType = 3
            begin
               execute @currKey = absp_FindNodeCurrencyKey @childKey,@childType
               if not exists (select 1 from currmap where FOLDER_KEY = @currKey and CHILD_KEY= @childKey and CHILD_TYPE= @childTYPE)
               begin
      			set @sql = ''insert into CURRMAP (FOLDER_KEY, CHILD_KEY, CHILD_TYPE) ''+''values ( ''+rtrim(ltrim(str(@currKey)))+'', ''+rtrim(ltrim(str(@childKey)))+'', ''+rtrim(ltrim(str(@childType)))+'' )''
      			print @sql
      			exec (@sql)
               end
            end
            fetch next from @curs1 into @new_Child_Key,@new_Child_Type
         end
         close @curs1
         deallocate @curs1
  ')
   if exists(select 1 from sysobjects where name = 'On_update_of_APORTMAP_update_CURRMAP' and type = 'TR')
   begin
      drop trigger On_update_of_APORTMAP_update_CURRMAP
   end
   execute('create trigger On_update_of_APORTMAP_update_CURRMAP on APORTMAP
   after update 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired when the child nodes of one accumulation portfolio is moved to another
  accumulation portfolio. The new currency folder key is updated in the currency mapping table
  (CurrMap) 


  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
      declare @SWV_OLD_CHILD_KEY int
      declare @SWV_OLD_CHILD_TYPE smallint
      declare @SWV_Cursor_For_OLD cursor
      declare @SWV_NEW_CHILD_KEY int
      declare @SWV_NEW_CHILD_TYPE smallint
      declare @SWV_Cursor_For_NEW cursor
      SET @SWV_Cursor_For_OLD = cursor  for select CHILD_KEY, CHILD_TYPE from DELETED
      open @SWV_Cursor_For_OLD
      set @SWV_Cursor_For_NEW = cursor  for select CHILD_KEY, CHILD_TYPE from INSERTED
      open @SWV_Cursor_For_NEW
      fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      fetch next from @SWV_Cursor_For_NEW into @SWV_NEW_CHILD_KEY,@SWV_NEW_CHILD_TYPE
      while @@fetch_status = 0
      begin
         declare @childKeyOld int
         declare @childTypeOld int
         declare @currKeyOld int
         declare @childKeyNew int
         declare @childTypeNew int
         declare @currKeyNew int
         declare @sql varchar(max)
         execute absp_MessageEx ''TRIGGER update_of_CURRMAP_for_APORTMAP starts''
         set @childKeyNew = @SWV_NEW_CHILD_KEY
         set @childTypeNew = @SWV_NEW_CHILD_TYPE
         set @childKeyOld = @SWV_OLD_CHILD_KEY
         set @childTypeOld = @SWV_OLD_CHILD_TYPE
         print ''@childKeyOld = ''
         print @childKeyOld
         print '', @childTypeOld = ''
         print @childTypeOld
         print ''@childKeyNew = ''
         print @childKeyNew
         print '', @childTypeNew = ''
         print @childTypeNew
    -- Only continue if the old APORTMAP record was for either Primary (2) or Reinsurance portfolios (3)
    -- and the old type and key = the new type and key
         if(@childTypeOld = 2 or @childTypeOld = 3) and
         @childKeyOld = @childKeyNew and
         @childTypeOld = @childTypeNew
         begin
      -- determine the new currency folder key.
            execute @currKeyNew = absp_FindNodeCurrencyKey @childKeyNew,@childTypeNew
            set @sql = ''update CURRMAP set FOLDER_KEY = ''+rtrim(ltrim(str(@currKeyNew)))+'' where CHILD_KEY  = ''+rtrim(ltrim(str(@childKeyOld)))+''   and CHILD_TYPE = ''+rtrim(ltrim(str(@childTypeOld)))
            print @sql
            execute(@sql)
         end
         fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
         fetch next from @SWV_Cursor_For_NEW into @SWV_NEW_CHILD_KEY,@SWV_NEW_CHILD_TYPE
      end
      close @SWV_Cursor_For_OLD
      close @SWV_Cursor_For_NEW -- not allowed commit;
  ')
   if exists(select 1 from sysobjects where name = 'On_update_of_FLDRMAP_update_CURRMAP' and type = 'TR')
   begin
      drop trigger On_update_of_FLDRMAP_update_CURRMAP
   end
   execute('create trigger On_update_of_FLDRMAP_update_CURRMAP on fldrmap
   after update 
  /*
  ##BD_BEGIN
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    ASA
  Purpose:

  This trigger gets fired on the updation of a record in the FLDRMAP table and it updates the  
  CURRMAP and sets the FOLDER_KEY to the new FOLDER_KEY matching CHILD_KEY and CHILD_TYPE thus
  creating the reference and maintain the CURRMAP when FLDRMAP is changed. 

  Returns:       It returns nothing.                  
  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  */
      AS
    /*
    SDG__00013513 -- create triggers to maintain CURRMAP when FLDRMAP or APORTMAP is changed
    */
      declare @SWV_OLD_CHILD_KEY int
      declare @SWV_OLD_CHILD_TYPE smallint
      declare @SWV_Cursor_For_OLD cursor
      declare @SWV_NEW_CHILD_KEY int
      declare @SWV_NEW_CHILD_TYPE smallint
      declare @SWV_Cursor_For_NEW cursor
      set @SWV_Cursor_For_OLD = cursor  for select CHILD_KEY, CHILD_TYPE from DELETED
      open @SWV_Cursor_For_OLD
      set @SWV_Cursor_For_NEW = cursor  for select CHILD_KEY, CHILD_TYPE from INSERTED
      open @SWV_Cursor_For_NEW
      fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
      fetch next from @SWV_Cursor_For_NEW into @SWV_NEW_CHILD_KEY,@SWV_NEW_CHILD_TYPE
      while @@fetch_status = 0
      begin
         declare @childKeyOld int
         declare @childTypeOld int
         declare @currKeyOld int
         declare @childKeyNew int
         declare @childTypeNew int
         declare @currKeyNew int
         declare @sql varchar(max)
         execute absp_MessageEx ''TRIGGER update_of_CURRMAP_for_FLDRMAP starts''
         set @childKeyNew = @SWV_NEW_CHILD_KEY
         set @childTypeNew = @SWV_NEW_CHILD_TYPE
         set @childKeyOld = @SWV_OLD_CHILD_KEY
         set @childTypeOld = @SWV_OLD_CHILD_TYPE
         print ''@childKeyOld = ''
         print @childKeyOld
         print '', @childTypeOld = ''
         print @childTypeOld
         print ''@childKeyNew = ''
         print @childKeyNew
         print '', @childTypeNew = ''
         print @childTypeNew
    -- Only continue if the old FLDRMAP record was for either Primary (2) or Reinsurance portfolios (3)
    -- and the old type and key = the new type and key
         if(@childTypeOld = 2 or @childTypeOld = 3) and
         @childKeyOld = @childKeyNew and
         @childTypeOld = @childTypeNew
         begin
      -- determine the new currency folder key.
            execute @currKeyNew = absp_FindNodeCurrencyKey @childKeyNew,@childTypeNew
            set @sql = ''update CURRMAP set FOLDER_KEY = ''+rtrim(ltrim(str(@currKeyNew)))+'' where CHILD_KEY  = ''+rtrim(ltrim(str(@childKeyOld)))+''   and CHILD_TYPE = ''+rtrim(ltrim(str(@childTypeOld)))
            print @sql
            execute(@sql)
         end
         fetch next from @SWV_Cursor_For_OLD into @SWV_OLD_CHILD_KEY,@SWV_OLD_CHILD_TYPE
         fetch next from @SWV_Cursor_For_NEW into @SWV_NEW_CHILD_KEY,@SWV_NEW_CHILD_TYPE
      end
      close @SWV_Cursor_For_OLD
      close @SWV_Cursor_For_NEW -- not allowed commit;
  ')
end


