if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChasDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewChasDelete
end
 go

create procedure  absp_TreeviewChasDelete @chasKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes all the WCC Policy data for a given chas key.


Returns:       It returns nothing. It uses the DELETE statement to remove all the WCC Policy data.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @chasKey ^^  The chas key for which the WCC information is to be deleted. 

*/
as
begin

   set nocount on
   
   declare @chasptfKey int
   declare @sql nvarchar(4000)

    delete from CHASDATA where CHAS_KEY = @chasKey
    delete from CHASERRS where CHAS_KEY = @chasKey
    delete from CHASINFO where CHAS_KEY = @chasKey
    delete from CHASPARM where CHAS_KEY = @chasKey

   declare curs1  cursor fast_forward for select CHASPTFKEY  from CHASPTF where CHAS_KEY = @chasKey
   open curs1
   fetch next from curs1 into @chasptfKey
   while @@fetch_status = 0
   begin
	  set identity_insert CHASPTF on;
	  insert into CHASPTF(CHASPTFKEY,CHAS_KEY,LONGNAME,SHORTNAME,PTF_BLOB)
	  select -CHASPTFKEY,CHAS_KEY,LONGNAME,SHORTNAME,PTF_BLOB from CHASPTF where CHASPTFKEY = @chasptfKey
	  set identity_insert CHASPTF off;
	  delete from CHASPTF where CHASPTFKEY = @chasptfKey
      fetch next from curs1 into @chasptfKey
   end
   close curs1
   deallocate curs1
-----------------------------------------------------------------------------------------------------------

  --delete from CHASPTF WHERE CHAS_KEY = chasKey;
end





