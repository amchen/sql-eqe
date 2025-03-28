if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewRPortfolioLink') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewRPortfolioLink
end
 go
create procedure absp_TreeviewRPortfolioLink @rportKey int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure paste links a given rport residing under a folder/aport to another given folder/aport.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The key of the rport which is to be linked.
##PD  @newNodeKey ^^  The key of the parent node to which the given rport is to be linked.  
##PD  @newNodeType ^^  The type of the parent node to which the given rport is to be linked.  

*/
as
begin

   set nocount on
   
   declare @cntInstance int
   declare @rport_Node_Type int
   execute @rport_Node_Type  = absp_Util_GetRPortType @rportKey
  
    -- first we need to see if this is the only instance
    
    -- first we need to see if this is the only instance
   if @newNodeType = 0
   begin
      select  @cntInstance = count(*)  from FLDRMAP where
      FOLDER_KEY = @newNodeKey and CHILD_KEY = @rportKey and CHILD_TYPE = @rport_Node_Type
      if @cntInstance = 0
      begin
         insert into FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@rportKey,@rport_Node_Type)
      end
   end
   else
   begin
      if @newNodeType = 1
      begin
         select  @cntInstance = count(*)  from APORTMAP where
         APORT_KEY = @newNodeKey and CHILD_KEY = @rportKey and CHILD_TYPE = @rport_Node_Type
         if @cntInstance = 0
         begin
            insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@newNodeKey,@rportKey,@rport_Node_Type)
         end
      end
   end
end


