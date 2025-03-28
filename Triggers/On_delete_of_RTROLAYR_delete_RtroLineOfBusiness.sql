if exists (select 1 from SYSOBJECTS where ID = object_id(N'On_delete_of_RTROLAYR_delete_RtroLineOfBusiness') and objectproperty(id,N'IsTrigger') = 1)
begin
    drop trigger On_delete_of_RTROLAYR_delete_RtroLineOfBusiness
end
go

create trigger On_delete_of_RTROLAYR_delete_RtroLineOfBusiness on RTROLAYR
after delete as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     MSSQL
Purpose:        This trigger gets fired on the deletion of record from RTROLAYR table and it deletes
                corresponding record from RtroLineOfBusiness table with matching RTLAYR_KEY.

Returns:        It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END
*/
    delete RtroLineOfBusiness from RtroLineOfBusiness join DELETED on RtroLineOfBusiness.RtLayerKey = DELETED.RTLAYR_KEY
