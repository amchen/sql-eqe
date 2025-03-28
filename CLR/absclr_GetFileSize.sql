if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_GetFileSize') and objectproperty(ID,N'IsScalarProcedure') = 1)
begin
   drop procedure absclr_GetFileSize
end
go

create procedure absclr_GetFileSize  (@fileName varchar(255))

as
begin

    declare @rc integer;

    set @rc=systemdb.dbo.clr_Util_GetFileSizeMB (@fileName );
    return @rc;
end
