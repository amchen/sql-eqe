if exists(select * from sysobjects where id = object_id(N'absp_DumpRes') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DumpRes
end
 go
create procedure absp_DumpRes @passwd char(3) 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure deletes all the portfolio analysis results from the results tables.

Returns:	Nothing

====================================================================================================

</pre>
</font>

##BD_END

##PD   @passwd  ^^ The password

*/
as
begin

   set nocount on
   
   -- get rid of  results
   declare @sql varchar(max)
   declare @curs1_TblName char(10)
   declare curs1  cursor dynamic  for select TABLENAME from dbo.absp_Util_GetTableList('QA.Portfolio.Results')
   if @passwd = 'yes'
   begin
      open curs1
      fetch next from curs1 into @curs1_TblName
      while @@fetch_status = 0
      begin
         set @sql = 'delete  '+rtrim(ltrim(@curs1_TblName))
         execute(@sql)
         fetch next from curs1 into @curs1_TblName
      end
      close curs1
   end
   deallocate curs1
   delete from EXPRES
   delete from LIMITRES
end
