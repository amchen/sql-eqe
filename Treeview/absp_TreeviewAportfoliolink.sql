if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewAportfolioLink') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAportfoliolink
end
 go
create procedure absp_TreeviewAPortfolioLink @aportKey int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure paste links a given aport residing under a folder to another given folder.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @aportKey ^^  The key of the aport which is to be linked.
##PD  @newNodeKey ^^  The key of the parent node to which the given aport is to be linked.  
##PD  @newNodeType ^^  The type of the parent node to which the given aport is to be linked.  

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
      FOLDER_KEY = @newNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
      if @cntInstance = 0
      begin
         insert into FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@aportKey,1)
      end
   end
   else
   begin
      if @newNodeType = 1
      begin
         select  @cntInstance = count(*)  from APORTMAP where
         APORT_KEY = @newNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
         if @cntInstance = 0
         begin
            insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@aportKey,1)
         end
      end
   end
end

GO

