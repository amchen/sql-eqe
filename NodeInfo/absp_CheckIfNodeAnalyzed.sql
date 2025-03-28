if exists(select * from SYSOBJECTS WHERE id = object_id(N'absp_CheckIfNodeAnalyzed') and OBJECTPROPERTY(Id,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckIfNodeAnalyzed
end
 go
 
create procedure absp_CheckIfNodeAnalyzed @nodeKey int ,@nodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks if a given node has been analyzed. It returns 0 if no analysis has been done 
for the node else >0.


Returns:       It returns 0 if no analysis has been done for the given node else >0.

====================================================================================================
</pre>
</font>
##BD_END

##PD  nodeKey ^^  The key of the node for which the procedure checks if analysis has been done 
##PD  nodeType ^^  The type of node for which the procedure checks if analysis has been done.

##RD @cnt ^^  Returns 0 if no analysis has been done for the given node else >0.
*/
as
begin

   set nocount on
   
  --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --FPort = 4;
  --Acct = 5;
  --Cert = 6;
  --Prog = 7;
  --Lport = 8;
  -- call the correct lister based on the child type
   declare @cnt int
  --set @hasResult=0;
   if @nodeType = 1
   begin
      select  @cnt = count(*)  from ReportsDone where NodeKey = @nodeKey and NodeType=1
   end
   else
   begin
      if @nodeType = 2
      begin
         select  @cnt = count(*)  from ReportsDone where NodeKey = @nodeKey and NodeType=2
      end
      else
      begin
         if @nodeType = 3
         begin
            select  @cnt = count(*)  from ReportsDone where NodeKey = @nodeKey and NodeType=3
         end
         else
         begin
            if @nodeType = 23
            begin
               select  @cnt = count(*)  from ReportsDone where NodeKey = @nodeKey and NodeType=23
            end
         end
      end
   end
   return @cnt
end




