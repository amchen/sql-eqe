if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateDbSpace') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateDbSpace
end
go
create procedure absp_Util_CreateDbSpace(@dbSpaceName char(40) ,@dbSpacePath char(255))
as
begin

   set nocount on
   
-- This is an empty procedure
-- Kept to maintain consistancy with ASA
   return 0

end


