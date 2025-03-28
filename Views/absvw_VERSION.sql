if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_VERSION') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_VERSION
end
go

create view absvw_VERSION
as
select
	case when DBType='IDB' then 'Results' when DBType='RDB' then 'RDB' else 'Master' end as DB_NAME,
	SchemaVersion as DB_SCHEMA,
	'' as ARC_SCHEMA,
	RQEVersion as WCEVERSION,
	'' as EQEVERSION,
	Build as BUILD,
	VersionDate as UPDATED_ON,
	ScriptUsed as SCRIPTUSED,
	FlCertificationVersion as FL_CERTVER,
	DBType as DB_TYPE
	from RQEVersion;
