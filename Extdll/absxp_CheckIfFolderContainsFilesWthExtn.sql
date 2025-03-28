if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_CheckIfFolderContainsFilesWthExtn') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_CheckIfFolderContainsFilesWthExtn
end
go

create function absxp_CheckIfFolderContainsFilesWthExtn (
    @folderPath   varchar (2000),
    @fileExtn    varchar (10)
)
returns integer
as
begin
    declare @rc integer
    
    -- if some one pass .XXX instead XXX then remove the dot
    set @fileExtn = right(@fileExtn, len(@fileExtn) - CHARINDEX('.', @fileExtn))
    
    execute @rc = master.dbo.eqe_CheckIfFolderContainsFilesWthExtn @folderPath, @fileExtn

    return @rc
end


