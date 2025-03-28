if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_InvalidCharRepair') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_InvalidCharRepair
end

go

create procedure absp_Migr_InvalidCharRepair 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure will replace all non-alphanumeric characters with an underscore (_)
character in the LONGNAME field for PPRTINFO, RPRTINFO, APRTINFO, PROGINFO, CASEINFO and RTROINFO tables.


Returns:       nothing

=================================================================================
</pre>
</font>
##BD_END


*/
begin
set nocount on

  -- the point of this routine is to replace invaild characters with underscores _
  -- in the LONGNAME fields of certain tables that cause us trouble
   declare @keyName char(120)
   declare @fldName char (120)
   declare @sSql varchar(max)
   declare @key int
   declare @name char (120)
   declare @newName char (120)
   declare @i int
   declare @badChars char (27)
   declare @sqlStr varchar(4000)
   declare @curs_TblName char(10)

   set @fldName = 'LONGNAME'
   set @badChars = '%[`~!@#$^&*{}|:;",.<>/?\\]%'
   -- first get all the table names of interest whose names having bad chars cause trouble
  
   -- get the key name as the first field
   declare currDictTbl cursor fast_forward for select TABLENAME from dbo.absp_Util_GetTableList('Longname.Info') 
   open currDictTbl
   fetch next from currDictTbl into @curs_TblName
   while @@fetch_status = 0
   begin
      select  @keyName = rtrim(ltrim(FIELDNAME))  from DICTCOL where TABLENAME = @curs_TblName and FIELDNUM = 1
      
      -- now create a query to return a list of all records where the LONGNAME has a problem
      set @sSql = 'select '+@keyName+' as AKEY, ltrim(rtrim ('+@fldName+' )) '+' from '+@curs_TblName+' where '+' patindex ( '+''''+@badChars+''''+', '+@fldName+' )  > 0 '
      
      -- inner loop cursor to fix up the ones we found
      begin
         execute('declare cursSql cursor global FOR '+@sSql)
         open cursSql
         fetch next from cursSql into @key,@name
         while @@fetch_status = 0
         begin
            -- SDG__00011476
            exec absp_Util_ReplaceNonAlphas @newName output,@name,0,' '
            -- fix up name by setting badchar to _
            set @i = patindex(@badChars,@newName)
            while @i > 0
            begin
               set @newName = left(@newName,@i -1)+'_'+substring(@newName,@i+1,len(@newName) -@i+1)
               set @i = patindex(@badChars,@newName)
            end
            -- OK, now update the name to the new name
            set @sqlStr = 'update '+@curs_TblName+' set '+@fldName+' = '+''''+@newName+''''+'  where '+@keyName+' = '+rtrim(ltrim(str(@key)))
            execute(@sqlStr)
            fetch next from cursSql into @key,@name
         end
         close cursSql
         deallocate cursSql
      end
      fetch next from currDictTbl into @curs_TblName
   end
   close currDictTbl
   deallocate currDictTbl
-- all done
end


