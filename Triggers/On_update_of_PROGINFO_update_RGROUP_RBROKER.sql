if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_update_of_PROGINFO_update_RGROUP_RBROKER') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_update_of_PROGINFO_update_RGROUP_RBROKER
end
go

create trigger On_update_of_PROGINFO_update_RGROUP_RBROKER on PROGINFO
after update as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL

Purpose:        This trigger gets fired on the updation of a record in the PROGINFO table and it inserts the
                corresponding group name and broker name in respective tables like RGROUP and RBROKER,provided
                the new values do not exist in the respective tables.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    declare @NewGrpName char(40)
    declare @NewBrokerName char(40)
    declare @refCount int

    execute absp_messageEx 'TRIGGER On_update_of_PROGINFO_update_RGROUP_RBROKER starts'

    select @NewGrpName = GROUP_NAM, @NewBrokerName = BROKER_NAM from INSERTED

    if update(GROUP_NAM)
    begin
        select   @refCount = COUNT(*)  from RGROUP where RGROUP.NAME = @NewGrpName

        if @refCount = 0 and LEN(rtrim(ltrim(@NewGrpName))) > 0
        begin
            insert into RGROUP(NAME) values(@NewGrpName)
        end
    end

    if update(BROKER_NAM)
    begin
        select @refCount = COUNT(*)  from RBROKER where RBROKER.NAME = @NewBrokerName

        if @refCount = 0 and LEN(rtrim(ltrim(@NewBrokerName))) > 0
        begin
            insert into RBROKER(NAME) values(@NewBrokerName)
        end
    end
