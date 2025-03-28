if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_GetEnvironmentVariable') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_GetEnvironmentVariable
end
go

create function absxp_GetEnvironmentVariable (
    @environName  char(255)
)
returns char(255)
as
begin
    declare @environValue char(255)

    execute master.dbo.eqe_GetEnvironmentVariable @environName, @environValue output

    return @environValue
end

