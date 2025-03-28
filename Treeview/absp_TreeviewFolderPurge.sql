if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewFolderPurge') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewFolderPurge
end
 go

create procedure  absp_TreeviewFolderPurge @currentParentKey int ,@folderKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure performs a cascading delete for the given folder node and its children.It will
also delete the user notes and folder map entries for the given folder.


Returns:       It returns nothing. It uses the DELETE statement to remove the given folder node and its children from the database.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @currentParentKey ^^  The key of the parent node for which the folder is to be deleted.
##PD  @folderKey ^^ The key of the folder node that is to be deleted

*/
as


begin
   set nocount on
   declare @curs1_ChildKey int
   declare @curs1_ChildType smallint
   
   if @folderKey = 0
   begin
        --deallocate curs1
	return
   end
   
  -- delete all children
  
   declare curs1 cursor fast_forward local for select  CHILD_KEY,CHILD_TYPE from FLDRMAP where   FOLDER_KEY = @folderKey
   open curs1
   fetch next from curs1 into @curs1_ChildKey,@curs1_ChildType
   while @@fetch_status = 0
   begin
      execute absp_TreeviewGenericNodeDelete @folderKey,0,@curs1_ChildKey,@curs1_ChildType
      fetch next from curs1 into @curs1_ChildKey,@curs1_ChildType
   end
   close curs1
   deallocate curs1
  -- now get rid of notes
   execute absp_UserNotesPurge 7,@folderKey
  -- delete the map entry
   delete from FLDRMAP where FOLDER_KEY = @currentParentKey and CHILD_KEY = @folderKey and CHILD_TYPE = 0
  -- delete the folder
   delete from FLDRINFO where FOLDER_KEY = @folderKey
 
end



