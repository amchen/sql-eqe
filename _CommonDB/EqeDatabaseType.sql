if exists(select * from SYSOBJECTS where ID = object_id(N'eqeDatabaseType') and objectproperty(id,N'IsView') = 1)
begin
   drop view eqeDatabaseType;
end
go

create view eqeDatabaseType
as
select top 1 DbType from RQEVersion;
