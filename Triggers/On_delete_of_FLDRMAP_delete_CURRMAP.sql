if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_FLDRMAP_delete_CURRMAP') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_delete_of_FLDRMAP_delete_CURRMAP
end
go

create trigger On_delete_of_FLDRMAP_delete_CURRMAP on fldrmap
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This trigger gets fired on the deletion of a record in the FLDRMAP table and it deletes
               the CURRMAP record for the corresponding child pport/rport only if no map entry exists
               for them in FLDRMAP and APORTMAP.


Returns:       It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    declare @childKey   int
    declare @childType  int
    declare @aportCount int
    declare @fldrCount  int
    Declare @i          int

    Declare @IntermediateData table(RowId Int, FOLDER_KEY int, CHILD_KEY int, CHILD_TYPE int)

    execute absp_messageEx 'TRIGGER On_delete_of_FLDRMAP_delete_CURRMAP starts'

    Insert into @IntermediateData
                Select ROW_NUMBER () OVER (order by DELETED.FOLDER_KEY), FOLDER_KEY, CHILD_KEY, CHILD_TYPE
                from DELETED
                where CHILD_TYPE in (2,3,23)

    Set @i = 0

    While (@i < (Select max(RowId) From @IntermediateData))
    Begin
        Set @i = @i + 1

        Select  @childKey = CHILD_KEY, @childType = CHILD_TYPE
        from    @IntermediateData
        Where   RowId = @i

        select  @fldrCount = count(*)  from fldrmap where CHILD_KEY = @childKey and CHILD_TYPE = @childType
        select  @aportCount = count(*)  from APORTMAP where CHILD_KEY = @childKey and CHILD_TYPE = @childType

        if @fldrCount + @aportCount = 0
        begin
            delete from CURRMAP where CHILD_KEY = @childKey and CHILD_TYPE = @childType
        end
    end
