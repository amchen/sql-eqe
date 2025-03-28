if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_GetDLLBuildNumber') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_GetDLLBuildNumber
end
go

create function absxp_GetDLLBuildNumber ( )
returns char(255)
as
begin
    declare @theBuild char(255)

    execute master.dbo.eqe_GetDLLBuildNumber @theBuild output

    return @theBuild
end

