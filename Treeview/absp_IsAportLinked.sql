if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsAportLinked') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_IsAportLinked
end
 go

create procedure absp_IsAportLinked @aportKey int 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

    This procedure is used to test if an accumulation portfolio is paste-linked or not. 
        
Returns:         A single value @retVal
                     1.  <=0, indicates the specified aport node is paste-linked.
                     2.   >0, indicates that the aport node is paste-linked.
                

====================================================================================================
</pre>
</font>
##BD_END

##PD  aportKey ^^ The key of the aport node to be identified if the aport node is paste-linked or not.

##RD @retVal ^^ Flag indicating whether the aport is paste-linked or not.

*/
as
begin
   set nocount on
   declare @retVal int
   declare @cnt1 int 
   declare @cnt2 int

   set @retVal = 0
   
   select @cnt1 = COUNT(*) from FLDRMAP where CHILD_KEY = @aportKey and CHILD_TYPE = 1
   select @cnt2 = COUNT(*) from APORTMAP where CHILD_KEY = @aportKey and CHILD_TYPE = 1
           
   if @cnt1 + @cnt2 > 1
   begin
   	--yes, its in use
      	set @retVal = 1 
   end
           
   return @retVal
   
end