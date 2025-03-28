if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetProgramType') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetProgramType
end
go

create procedure absp_Util_GetProgramType(@progKey int)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will check and return the Node type (regular or Multi-Treaty) for a given PROG_KEY.

Returns:       The Prog Type is returned - 7 if regular Program and 27 if multi-treaty Program.
====================================================================================================
</pre>
</font>
##BD_END

##PD @progKey ^^ The prog Key for which the node type is to be determined.

##RD @retNodeType ^^  The Prog Type is returned - 7 if regular Program and 27 if multi-treaty Program.
*/

as

begin

   set nocount on

   declare @retNodeType int
   declare @isMT char(1)

   set @retNodeType = 7

   select   @isMT = isNull(MT_FLAG,'N')  from PROGINFO where PROG_KEY = @progKey
   if(@isMT = 'Y')
   begin
      set @retNodeType = 27
   end
   else
   begin
      if(@isMT = 'N')
      begin
         set @retNodeType = 7
      end
   end
   --print '@retNodeType = ' + str(@retNodeType)
   return @retNodeType
end
