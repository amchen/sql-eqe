if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getNodeDisplayName_RS') and objectproperty(id,N'IsProcedure') = 1)
begin
drop procedure absp_getNodeDisplayName_RS;
end
go

create procedure absp_getNodeDisplayName_RS @dbName as varchar(120), @batchJobKey INT = 0, @taskKey int = 0, @analysisRunKey int = 0, @yltID int = 0, @schemaName varchar(255) ='', @downloadKey int = 0
as
/*
====================================================================================================
Purpose:

	This procedure will return node displaying name of a task or a batch job given the BatchJobKey or TaskKey.
	Wrapper procedure for absp_getNodeDisplayName to satisfy hibernate which needs a resultset to be returned

Returns:      node displaying name as a resultset
====================================================================================================

##PD  @dbName		^^  executed database name.
##PD  @batchJobKey  ^^  batch job key (taskkey will be used if = 0)
##PD  @TaskKey		^^  task key
*/
begin
      set nocount on
      declare @nodeDispName as varchar(1000);
      exec absp_getNodeDisplayName @nodeDispName out, @dbName, @batchJobKey, @taskKey, @analysisRunKey, @yltID, @schemaName, @downloadKey;
      select @nodeDispName as NodeDisplayName;
end
