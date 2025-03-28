if exists(select * from sysobjects where id = object_id(N'absp_Util_GetRPortType') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetRPortType
end
go

create procedure -------------------------------------------------------------------------------------------------
absp_Util_GetRPortType (@rportKey int)

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will check and return the Node type (regular or Multi-Treaty) for a given RPORT_KEY.

Returns:       It returns a single value in @rc
@rc = 3  if regular Reinsurance Portfolio 
@rc = 23 if multi-treaty Reinsurance Portfolio.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The rport key.

##RD  @ret_NodeType ^^ 3  if regular Reinsurance Portfolio and 23 if multi-treaty Reinsurance Portfolio.Output parameter
*/
   as
begin

   set nocount on
   
   declare @ret_NodeType int
   declare @isMT char(1)
   select   @isMT = isNull(MT_FLAG,'N')  from RPRTINFO where RPORT_KEY = @rportKey
   if(@isMT = 'Y')
   begin
      set @ret_NodeType = 23
   end
   else
   begin
      if(@isMT = 'N')
      begin
         set @ret_NodeType = 3
      end
   end
   return @ret_NodeType

end







