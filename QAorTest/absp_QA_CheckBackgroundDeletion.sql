if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_CheckBackgroundDeletion') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_CheckBackgroundDeletion
end
 go

create procedure absp_QA_CheckBackgroundDeletion
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure checks whether the background deletion is complete. 
				It exits once the process is complete.
.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin  
	set nocount on
	declare @isDeleted int;
		
	---Check if background deletion is complete---
	while (1=1)
	begin
		
		set @isDeleted=1;
		if exists (select * from AprtInfo where Status='Deleted')
			set @isDeleted=0;
		else if  exists (select * from PprtInfo where Status='Deleted')
			set @isDeleted=0;
		else if  exists (select * from RprtInfo where Status='Deleted')
			set @isDeleted=0;
		else if  exists (select * from ProgInfo where Status='Deleted')
			set @isDeleted=0;
		else if  exists (select * from CaseInfo where Status='Deleted')
			set @isDeleted=0;
	 	else if  exists (select * from ExposureInfo where Status='Deleted')
			set @isDeleted=0;
		else if  exists (select * from EltSummary where Status='Deleted')
			set @isDeleted=0;	
		if @isDeleted=1 
			break;
		else
			exec absp_Util_Sleep 5000;
	end
	exec absp_Util_Sleep 60000;
end