if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_PPRTINFO_update_REF_PPTKEY') and OBJECTPROPERTY(id,N'IsTrigger') = 1)
begin
   drop trigger On_delete_of_PPRTINFO_update_REF_PPTKEY
end
go

create trigger On_delete_of_PPRTINFO_update_REF_PPTKEY on PPRTINFO
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of a record in the PPRTINFO table and it
                updates the REF_PPTKEY to 0 thus dereferencing the reference pportkey for other pports.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'TRIGGER On_delete_of_PPRTINFO_update_REF_PPTKEY starts'

    update PPRTINFO set REF_PPTKEY = 0 from PPRTINFO as a join deleted as d on a.REF_PPTKEY = d.PPORT_KEY;
