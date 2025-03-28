if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateReportFilterInfoForAllNodes') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateReportFilterInfoForAllNodes
end
go

create procedure absp_GenerateReportFilterInfoForAllNodes @threshold int=20000
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure generates report filter information for the all the
		analysisRunKeys.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin 
	set nocount on
	
	declare @analysisRunKey int;
	

	declare curs  cursor for select analysisRunKey from AnalysisRunInfo 
	open curs
	fetch next from curs into @analysisRunKey
	while @@fetch_status = 0
	begin

		exec absp_GenerateReportFilterInfo -1,@threshold, @analysisRunKey;
		
		fetch next from curs into @analysisRunKey;
	end;
	close curs;
	deallocate curs;
end