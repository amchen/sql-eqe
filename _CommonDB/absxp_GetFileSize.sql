if exists(select * from SYSOBJECTS where ID = object_id(N'absxp_GetFileSize') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absxp_GetFileSize
end
go

create function absxp_GetFileSize (
    @theFile   char (248)
)
returns integer
as
begin
    declare @theSize integer

    execute master.dbo.eqe_GetFileSize @theFile, @theSize output
    if @theSize = -2 
    begin
      set @theSize = -1
    end
    return @theSize
end


