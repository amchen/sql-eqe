if exists(select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_APRTINFO_update_REF_APTKEY') and objectproperty(id,N'IsTrigger') = 1)
begin
   drop trigger On_delete_of_APRTINFO_update_REF_APTKEY
end
go

create trigger On_delete_of_APRTINFO_update_REF_APTKEY on APRTINFO
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of a record in the APRTINFO table and it updates the
                ref_aptkey to 0 thus dereferencing the reference aportkey for other aports.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'TRIGGER On_delete_of_APRTINFO_update_REF_APTKEY starts'

    update APRTINFO set REF_APTKEY = 0 from APRTINFO as a join deleted as d on a.REF_APTKEY = d.APORT_KEY;
