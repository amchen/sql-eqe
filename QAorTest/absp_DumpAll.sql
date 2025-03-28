if exists(select * from SYSOBJECTS where id = object_id(N'absp_DumpAll') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DumpAll
end

go
create procedure absp_DumpAll @passwd char(3) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:    	This procedure deletes the portfolio and trigger information from the associated tables
            	and calls absp_DumpRes() to delete the results. The treeview gets empty except the root node.


Returns:    Nothing

====================================================================================================

</pre>
</font>

##BD_END

##PD    passwd  ^^ The password

*/

as
begin
   declare @sql varchar(2000)
   declare @tablename varchar(120)
   -- get rid of  results 
   
   if @passwd = 'yes'
   begin
      declare curs_dumpAll cursor fast_forward for 
			select TABLENAME from dbo.absp_Util_GetTableList('QA.Portfolio')
      open curs_dumpAll
      fetch next from curs_dumpAll into @tablename
      while @@FETCH_STATUS = 0
      begin
         set @sql = 'DELETE  '+rtrim(ltrim(@tablename))
         execute(@sql)
         fetch next from curs_dumpAll into @tablename
      end
      close curs_dumpAll
      deallocate curs_dumpAll
      
      -- not the root node!
      delete from fldrinfo where FOLDER_KEY > 0
      execute absp_DumpRes @passwd
   end
end
