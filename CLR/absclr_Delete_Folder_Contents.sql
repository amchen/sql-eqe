if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_Delete_Folder_Contents') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absclr_Delete_Folder_Contents
end
go

create procedure absclr_Delete_Folder_Contents @folderName varchar (255)
as
begin

	--Returns 0 on success--
    declare @rc integer

    exec @rc=systemdb.dbo.clr_Util_FolderDeleteContents @folderName
	if @rc <>0 set @rc=1 --Could not delete folder contents
    return @rc
end

