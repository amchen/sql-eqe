if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_delete_file') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_delete_file
end
go

create function absxp_delete_file (
    @filename char (248)
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_deletefile @filename

    if (@rc = 1)
	set @rc = 0
    else if (@rc = 0)
	set @rc = 1
    return @rc
end

