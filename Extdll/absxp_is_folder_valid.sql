if exists (select 1 from sysobjects where id = object_id('absxp_is_folder_valid') and xtype in ('FN', 'IF', 'TF'))
    drop function absxp_is_folder_valid
go

create function absxp_is_folder_valid (
    @filename char (248)
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_isfoldervalid @filename

    return @rc
end
go
