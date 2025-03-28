if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetDependentBatchJobs') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDependentBatchJobs
end
 go

create procedure absp_GetDependentBatchJobs @pKey int as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This is a recursive procedure to get dependent batch jobs.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

*/
begin
	set nocount on;
	
	WITH cte (BatchJobKey,ParentKey) AS (
		select  BatchJobKey,0	from commondb..BatchJob where BatchJobKey=@pKey	
		union all
		select  t.BatchJobKey, cte.BatchJobKey	from cte , commondb..BatchJob t
			where  charindex(','+ dbo.trim(cast(cte.BatchJobKey as varchar))+',',replace(','+DependencyKeyList+',',' ',''))>0
	)
  select * from commondb..BatchJob where BatchJobKey in (select distinct BatchJobKey from  cte where BatchJobKey<>@pKey)
end