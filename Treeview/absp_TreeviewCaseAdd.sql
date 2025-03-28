if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewCaseAdd') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewCaseAdd
end

go

create  procedure absp_TreeviewCaseAdd @progKey int ,@caseNodeType int ,@newName char(120) ,@createDate char(120) ,@createBy int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new case by inserting a given case in the CASEINFO table and returns the 
new caseKey.

Returns:	The Key of the new case.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key of the program to which the given case will be added. 
##PD  @caseNodeType ^^  The case Node Type - 10 for single, 30 for Multi-treaty cases. 
##PD  @newName ^^  The name for the given treaty case.
##PD  @createDate ^^  The date this treaty case is created.
##PD  @createBy ^^  The user key of the user creating the treaty case.

##RD  @lastKey ^^  The key of the new case.

*/
as
begin

   set nocount on
   
  -- this procedure will add a Case to a Program by adding the new item itself 
   declare @lastKey int
   declare @mt_flag_parm char(1)
  -- Fixed code to handle Multi-Treaty Node
   if(@caseNodeType = 10)
   begin
      set @mt_flag_parm = 'N'
   end
   else
   begin
      if(@caseNodeType = 30)
      begin
         set @mt_flag_parm = 'Y'
      end
   end
  -- set status = 'NEW'
   insert into caseinfo(PROG_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,MT_FLAG) values(@progKey,@newName,'NEW',@createDate,@createBy,@mt_flag_parm)
  -- get the key of the new item
   set @lastKey = @@identity
   return @lastKey
end





