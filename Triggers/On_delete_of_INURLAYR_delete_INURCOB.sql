if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_INURLAYR_delete_INURCOB') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_delete_of_INURLAYR_delete_INURCOB
End
go
create trigger On_delete_of_INURLAYR_delete_INURCOB on INURLAYR
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of record from INURLAYR table and it deletes
                corresponding record from INURCOB table with matching INLAYR_KEY.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'Executing Trigger On_delete_of_INURLAYR_delete_INURCOB'

    delete INURCOB from INURCOB as a join deleted as d on a.INLAYR_KEY = d.INLAYR_KEY;
