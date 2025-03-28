if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetBrowserFindReplFail') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetBrowserFindReplFail
end
go
 
create procedure absp_InfoTableAttribSetBrowserFindReplFail   @nodeType integer, @nodeKey integer, @setting bit   
as
begin
    
    set nocount on
    declare @attribName  varchar(25)
	set @attribName = 'BRW_FINDREPLACE_FAIL'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end