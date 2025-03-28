if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DeleteLookups') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DeleteLookups
end
go

create procedure ----------------------------------------------------
absp_Util_DeleteLookups @transId int  
as
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes all records containing the given TransId from the lookup tables having 
foreign key references.

Returns:       Nothing 
====================================================================================================
</pre>
</font>
##BD_END  

##PD  @transId ^^  The Lookup Table translatorID.

*/
begin

   set nocount on
   
   declare @sql varchar(max)
   declare @retVal int
   declare @SWV_curs1_FK_TABLE char(8)
   declare @curs1 cursor
   declare @SWV_exec nvarchar(4000)
  --message '==========================';
  -- Remove all of the lookups that have a specific TRANS_ID
   set @curs1 = cursor dynamic for select distinct FK_TABLE from DICTFKLK
   open @curs1
   fetch next from @curs1 into @SWV_curs1_FK_TABLE
   while @@fetch_status = 0
   begin
      begin transaction
      set @sql = 'delete from '+@SWV_curs1_FK_TABLE+' where TRANS_ID = '+rtrim(ltrim(str(@transId)))
    --message @sql;
      set @SWV_exec = @sql
      execute sp_executesql @SWV_exec
      commit work
      fetch next from @curs1 into @SWV_curs1_FK_TABLE
   end
   close @curs1
  --message '==========================';
   set @retVal = 0
   return @retval
   
end





