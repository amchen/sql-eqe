if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_update_of_INURLAYR_update_INURCOB') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_update_of_INURLAYR_update_INURCOB
end
go

create trigger On_update_of_INURLAYR_update_INURCOB on INURLAYR
after insert,update as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL

Purpose:        This trigger gets fired on inserting or updating INURLAYR record. It inserts the
                same record in INURCOB with corresponding INLAYR_KEY. It inserts the
                updated record of INURLAYR into INURCOB if it is missing in INURCOB. The trigger
                updates record in INURCOB with matching INLAYR_KEY.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    execute absp_messageEx  'Trigger On_update_of_INURLAYR_update_INURCOB Starts'

    delete INURCOB from INURCOB join INSERTED on INURCOB.INLAYR_KEY = INSERTED.INLAYR_KEY
    insert into INURCOB select ISNULL(INLAYR_KEY,0), ISNULL(COB_ID,0) from INSERTED
