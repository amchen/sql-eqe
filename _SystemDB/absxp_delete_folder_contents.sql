if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_delete_folder_contents') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_delete_folder_contents
end
go

create function absxp_delete_folder_contents (
    @folderName   char (248),
    @forceFlag    integer
)
returns integer
as
begin
    declare @rc integer

    execute @rc = master.dbo.eqe_deletefoldercontents @folderName, @forceFlag
    
    if (@rc = 1)
    		set @rc = 0
    	else if (@rc = 0)
		set @rc = 1
		
    return @rc
end

