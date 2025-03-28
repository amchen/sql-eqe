if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_update_of_CASELAYR_update_CASECOB') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_update_of_CASELAYR_update_CASECOB
end
go

create trigger On_update_of_CASELAYR_update_CASECOB on CASELAYR
after insert, update as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on inserting or updating CASELAYR record. It inserts the
                same record in CASECOB with corresponding CSLAYR_KEY. It inserts the
                updated record of CASELAYR into CASECOB if it is missing in CASECOB. The trigger
                updates record in CASECOB with matching CSLAYR_KEY.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx 'Trigger On_update_of_CASELAYR_update_CASECOB Starts'

    delete CASECOB from CASECOB join INSERTED on CASECOB.CSLAYR_KEY = INSERTED.CSLAYR_KEY
    insert into CASECOB select ISNULL(CSLAYR_KEY,0), ISNULL(COB_ID,0) from INSERTED
