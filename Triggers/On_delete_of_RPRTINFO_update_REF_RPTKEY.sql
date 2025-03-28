if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_RPRTINFO_update_REF_RPTKEY') and objectproperty(id,N'IsTrigger') = 1)
begin
   drop trigger On_delete_of_RPRTINFO_update_REF_RPTKEY
end
go

create trigger On_delete_of_RPRTINFO_update_REF_RPTKEY on RPRTINFO
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of a record in the RPRTINFO table and it
                updates the REF_RPTKEY to 0 thus dereferencing the reference rportkey for other rports.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'TRIGGER On_delete_of_RPRTINFO_update_REF_RPTKEY starts'

    update RPRTINFO set REF_RPTKEY = 0 from RPRTINFO as a join deleted as d on a.REF_RPTKEY = d.RPORT_KEY;
