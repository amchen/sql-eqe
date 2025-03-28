if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenerateStepTemplateID') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_GenerateStepTemplateID
end
go

create procedure absp_GenerateStepTemplateID @templateName varchar(120)
as
/*
========================================================================================================================================================================
Purpose: The procedure takes a template name as a parameter and concatenate the template with the current time stamp to generate a unique steptemplate ID. 
Returns: None
Usage:
         exec absp_GenerateStepTemplateID 'BAC EFGHIJBACDEFGHIJBACDEFGHIJBACDEFGHIJBACDQFGHIJBACDEFGHIJBACDEFRHIJBACDEFGHIJBXCDYFGZIVBACDEFGHIJBACUEFGHYSBACDZFGWIXT'

========================================================================================================================================================================
*/
begin
declare @stepTemplateId int;

	while(1=1)
	begin
		select @stepTemplateId= abs(Binary_CheckSum(@templateName + CONVERT(varchar(23), current_timestamp, 121))) 
            
		if not exists (select 1 from StepInfo where StepTemplateID =@stepTemplateId)
			break;
	
		WAITFOR DELAY '00:00:00.050';
	end
	select   @stepTemplateId as StepTemplateId   
end