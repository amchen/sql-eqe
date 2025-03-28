if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_Delete_File') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absclr_Delete_File
end
go

create procedure absclr_Delete_File @filename varchar (255) 
as
begin

	--Returns 0 on success--
    declare @rc integer

    exec @rc=systemdb.dbo.clr_Util_FileDelete @filename
	if @rc <>0 set @rc=1 --Could not delete file
    return @rc
end

