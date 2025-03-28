if exists(select * from SYSOBJECTS where id = object_id(N'absp_getDistinctCode_RS') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getDistinctCode_RS
end
 go
create procedure absp_getDistinctCode_RS @nodeKey int ,@targetCurrKey int ,@srcCurrKey int ,@nodeType int ,@targetDB varchar(130) = ''
as
/*
Purpose:	This procedure is a wrpper of absp_getDistinctCode and returns a resultset to satisfy hibernate
*/
begin

   set nocount on
   declare @retVal int;
   exec @retVal= absp_getDistinctCode @nodeKey,@targetCurrKey,@srcCurrKey,@nodeType,@targetDB

   if @retval is null
   begin
   	   	  select '' as code
	end
end




