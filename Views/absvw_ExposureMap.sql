if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_ExposureMap') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_ExposureMap;
end
go

create view absvw_ExposureMap
as
select em.ExposureKey, em.ParentKey, em.ParentType
	from ExposureMap em inner join ExposureInfo ei
	  on em.ExposureKey = ei.ExposureKey
	 and ei.GeocodeStatus = 'Completed';
