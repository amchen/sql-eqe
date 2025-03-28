if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_update_of_APORTMAP_update_CURRMAP') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_update_of_APORTMAP_update_CURRMAP
end
go

create trigger On_update_of_APORTMAP_update_CURRMAP on APORTMAP
after update as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL

Purpose:        This trigger gets fired when the child nodes of one accumulation portfolio is moved to another
                accumulation portfolio. The new currency folder key is updated in the currency mapping table
                (CurrMap)


Returns:       It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    declare @childKeyOld    int
    declare @childTypeOld   int
    declare @childKeyNew    int
    declare @childTypeNew   int
    declare @currKeyNew     int
    declare @i              int

    declare @IntermediateData table(RowId           Int,    APORT_KEY       int,
                                    CHILD_KEY_OLD   int,    CHILD_TYPE_OLD  int,
                                    CHILD_KEY_NEW   int,    CHILD_TYPE_NEW  int)

    execute absp_messageEx 'Trigger On_update_of_APORTMAP_update_CURRMAP'

    insert into @IntermediateData
                select  ROW_NUMBER () OVER (order by D.APORT_KEY),
                        D.APORT_KEY, D.CHILD_KEY, D.CHILD_TYPE,
                        I.CHILD_KEY, I.CHILD_TYPE
                from DELETED D
                join INSERTED I on      D.CHILD_KEY     = I.CHILD_KEY
                                and     D.CHILD_TYPE    = I.CHILD_TYPE
                                where   D.CHILD_TYPE in (2,3,23)

    set @i = 0
    while (@i < (select max(RowId) from @IntermediateData))
    begin
        Set @i = @i + 1


        select  @childKeyOld = CHILD_KEY_OLD, @childTypeOld = CHILD_TYPE_OLD,
                @childKeyNew = CHILD_KEY_NEW, @childTypeNew = CHILD_TYPE_NEW
        from    @IntermediateData
        Where   RowId = @i

        if @childKeyOld = @childKeyNew and @childTypeOld = @childTypeNew
        begin
            execute @currKeyNew = absp_FindNodeCurrencyKey @childKeyNew, @childTypeNew
            update CURRMAP set FOLDER_KEY = @currKeyNew where CHILD_KEY = @childKeyOld and CHILD_TYPE = @childTypeOld
        end
    end
