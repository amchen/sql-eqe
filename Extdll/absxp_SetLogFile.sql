if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_SetLogFile') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_SetLogFile
end
go

create function absxp_SetLogFile (
    @logFile    char (248),
    @bOverWrite integer
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_SetLogFile @logFile, @bOverWrite

    if (@rc = 1)
		set @rc = 0
	else if (@rc = 0)
		set @rc = 1
    return @rc
end

