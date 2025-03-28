if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_MakeAllMainTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MakeAllMainTables
end
go

create procedure ----------------------------------------------------
absp_Util_MakeAllMainTables AS
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates all tables of DICTTBL that do not exist.

Returns:   Nothing

=================================================================================
</pre>
</font>
##BD_END

*/
begin

   set nocount on
   
  /*
  This will create all tables in DICTTBL that do not exist
  The intent is to call it on the results database during server
  startup because we found an issue with a procedure that failed
  becaused it referenced a missing table.  The results DB only has (had)
  certain tables in it and a proc was changed and then an invalidation failed
  due to the procedure failing.

  Note it does not create indices, or do constraints.
  */
   declare @sSql varchar(MAX)
   declare @sql varchar(1000)
   declare @tmpTablename char(120)
   declare @SWV_curs1_TBLNAME char(120)
   declare @curs1 cursor
   declare @dbBit varchar(10)
   
   
   set @sSql = ''
   set @dbBit= case when DB_NAME()='systemdb' then 'SYS_DB' 
   					 when DB_NAME()='commondb' then 'COM_DB' 
   					 when SUBSTRING(DB_NAME(),len(DB_NAME())-3,len(DB_NAME()))='_IR' then 'CF_DB_IR'
   					 else 'CF_DB'
   					 end
   					 
   
   -- NOTE: we filter out client-only tables

   -- do it
   
   set @sql='declare curs1 cursor fast_forward global for 
   				select distinct rtrim(ltrim(TABLENAME)) as TBLNAME
   				from DICTTBL
				where LOCATION in (''B'',''S'') and ' + @dbBit + 
				' in (''L'', ''Y'') '
				
   	exec(@sql)
    open curs1
   fetch next from curs1 into @SWV_curs1_TBLNAME
   while @@fetch_status = 0
   begin
      if not exists(select 1 from SYSOBJECTS where NAME = @SWV_curs1_TBLNAME and TYPE = 'U')
      begin
      -- begin our create SQL statement
         execute absp_Util_CreateTableScript @sSql output, @SWV_curs1_TBLNAME, '','',0,0,0
         execute(@sSql)
      end
      fetch next from curs1 into @SWV_curs1_TBLNAME
   end
   close curs1
   deallocate curs1
   -- end of the tables cursor
end
