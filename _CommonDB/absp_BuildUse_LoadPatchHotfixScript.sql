--nogocheck
-----------------------------------------------------------------------------------
-- commondb database
-----------------------------------------------------------------------------------
-- Path to procedures D:\Working\SETUP_EQE\CD-Db\EDM\ZZPROCS_MSSQL
-- Load procedures into the PatchHotfixScript table

-- strip drop clause
update commondb.dbo.PatchHotfixScript
	set ScriptText = substring(ScriptText, charindex('create ', ScriptText), len(ScriptText))
	where ScriptName <> '';
