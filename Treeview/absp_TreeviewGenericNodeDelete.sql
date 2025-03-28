if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewGenericNodeDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGenericNodeDelete;
end
go

create procedure absp_TreeviewGenericNodeDelete
	@parentKey int,
	@parentType int,
	@nodeKey int,
	@nodeType int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure deletes a given node and all its children.
Returns:    It returns nothing. It uses the DELETE statement to delete a node and its children from the database.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentKey ^^  The key of the parent node for which the child node is to be deleted.
##PD  @parentType ^^  The type of the parent node for which the child is to be deleted.
##PD  @nodeKey ^^  The key of the node that is to be deleted.
##PD  @nodeType ^^  The type of node that is to be deleted.

*/
as

BEGIN TRY

  set nocount on;

	--Folder = 0;
	--APort = 1;
	--PPort = 2;
	--RPort = 3, 23;

	-- call the correct deleter based on the node type

	if @nodeType = 0
	begin
		execute absp_TreeviewFolderDelete @parentKey,@nodeKey;
	end

	if @nodeType = 1
	begin
		execute absp_TreeviewAPortfolioDelete @parentKey,@parentType,@nodeKey;
	end

	if @nodeType = 2
	begin
		execute absp_TreeviewPPortfolioDelete @parentKey,@parentType,@nodeKey;
	end

	if (@nodeType = 3 or @nodeType = 23)
	begin
		execute absp_TreeviewRPortfolioDelete @parentKey,@parentType,@nodeKey;
	end


END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
