if exists(select * from SYSOBJECTS where id = object_id(N'absp_HasChildLockUnderNode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_HasChildLockUnderNode
end
go 
 
create procedure absp_HasChildLockUnderNode 
@keyTypePairList varchar(255) = '',
@destNodeKey int = -1,
@destNodeType int = 0 

/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

This procedure returns the parent node key if any of the given child node pairs reside under it else it returns an error code.

Returns:      The single value @retVal:-
1. @retVal=0, the parent node specified is not the actual parent of the specified child node.
2. @retVal=-1, destinationNodeKey<=0
3. @retVal=-2, keyTypePairList=''
4. @retVal=-3, The string keyTypePairList does not contain the substring '|'
5. @retVal=-4, Improper child key/type pair  
6. @retVal>0, destination node matches with the parent  

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @keyTypePairList ^^ A string containing the pair of parent node key/type and child node key/type
##PD  @destNodeKey ^^ The key of the destination node
##PD  @destNodeType ^^ The type of the destination node

##RD @retVal ^^ The parent node key is child node is found else an error code.

*/
as
begin

   set nocount on
   
  /*    The point of this procedure is to check if a child in keyTypePairString list is locked under a node

  */
   declare @keyTypePair char(50)
   declare @keyStr char(20)
   declare @typeStr char(20)
   declare @sql nvarchar(4000)
   declare @key int
   declare @type int
   declare @retKey int
   declare @i1 int
   declare @i2 int
   declare @j int
   declare @retVal int
   print GetDate()
   print ' inside absp_HasChildLockUnderNode  '
   if(@destNodeKey <= 0)
   begin /* should not happen */
    -- return -1; --'foldeKey &lt;= 0 ';
      set @retVal = -1
      return @retVal
   end
   if(len(@keyTypePairList) <= 0 or @keyTypePairList = '')
   begin
    -- return -2; /*'child key-type pair List is empty ' should not happen; */
      set @retVal = -2
      return @retVal
   end
   print GetDate()
   print ' inside absp_HasChildLockUnderNode, keyTypePairList = '+@keyTypePairList
  -- Find the last trailing bar
   set @i2 = charindex('|',@keyTypePairList,1)
   if @i2 = 0
   begin
    -- return -3; /*'cannot proceed without valid child key-type pair String';*/
      set @retVal = -3
      return @retVal
   end
   set @i1 = 1
   while @i2 > 0
   begin
    --	get the keyType Pair 
      set @keyTypePair = substring(@keyTypePairList,@i1,@i2 -@i1)
    --	find the key
      set @j = charindex(',',@keyTypePair)
      if @j = 0
      begin
      -- return -4; /*' cannot proceed without valid child key in the keyType pair String';*/
         set @retVal = -4
         return @retVal
      end
      print GetDate()
      print ' inside absp_HasChildLockUnderNode, @keyTypePair = '+@keyTypePair
      set @sql = 'EXEC @retKey =   absp_isChildofNode '+@keyTypePair+','+str(@destNodeKey)+','+str(@destNodeType)+' '

      print GetDate()
      print ' inside absp_HasChildLockUnderNode, @sql = '+@sql
      exec sp_executesql @sql, N'@retKey int output', @retKey output
      print GetDate()
      print ' inside absp_HasChildLockUnderNode, destNodeKey = '+str(@destNodeKey)
      print GetDate()
      print ' inside absp_HasChildLockUnderNode, @retKey = '+str(@retKey)
    --	if the locked child is under this node , return the destNodeKey 
      if(@retKey = @destNodeKey)
      begin
      --return destNodeKey;
         set @retVal = @destNodeKey
         return @retVal
      end
      set @i1 = @i2+1
      if(@i1 > len(@keyTypePairList))
      begin
         set @i2 = 0
      end
      else
      begin
         set @i2 = charindex('|',@keyTypePairList,@i1)
      end
   end
  --	message now(), ' inside absp_HasChildLockUnderNode, @i ... = ' + str(@i); 
 
   set @retVal = 0
   return @retVal
end




