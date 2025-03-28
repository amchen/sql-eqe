if exists (select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_GetLockedObjects') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_GetLockedObjects
end
go

create procedure absp_QA_GetLockedObjects

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This internal procedure returns all locked objects by name that are currently in the EQE database.
It is a short-cut for internal EQE QA use only.

Returns: Result set of locked object names by spid.
====================================================================================================
</pre>
</font>
##BD_END
*/

as
begin

    set nocount on

    create table #LOCKED_OBJECTS (
        spid  smallint,
        dbid  smallint,
        objid int,
        indid smallint,
        type nchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS,
        resource nchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS,
        mode nvarchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS,
        status nvarchar(5)
     COLLATE SQL_Latin1_General_CP1_CI_AS)

    insert #LOCKED_OBJECTS exec sp_lock

    select distinct SPID, OBJECT_NAME(objid) as OBJECT_NAME, type as LOCK_TYPE from #LOCKED_OBJECTS
        where objid > 1000
          and spid >= 50
          and spid <> @@spid
        order by 1,2 desc

end
