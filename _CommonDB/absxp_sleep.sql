if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_sleep') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_sleep
end
go

create function absxp_sleep (
    @msecs  integer
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_sleep @msecs

    return @rc
end

