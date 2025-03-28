if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewFolderMove') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_TreeviewFolderMove;
end
go

create procedure absp_TreeviewFolderMove @folderKey int, @currentParentKey int, @newParentKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure moves a sub-folder from one parent folder node to another by updating the map entry in
the FLDRMAP table.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  folderKey ^^  The key of the folder node that is to be moved.
##PD  currentParentKey ^^  The current parent node key of the folder that is to be moved.
##PD  newParentKey ^^  The key of the parent folder node under which the given folder is to be moved.

*/
as
begin
	set nocount on;

	if @folderKey = 0
	begin
		return;
	end

	update FLDRMAP set FOLDER_KEY = @newParentKey
		where FOLDER_KEY = @currentParentKey and CHILD_KEY = @folderKey and CHILD_TYPE = 0;
end
