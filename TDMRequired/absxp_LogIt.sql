if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_LogIt') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_LogIt
end
go

create function absxp_LogIt (
    @logFile char (255),
    @logMsg char (255)
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_LogIt @logFile, @logMsg

    if (@rc = 1)
	set @rc = 0
	else if (@rc = 0)
		set @rc = 1
    return @rc
end


