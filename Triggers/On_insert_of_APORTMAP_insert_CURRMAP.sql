if exists (select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.On_insert_of_APORTMAP_insert_CURRMAP') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_insert_of_APORTMAP_insert_CURRMAP
end
go

create trigger On_insert_of_APORTMAP_insert_CURRMAP on APORTMAP
after insert as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the insertion of a record in the APORTMAP table and it
                inserts a record into the CURRMAP table to map the inserted child node with the
                corresponding parent currency folder.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    declare @currKey    integer
    declare @childKey   integer
    declare @childType  integer

    execute absp_messageEx 'TRIGGER On_insert_of_APORTMAP_insert_CURRMAP starts'

    select @childKey = CHILD_KEY, @childType = CHILD_TYPE from INSERTED

    -- Only continue if the new APORTMAP record was for either Primary (2) or Reinsurance portfolios (3)
    if @childType = 2 or @childType = 3 or @childType = 23
    begin

        -- find the currency key for the new record
        execute @currKey = absp_FindNodeCurrencyKey @childKey, @childType

        -- insert the record ONLY if it does not already exist
        if not exists (select 1 from CURRMAP where FOLDER_KEY = @currKey and CHILD_KEY = @childKey and CHILD_TYPE = @childType)
        begin
            insert into CURRMAP (FOLDER_KEY, CHILD_KEY, CHILD_TYPE) values
                                (@currKey, @childKey, @childType)
        end
    end
