if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DeleteTemplateByTemplateInfoKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DeleteTemplateByTemplateInfoKey
end
go

create procedure absp_DeleteTemplateByTemplateInfoKey @templateInfoKey int
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure deletes given Template 

Returns:       None.

=================================================================================
</pre> 
</font> 
##BD_END 

*/
begin

   set nocount on
   
    declare @templateName varchar(150)
	declare @templateType int
	declare @stepTemplateID int
   
	select @templateName = TemplateName, @templateType = TemplateType from TemplateInfo where templateInfoKey = @templateInfoKey;
	delete from TemplateInfo where templateInfoKey = @templateInfoKey;

	if(@templateType = 3)
	begin
		select @stepTemplateID = StepTemplateID from StepInfo where StepConditionName = @templateName;
		delete from StepInfo where StepConditionName = @templateName;
		delete from StepDef where StepDef.StepTemplateID = @stepTemplateID
	end

end
