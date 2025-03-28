if exists(select * from SYSOBJECTS where ID = object_id(N'absp_10951_FixExposureCacheInfoColType') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_10951_FixExposureCacheInfoColType;
end
go

create procedure  absp_10951_FixExposureCacheInfoColType
as

begin
	set nocount on

	declare @sql varchar(max);        
	declare @cName varchar(200); 

	--Get Default Constraint on ExposureKey--       
	select @cName=d.Name from sys.tables t
	   inner join sys.default_constraints d on d.parent_object_id = t.object_id
	   inner join sys.columns c  on c.object_id = t.object_id   and c.column_id = d.parent_column_id
	   where t.name = 'ExposureCacheInfo' and c.name = 'ExposureKey';

	--Drop Constraint--    
	set @sql ='ALTER TABLE ExposureCacheInfo DROP CONSTRAINT [' + @cName + ']'
	exec (@sql)

	--Drop Index on ExposureKey--
	if exists(select * from sys.indexes where object_id=object_Id('ExposureCacheInfo') and name='ExposureCacheInfo_I1')
		Drop Index ExposureCacheInfo_I1 ON ExposureCacheInfo

	--Modify data type--
	Alter Table exposurecacheinfo alter column exposurekey int not null

	--Recreate Index--
	Create NonClustered Index ExposureCacheInfo_I1 ON ExposureCacheInfo (ExposureKey ASC)

	--Recreate Default Constraint--
	Alter Table ExposureCacheInfo ADD  DEFAULT ((0)) FOR ExposureKey

end;

