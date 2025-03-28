if exists(select 1 from SYSOBJECTS where ID = object_id(N'rinfoa') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure rinfoa
end
 go
create procedure rinfoa
as
begin
   set nocount on
   exec absp_Util_GetRPortInfoA
end