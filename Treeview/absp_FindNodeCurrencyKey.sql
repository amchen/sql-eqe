if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNodeCurrencyKey') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindNodeCurrencyKey
end
 go
create procedure absp_FindNodeCurrencyKey @nodeKey int,@nodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the node key of the parent(may not be the immediate parent, in case the concerned node is deep down the 
the treeview) currency folder for a given node via the parentKey return value.


Returns:       A single value @parentKey
1. @parentKey = -1, a parent currency node is not found
2. @parentKey = any positive number, then a parent currency folder node is found and the 
parentKey value is the folder_key of the currency folder.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node for which the parent currency folder needs to be identified. 
##PD  @nodeType ^^  The type of the node for which the parent currency folder needs to be identified.

##RD @parentKey ^^ The the folder_key of the parent currency folder.

*/
as
begin

   set nocount on
   
   declare @lastKey int
   declare @lastType int
   declare @lastCode int
   declare @parentKey int
   declare @parentType int
  --message '------------------------';
  -- message 'in absp_FindNodeCurrencyKey , nodeKey, nodeType  = ', nodeKey , nodeType;
   set @lastKey = @nodeKey
   set @lastType = @nodeType
   set @lastCode = 1
  -- a currency node IS the top level
   if @lastType = 12
   begin
      set @parentKey = 0
      return @parentKey
   end
   while @lastCode = 1
   begin
      execute @lastCode = absp_FindNodeParent @parentKey output,@parentType output,@lastKey,@lastType
    --message 'in absp_FindNodeCurrencyKey , @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
      set @lastKey = @parentKey
      set @lastType = @parentType
      if @lastCode = 2
      begin
      --select  CURRSK_KEY into @lastCode from FLDRINFO where FOLDER_KEY = @parentKey;
      --message 'your currkey = ', @lastCode;
      --return @lastCode;
         return @parentKey
      end
   end
   set @parentKey = -1
   return @parentKey
end




