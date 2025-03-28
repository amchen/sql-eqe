if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewPPortfolioLink') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewPPortfolioLink
end
 go
create procedure absp_TreeviewPPortfolioLink @pportKey int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure paste links a given pport residing under a folder/aport to another given folder/aport.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @pportKey ^^  The key of the pport which is to be linked.
##PD  @newNodeKey ^^  The key of the parent node to which the given pport is to be linked.  
##PD  @newNodeType ^^  The type of the parent node to which the given pport is to be linked.  

*/
as
begin
 
   set nocount on
   
  declare @cntInstance int
  
    -- first we need to see if this is the only instance
    
    -- first we need to see if this is the only instance
   if @newNodeType = 0
   begin
      select  @cntInstance = count(*)  from FLDRMAP where
      FOLDER_KEY = @newNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
      if @cntInstance = 0
      begin
         insert into FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@pportKey,2)
      end
   end
   else
   begin
      if @newNodeType = 1
      begin
         select  @cntInstance = count(*)  from APORTMAP where
         APORT_KEY = @newNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
         if @cntInstance = 0
         begin
            insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@pportKey,2)
         end
      end
   end
end

GO


