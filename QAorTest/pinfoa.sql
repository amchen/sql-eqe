if exists(select 1 from SYSOBJECTS where ID = object_id(N'pinfoa') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure pinfoa
end
 go
create procedure pinfoa
as
begin
   set nocount on
   exec absp_Util_GetPPortInfoA
end