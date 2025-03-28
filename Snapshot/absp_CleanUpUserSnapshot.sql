if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanUpUserSnapshot') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanUpUserSnapshot
end
 go

create procedure absp_CleanUpUserSnapshot @snapshotKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will be invoked if a Snapshot task is cancelled or failed.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin
	set nocount on
	declare @schemaname varchar(50);
	
	--Get schemaName based on the given snapshot key--
	select @schemaName=SchemaName from SnapshotInfo where SnapshotKey=@snapshotKey;

	--Drop schema--
	execute absp_Util_CleanupSchema @schemaName
	
	--Clanup Snapshot tables--
	delete from SnapshotInfo where SnapshotKey=@snapshotKey;
	delete from SnapshotMap where SnapshotKey=@snapshotKey;
	
end
