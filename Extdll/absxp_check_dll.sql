if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_check_dll') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_check_dll
end
go

create function absxp_check_dll ( )
returns integer
as
begin
    declare @rc integer

    execute master.dbo.eqe_checkdll @rc output

--	if (@rc = 1)
--		set @rc = 0
--	else if (@rc = 0)
--		set @rc = 1

    return @rc
end


