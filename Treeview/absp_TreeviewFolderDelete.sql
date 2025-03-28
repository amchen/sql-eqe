if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewFolderDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewFolderDelete
end
 go

create procedure  absp_TreeviewFolderDelete  @currentParentKey int ,@folderKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure:
- performs a cascading delete for the given folder node and its children if the folder is the only instance
under its parent
- removes the folder entry from the folder map if it is paste-linked (the feature is currently unused)    


Returns:       It returns nothing. It uses the DELETE statement to remove the given folder node and its children from the database.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @currentParentKey ^^  The key of the parent folder node for which the folder is to be deleted.
##PD  @folderKey ^^ The key of the folder node that is to be deleted
*/
as

begin
   set nocount on

   declare @cntFolderkey int
   declare @curs1_ChildKey int
   declare @curs1_ChildType smallint
   declare @curs1 cursor
  -- first we need to see if this is the only instance
   select   @cntFolderkey = COUNT(*)  from FLDRMAP where CHILD_KEY = @folderKey and CHILD_TYPE = 0
   if @cntFolderkey = 1
   begin
    -- First delete all the children under this folder
      set @curs1 = cursor fast_forward for select CHILD_KEY,CHILD_TYPE from FLDRMAP where FOLDER_KEY = @folderKey
      open @curs1
      fetch next from @curs1 into @curs1_ChildKey,@curs1_ChildType
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeDelete @folderKey,0,@curs1_ChildKey,@curs1_ChildType
         fetch next from @curs1 into @curs1_ChildKey,@curs1_ChildType
      end
      close @curs1
      deallocate @curs1
      -- Now Remove the map entries from FLDRMAP
      delete from FLDRMAP where FOLDER_KEY = @folderKey
      delete from FLDRMAP where CHILD_KEY = @folderKey and CHILD_TYPE = 0
      -- Now Remove the FLDRINFO entry
      delete from FLDRINFO where FOLDER_KEY = @folderKey
   end
   else
   begin
    -- if> 1 then just delete from map
      delete from FLDRMAP where FOLDER_KEY = @currentParentKey and CHILD_KEY = @folderKey and CHILD_TYPE = 0
   end

end
