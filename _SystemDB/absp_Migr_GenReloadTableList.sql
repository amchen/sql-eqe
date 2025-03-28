if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_GenReloadTableList') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_GenReloadTableList
end
go

create procedure absp_Migr_GenReloadTableList
    @ret_ColList  varchar(max) output ,
    @baseName     varchar(120) ,
    @debugFlag    int = 0 ,
    @newTableName varchar(120) = ''

--returns long varchar
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a comma separated list of column names that exist in the given tables as
defined in the data dictionary in an OUTPUT parameter. The default values are substituted for new columns. If no defaults exist,
the default is 0 for numeric columns and empty string for strings.

Returns:      Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @baseName ^^ The table name for which the column list is to be generated
##PD  @columnList ^^ This is an OUTPUT parameter where the string containing a comma seperated list of columns for the given table will be returned.
##PD  @debugFlag ^^ The debug Flag.
##PD  @newTableName ^^ The table whose actual schema is to be compared



*/
as
begin

set nocount on

/*
This function is used by migration to generate the column name string for use by absp_Migr_ReloadTable().
Default values in DICTTBL will be substituted for new columns.
If no default values are found, then the following rules apply:

1. If the new column is a char/string, the default value will be an empty string, else
2. The default will be zero.

parameter:
The tablename for absp_Migr_ReloadTable().

usage:
set @columnList = absp_Migr_GenReloadTableList ( 'ESDL' )
*/

   declare @columnList varchar(max)
   declare @cnt        int
   declare @len        int
   declare @defval     char(15)
   declare @deftype    char(1)
   declare @repval     char(15)
   declare @repfld     varchar(120)
   declare @newTblName varchar(120)
   declare @msgText    varchar(255)
   declare @sql        varchar(255)
   declare @FldName    varchar(255)

   -- init variables
   set @cnt = 0
   set @columnList = ''
   if(@newTableName = '')
   begin
      set @newTblName = @baseName
   end
   else
   begin
      set @newTblName = @newTableName
   end

   -- select from DICTCOL
   if not exists(select 1 from DICTCOL where TABLENAME = @baseName)
   begin
      set @msgText = 'Error: Table '+@baseName+' not found in DICTTBL'
      execute absp_MessageEx @msgText
      set @columnList = 'ERROR_'+ltrim(rtrim(@baseName))+'_NOT_IN_DICTTBL'
      set @ret_ColList = @columnList
      return
   end
   else
   begin
      select   FIELDNUM,rtrim(ltrim(FIELDNAME)) as FIELDNAME,rtrim(ltrim(str(FIELDNUM)))+'-'+rtrim(ltrim(rtrim(ltrim(FIELDNAME)))) as FIELDORD into #tmp1
      from DICTCOL where TABLENAME = @baseName order by FIELDNUM asc
   end
   create table #tmp2
   (
		FIELDNUM smallint,
		FIELDNAME char(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
		FIELDORD char(50)
	 COLLATE SQL_Latin1_General_CP1_CI_AS)
   if not exists(select 1 from SYS.SYSCOLUMNS where Object_Name(id) =  @newTblName)
   begin
      insert into #tmp2
        select FIELDNUM, FIELDNAME,rtrim(ltrim(str(FIELDNUM)))+'-'+rtrim(ltrim(FIELDNAME)) as FIELDORD
        from DICTCOL where TABLENAME = @baseName order by FIELDNUM asc
   end
   else
   begin
      insert into #tmp2
        select COLUMN_ID as FIELDNUM,rtrim(ltrim(NAME)) as FIELDNAME,rtrim(ltrim(str(COLUMN_ID)))+'-'+rtrim(ltrim(NAME)) as FIELDORD
        from SYS.COLUMNS where Object_Name(object_id) = @newTblName order by COLUMN_ID asc
   end
   select   @cnt = count(*)  from #tmp1 where not FIELDORD = any(select FIELDORD from #tmp2)

   -- create a CSV ordered-list of all the columns from DICTCOL
   set @sql = 'select FIELDNAME from DICTCOL where TABLENAME = '''+@baseName+''' order by FIELDNUM'
   execute absp_Util_GenInListString @columnList output, @sql
   set @columnList = ','+replace(@columnList,' ','')+','
   if(@debugFlag > 0)
   begin
      set @msgText = 'absp_Migr_GenReloadTableList: '+@columnList
      execute absp_MessageEx @msgText
   end

   -- if the table schema is NOT the same, then replace new column names with default values
   if(@cnt > 0)
   begin
      declare  currTmp  cursor dynamic for select FIELDNAME as FLD from #tmp1
      open currTmp
      fetch next from currTmp into @FldName
      while @@fetch_status = 0
      begin
         if not exists(select 1 from #tmp2 where FIELDNAME = @FldName)
         begin
            set @deftype = ''
            set @defval = ''
            set @repval = ''
            select @deftype = rtrim(ltrim(FIELDTYPE)), @defval = rtrim(ltrim(DEFAULTVAL))
                from DICTCOL
                where TABLENAME = @baseName
                and FIELDNAME = @FldName

            -- if type is string or blob, then set the default value if it exists
            -- else use an empty string
            if(@deftype = 'C' or @deftype = 'B')
            begin
               set @repval = isnull(@defval,'')
               -- account for NA
               if(@repval = '[N/A]')
               begin
                  set @repval = ''
               end
               -- pre/post fix with quotes
               set @repval = ''''+ltrim(rtrim(@repval))+''''
            end
            else
            begin
               -- if type is a number, then set the default value if it exists
               -- else use a zero
               set @repval = isnull(@defval,'0')
               if(@repval = '[N/A]' or @repval = '')
               begin
                  set @repval = '0'
               end
            end

            -- pre/post with commas to avoid replacing a substring
            set @repval = ','+ltrim(rtrim(@repval))+','
            set @repfld = ','+ltrim(rtrim(@FldName))+','
            if(@debugFlag > 0)
            begin
               set @msgText = 'absp_Migr_GenReloadTableList Before: '+@columnList
               execute absp_MessageEx @msgText
            end
            set @columnList = replace(@columnList,ltrim(rtrim(@repfld)),ltrim(rtrim(@repval)))
         end
         fetch next from currTmp into @FldName
      end
      close currTmp
      deallocate currTmp
   end

   drop table #tmp1
   drop table #tmp2

   -- strip the @columnList of pre/post commas
   set @columnList = substring(@columnList,2,len(ltrim(rtrim(@columnList))) -2)
   if(@debugFlag > 0)
   begin
      set @msgText = 'absp_Migr_GenReloadTableList Final: '+@columnList
      execute absp_MessageEx @msgText
   end
   set @ret_ColList = @columnList

end
