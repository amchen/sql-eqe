if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanupDataExtraction') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CleanupDataExtraction;
end
go

create procedure  absp_CleanupDataExtraction @exposureKey int
as

/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	This procedure will drop the exk<exposureKey>_raw schema. 

Returns:	Nothing

====================================================================================================
</pre>
</font>
##PD  @exposureKey ^^ The exposureKey
##BD_END
*/
begin
	set nocount on
	declare @schemaName varchar(1000)
	declare @sname varchar(200)
	
	
	set @schemaName=   dbo.absp_Util_GetSchemaName(@exposureKey) + '_raw'
	if exists(select 1 from sys.schemas where name= @schemaName)
		exec absp_Util_CleanupSchema @schemaName
		
	set @schemaName=   dbo.absp_Util_GetSchemaName(@exposureKey)
	if exists(select 1 from sys.schemas where name= @schemaName)
		exec absp_Util_CleanupSchema @schemaName
	
	--Drop linked server
	--declare c1 cursor for select srvName from master.sys.sysservers where srvName like 'LknSvr%'
	--open c1
	--fetch c1 into @sname
	--while @@fetch_status=0
	--begin
	--	exec sp_dropserver @sname, 'droplogins'
	--	fetch c1 into @sname
	--end
	--close c1
	--deallocate c1
	
end