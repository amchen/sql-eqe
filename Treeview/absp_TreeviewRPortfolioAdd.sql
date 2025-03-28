if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewRPortfolioAdd') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewRPortfolioAdd
end
 go

create procedure absp_TreeviewRPortfolioAdd @parentNodeKey int ,@parentNodeType int ,@rportNodeType int ,@newName char(120) ,@createBy int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new rport by inserting a record in RPRTINFO,a map with the parent folder/aport 
in FLDRMAP/APORTMAP and returns the new rportKey.

Returns:	The key of the inserted rport.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey ^^  The key of the parent node to which the rport will be added. 
##PD  @parentNodeType ^^  The type of the parent node (folder/aport) to which the rport will be added. 
##PD  @rportNodeType ^^  The type of rport (Single/Multi-treaty). 
##PD  @newName ^^  The name of the new rport.
##PD  @createBy ^^  The user key of the user creating the rport.

##RD  @lastKey ^^  The key of the new rport.

*/
as
begin
 
   set nocount on
   
 -- this procedure will add an RPortfolio to its parent by first adding the
  -- new item itself and then adding the map entry
   declare @lastKey int
   declare @createDate char(14)
  -- now date + time
   exec absp_Util_GetDateString @createDate output,'yyyymmddhhnnss'
  -- ref_portkey set to 0 (self) to start
   insert into RPRTINFO(LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,REF_RPTKEY) values(@newName,'NEW',@createDate,@createBy,0,0)
  -- get the key of the new item
   set @lastKey = @@identity
  -- update the map
   if @parentNodeType = 0
   begin
      insert into FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@parentNodeKey,@lastKey,@rportNodeType)
   end
   else
   begin
      if @parentNodeType = 1
      begin
         insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@parentNodeKey,@lastKey,@rportNodeType)
      end
   end
   return @lastKey
end


