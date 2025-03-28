if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_GetPrivateProfileString') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_GetPrivateProfileString
end
go

create function absxp_GetPrivateProfileString (
    @lpAppName  char(255),   -- section name
    @lpKeyName  char(255),   -- key name
    @lpDefault  char(255),   -- default string
    @lpFileName char(255)    -- initialization file name
)
returns char(255)
as
begin
    declare @theString char(255)

    execute master.dbo.eqe_GetPrivateProfileString @lpAppName, @lpKeyName, @lpDefault, @lpFileName, @theString output

    return @theString
end

