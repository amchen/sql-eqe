if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_CASELAYR_delete_CASECOB') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_delete_of_CASELAYR_delete_CASECOB
end
go

create trigger On_delete_of_CASELAYR_delete_CASECOB on CASELAYR
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of record from CASELAYR table and it deletes
                corresponding record from CASECOB table with matching CSLAYR_KEY.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'Executing Trigger On_delete_of_CASELAYR_delete_CASECOB'

    delete CASECOB from CASECOB as a join deleted as d on a.CSLAYR_KEY = d.CSLAYR_KEY;
