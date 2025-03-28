if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsAPortUsed') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_IsAPortUsed
end
 go

create procedure absp_IsAPortUsed @aportKey int 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure is used to test if an accumulation portfolio is used or not, i.e. if the aport node
has any children or not. 

Returns:         A single value @retVal
1.  0, indicates the specified aport node is not used, i.e. it has no children.
2.  1, indicates that the aport node is used.


====================================================================================================
</pre>
</font>
##BD_END

##PD  @aportKey ^^ The key of the aport node for which it needs to be identified if the aport node is used or not.

##RD  @retVal ^^ Flag indicating whether the aport is used or not.

*/
as
begin

   set nocount on
   
   declare @retVal int
   declare @cnt int
   set @retVal = 0
  -- first see if we have any non-folder children
   select  @cnt = count(*)  from APORTMAP where APORT_KEY = @aportKey and CHILD_TYPE > 0
   --yes, its in use
   if @cnt > 0
   begin
      set @retVal = 1
   end
  -- if we got here, we have no children 
   return @retVal
end



