if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetBrowserFindReplCancel') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetBrowserFindReplCancel
end
go
 
create procedure absp_InfoTableAttribSetBrowserFindReplCancel   @nodeType integer, @nodeKey integer, @setting bit   

as
begin
    
    set nocount on
    declare @attribName  varchar(25)
	set @attribName = 'BRW_FINDREPLACE_CANCEL'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end