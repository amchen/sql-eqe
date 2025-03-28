if exists(select * from SYSOBJECTS where ID = object_id(N'absvw_SummaryKeysNames') and objectproperty(id,N'IsView') = 1)
begin
   drop view absvw_SummaryKeysNames
end
go
create view absvw_SummaryKeysNames
  --SELECT
  --RFOLDERS.FOLDER_KEY,  RFOLDERS.LONGNAME as FolderName, 
  --RPRTINFO.RPORT_KEY, RPRTINFO.LONGNAME as RPortName,
  --PROGINFO.PROG_KEY, PROGINFO.LONGNAME as ProgramName,
  --CASEINFO.CASE_KEY,  CASEINFO.LONGNAME as CaseName
  --FROM (proginfo INNER JOIN (rfolders INNER JOIN ((foldrmap INNER JOIN rprtinfo ON 
  --foldrmap.RPORT_KEY = rprtinfo.RPORT_KEY) INNER JOIN rprtmap ON 
  --rprtinfo.RPORT_KEY = rprtmap.RPORT_KEY) ON rfolders.FOLDER_KEY = 
  --foldrmap.PARENT_KEY) ON proginfo.PROG_KEY = rprtmap.PROG_KEY) INNER JOIN 
  --caseinfo ON proginfo.BCASE_KEY = caseinfo.CASE_KEY
as select* from RPRTINFO

