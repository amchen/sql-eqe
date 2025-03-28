if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewAPortfolioMove') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAPortfolioMove
end
 go
create procedure absp_TreeviewAPortfolioMove @aportKey int ,@currentNodeKey int ,@currentNodeType int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure moves an aport from one folder node to another.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @aportKey ^^  The key of the aport node that is to be moved.
##PD  @currentNodeKey ^^  The current parent key of the aport that is to be moved.  
##PD  @currentNodeType ^^  The current parent type of the aport that is to be moved. 
##PD  @newNodeKey ^^  The key of the parent node under which the given aport is to be moved. 
##PD  @newNodeType ^^  The type of the parent node under which the given aport is to be moved. 


*/
as
begin
set nocount on
   declare @mapTable char(10)
   declare @mapKey char(10)
   declare @sql varchar(max)
   if @currentNodeType = 0
   begin
      set @mapTable = 'FLDRMAP'
      set @mapKey = 'FOLDER_KEY'
   end
   else
   begin
      if @currentNodeType = 1
      begin
         set @mapTable = 'APORTMAP'
         set @mapKey = 'APORT_KEY'
      end
   end
   if @currentNodeType = @newNodeType
   begin
    -- this procedure will move an APortfolio to a new parent
    -- update the map
      set @sql = 'update '+@mapTable+' set '+@mapKey+' = '+str(@newNodeKey)+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@aportKey)+' and CHILD_TYPE = 1 '
      execute (@sql)
   end
   else
    begin
      set @sql = 'delete from '+@mapTable+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@aportKey)+' and CHILD_TYPE = 1 '
      execute (@sql)
      if @newNodeType = 0
      begin
         set @mapTable = 'FLDRMAP'
      end
      else
      begin
         if @newNodeType = 1
         begin
            set @mapTable = 'APORTMAP'
         end
      end
      set @sql = 'insert into '+@mapTable+'  values ( '+str(@newNodeKey)+' , '+str(@aportKey)+' , 1) '
      execute (@sql)
   end
end


