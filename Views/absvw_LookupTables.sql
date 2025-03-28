if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_LookupTables') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_LookupTables;
end
go

create view absvw_LookupTables
as
select * from DICTTBL
	where TABLETYPE = 'LOOKUP' and LOCATION <> 'C';
