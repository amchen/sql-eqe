if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsEmptyDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsEmptyDB
end

go
create procedure -------------------------------------------------------------------------------------------------
absp_Util_IsEmptyDB AS
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

This procedure will return a value which specifies whether the database is empty or not.

Returns:       It returns a single value in @rc
@rc = 0 if the Database is not empty 
@rc = 1 if the Database is empty.
====================================================================================================
</pre>
</font>
##BD_END

##RD  @rc ^^  0 if the Database is not empty and 1 if the Database is empty.

*/
begin

   set nocount on
   
  -- This procedure will check if the database is empty. Master and Results have different methods.
  -- Parameter: theMode = 0, returns value as a function
  --            theMode = 1, returns RESULT as a result set to calling procedure
  -- Returns:   0 for No, 1 for Yes.
   declare @rc int
   declare @cnt int
   declare @tblName varchar(255)
   declare @tblCnt int
   declare @sql nvarchar(4000)
   
   set @rc = 1 -- Assume database is empty
   set @cnt = 0
   if exists(select 1 from RQEVersion where DbType = 'EDB')
   begin
      select   @cnt = count(*)  from RQEVersion
     -- not empty
      if(@cnt <> 1)
      begin
         set @rc = 0
      end
      select   @cnt = count(*)  from FLDRMAP
     -- not empty
      if(@cnt <> 1)
      begin
         set @rc = 0
      end
   end
   else
   begin

      declare curs1 cursor for select distinct tablename from DELCTRL 
	  inner join SYS.TABLES on DELCTRL.tablename = SYS.TABLES.NAME
	  where
      TABLE_TYPE = 'B' and
      tablename not in('EVENTRES','EXPRES','LIMITRES')
      open curs1
      fetch next from curs1 into @tblName
      while @@fetch_status = 0
      begin
         set @sql='select @tblCnt=count(*) from '+ @tblName
         exec sp_executesql @sql,N'@tblCnt int out', @tblCnt out
         set @cnt = @cnt+ @tblCnt
         fetch next from curs1 into @tblName
      end
      close curs1
      deallocate curs1
     -- not empty		
      if(@cnt > 0)
      begin
         set @rc = 0
      end
   end
   return @rc
end



