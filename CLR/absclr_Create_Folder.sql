if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_Create_Folder') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absclr_Create_Folder
end
go

create procedure absclr_Create_Folder  @folderName varchar (255) 
as
begin
	--Returns 0 on success--
    declare @rc integer

    exec @rc=systemdb.dbo.clr_Util_FolderCreate @folderName
	if @rc <>0 set @rc=1 --Could not create folder 
    return @rc
end


