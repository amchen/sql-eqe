if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_IsFolderUsed') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_IsFolderUsed
end
 go

create procedure  absp_IsFolderUsed  @folderKey int  as
/*
##BD_BEGIN
&lt;font size ="3"&gt;
&lt;pre style="font-family: Lucida Console;" &gt;
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure is used to test if a folder is used or not, i.e. if the folder has any children or not 
and if it has child folders, they are used or not.

Returns:         A single value @retVal
1.  @retVal = 0, indicates the specified folder is not used.
2.  @retVal = 1, indicates that the folder is used.


====================================================================================================
&lt;/pre&gt;
&lt;/font&gt;
##BD_END

##PD  @folderKey ^^  The key of the folder node for which it needs to be identified if the folder is used or not.

##RD  @retVal ^^ Flag indicating whether the folder node is used or not.

*/
begin

   set nocount on
   declare @cnt int
   declare @retVal int
   declare @SWV_curs1_CK int
   declare @curs1 cursor
   set @retVal = 0
   
  -- first see if we have any non-folder children
   select   @cnt = count(*)  from FLDRMAP where FOLDER_KEY = @folderKey and CHILD_TYPE > 0
   if @cnt > 0
   begin
      set @retVal = 1 --yes, its in use
      return @retVal
   end
  -- if here, we may have folder children
   set @curs1 = cursor fast_forward for select CHILD_KEY from FLDRMAP where FOLDER_KEY = @folderKey
   open @curs1
   fetch next from @curs1 into @SWV_curs1_CK
   while @@fetch_status = 0
   begin
      execute @cnt = absp_IsFolderUsed @SWV_curs1_CK
      -- return true if used
      if @cnt > 0
      begin
         set @retVal = 1
         return @retVal
      end
      fetch next from @curs1 into @SWV_curs1_CK
   end
   close @curs1
   deallocate @curs1
  -- if we got here, we have no children that are not empty
   return @retVal
end




