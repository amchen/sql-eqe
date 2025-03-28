if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetBrowserFilterTaskFail') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetBrowserFilterTaskFail
end
go
 
create procedure absp_InfoTableAttribGetBrowserFilterTaskFail   @setting bit out, @nodeType integer, @nodeKey integer  

as
begin

    set nocount on
    
    declare @attribute  varchar(25)
	declare @attribName  varchar(25)
	declare @attribSetting  bit
	
	set @attribName = 'BRW_FILTERTASK_FAIL'
	
	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit)
	insert into @TableVar exec absp_InfoTableAttribAllGet  @nodeType , @nodeKey  
	
	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName
end
