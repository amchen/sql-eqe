if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewProgramAdd') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewProgramAdd
end
 go

create procedure absp_TreeviewProgramAdd @rportKey int ,@newName char(120) ,@createDate char(120) ,@createBy int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new program by inserting a given program in PROGINFO, a map with the parent
rport in RPORTMAP and returns the new progKey.

Returns:	The Key of the new program.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The key of the rport to which the given program will be added. 
##PD  @newName ^^  The name of the program which is to be added. 
##PD  @createDate ^^  The date this program is created.
##PD  @createBy ^^  The user key of the user creating the program.

##RD  @lastKey ^^  The key of the new program.

*/
as
begin
 
   set nocount on
   
 -- this procedure will add a Program to an RPortfolio by first adding the
  -- new item itself and then adding the map entry
   declare @lastKey int
   declare @rport_Node_Type int
   declare @prog_Node_Type int
   declare @pCnt int
   declare @mt_Flag_Val char(1)
   execute @rport_Node_Type = absp_Util_GetRPortType @rportKey
   
   if(@rport_Node_Type = 3)
   begin
      set @prog_Node_Type = 7
      set @mt_Flag_Val = 'N'
   end
   else
   begin
      if(@rport_Node_Type = 23)
      begin
         set @prog_Node_Type = 27
         set @mt_Flag_Val = 'Y'
      end
   end

   insert into PROGINFO(LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,MT_FLAG) values(@newName,'NEW',@createDate,@createBy,0,@mt_Flag_Val)
  -- get the key of the new item
   set @lastKey = @@identity
  -- update the map
   insert into RPORTMAP(RPORT_KEY,CHILD_KEY,CHILD_TYPE) values(@rportKey,@lastKey,@prog_Node_Type)
   return @lastKey
end


