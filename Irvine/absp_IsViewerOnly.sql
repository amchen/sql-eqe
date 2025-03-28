if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsViewerOnly') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_IsViewerOnly
end
 go

create procedure absp_IsViewerOnly @seqPlanerKey int 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks if an analysis engine is used by a planner sequence or not.It is used in 
case of "viewer only" mode.

Returns:       A value @retVal
1. @retVal = 1, when an analysis engine is used by a planner sequence 
2. @retVal = 0, when an analysis engine is not used by a planner sequence                
====================================================================================================
</pre>
</font>
##BD_END

##PD  @seqPlanerKey ^^  The key of the planned sequence which is checked if it uses an anlysis engine. 

##RD  @retVal ^^  A return value, signifying whether an analysis engine is used by the sequence planner or not.

*/
as
begin

   set nocount on
   
   declare @cnt int
   declare @retVal int
  --message 'sequence planer key =' + str(seqPlanerKey)
   set @cnt = 0
   select  @cnt = count(*)  from SEQPLOUT where(ENG_NAME like 'chasie32' or
   ENG_NAME like '%qck%' or
   ENG_NAME like '%dmg%' or
   ENG_NAME like 'fl%') and
   SEQPLN_KEY = @seqPlanerKey
   if @cnt > 0
   begin
	--return 1;
	  set @retVal = 1
	  return @retVal
   end
   else
   begin
	--return 0;
	  set @retVal = 0
	  return @retVal
   end
end



