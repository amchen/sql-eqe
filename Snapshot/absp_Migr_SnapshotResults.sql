if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_SnapshotResults') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_SnapshotResults
end
go

create procedure absp_Migr_SnapshotResults @nodeKey int =1, @nodeType int=12
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will be the driver procedure that will get called from the migration script 
		to perform the result snapshot.It willpreserve the old results during migration in order to compare 
		Results Due to Model Changes between Releases

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin


	set nocount on
	
	exec absp_Migr_SnapshotResultsForEDB @nodeKey, @nodeType;
end