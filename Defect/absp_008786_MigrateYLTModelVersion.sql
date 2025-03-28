if exists(select * from SYSOBJECTS where ID = object_id(N'absp_008786_MigrateYLTModelVersion') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_008786_MigrateYLTModelVersion;
end
go

create procedure  absp_008786_MigrateYLTModelVersion
as

begin
	set nocount on;
	
	declare @sql nvarchar(max);

	--rename existing table--
	if not exists(select 1 from sys.tables where name='YLTModelVersion_Backup')			
		exec sp_rename 'YLTModelVersion','YLTModelVersion_Backup';
	print 'backup created';
				
	--create table with indexes--
	exec systemdb..absp_Util_CreateTableScript @sql out, 'YLTModelVersion','','',1;
	exec (@sql);
	print 'table created';
	
	--insert to new table, select distinct from existing table--
	insert into YLTModelVersion select distinct * from YLTModelVersion_Backup;
	
	--delete existing table--
	if exists(select 1 from sys.objects where name='YLTModelVersion_Backup')
		drop table YLTModelVersion_Backup;
end;