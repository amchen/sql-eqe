if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_TemplateTables') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_TemplateTables
end
go
create view absvw_TemplateTables
as select* from DICTTBL where TABLETYPE = 'TEMPLATE' and LOCATION <> 'C'