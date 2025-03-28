if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_insert_of_PROGINFO_insert_or_update_RGROUP_RBROKER_RPRGSTAT') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_insert_of_PROGINFO_insert_or_update_RGROUP_RBROKER_RPRGSTAT
end
go

create trigger On_insert_of_PROGINFO_insert_or_update_RGROUP_RBROKER_RPRGSTAT on PROGINFO
after insert as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This trigger gets fired on the insertion of a record in the PROGINFO table and it inserts
               the corresponding group name,broker name and re insurance program status in respective
               tables like RGROUP, RBROKER and RPRGSTAT.

Returns:       It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    declare @NewGrpName char(40)
    declare @NewBrokerName char(40)
    declare @NewPortstat char(40)
    declare @refCount int

    execute absp_messageEx 'TRIGGER On_insert_of_PROGINFO_insert_or_update_RGROUP_RBROKER_RPRGSTAT starts'

    select @NewGrpName = GROUP_NAM, @NewBrokerName = BROKER_NAM, @NewPortstat = PROGSTAT from INSERTED

    select  @refCount = COUNT(*)  from RGROUP where RGROUP.NAME = @NewGrpName

    if @refCount = 0 and LEN(rtrim(ltrim(@NewGrpName))) > 0
    begin
        insert into RGROUP(NAME) values(@NewGrpName)
    end

    select   @refCount = COUNT(*)  from RBROKER where RBROKER.NAME = @NewBrokerName

    if @refCount = 0 and LEN(rtrim(ltrim(@NewBrokerName))) > 0
    begin
        insert into RBROKER(NAME) values(@NewBrokerName)
    end

    select   @refCount = COUNT(*)  from RPRGSTAT where RPRGSTAT.PROGSTAT = @NewPortstat

    if @refCount = 0 and LEN(rtrim(ltrim(@NewPortstat))) > 0
    begin
        insert into RPRGSTAT(PROGSTAT) values(@NewPortstat)
    end
