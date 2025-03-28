if exists(select * from sysobjects where ID = object_id(N'absp_Util_GetNodeKeyByName_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetNodeKeyByName_RS
end
go
 
create procedure absp_Util_GetNodeKeyByName_RS @nodeName varchar(255),@nodeType int,@parentKey int = 0 

/*
Purpose:  This procedure is a wrapper to absp_Util_GetNodeKeyByName and returns a resultset to satisfy hibernate

*/
as

begin

	set nocount on
	declare @lastKey int;
	exec @lastKey= absp_Util_GetNodeKeyByName @nodeName,@nodeType,@parentKey;
	select @lastKey as lastKey;
   
end



