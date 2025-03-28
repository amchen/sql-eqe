if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_GetImportEngineNames') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_GetImportEngineNames
end
go

create view absvw_GetImportEngineNames
as
select ENGINE_ID, NAME, NAME_32, NAME_64
    from ENGINES
    where ENGINE_ID >= 10000
