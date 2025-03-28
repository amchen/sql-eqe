if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CopyBaseToTmpTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CopyBaseToTmpTable
end

go

create procedure absp_Util_CopyBaseToTmpTable @baseTableName CHAR(120) ,@tmpTableName CHAR(120) ,@keyFieldName CHAR(120) = '' ,@keyFieldValue CHAR(254) = '' ,@forceDeleteFlag BIT = 0 ,@additonalWhereClause varchar(max) = '' ,@useTmpTableAsBase BIT = 0 ,@display INT = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates an existing temporary table from a base table depending on the specified condition and 
returns the status in an OUTPUT parameter.
1 when data is copied successfully from base to temporary table.
-1 when the base table name is same as the temporary table name.
-2 when base table is not found.
-3 when temporary table is not found.
-4 when keyFieldName is such that the corresponding field type is a blob.

Returns: An integer value
	  1 when data is copied successfully from base to temporary table.
	 -1 when the base table name is same as the temporary table name.
	 -2 when base table is not found.
	 -3 when temporary table is not found.
	 -4 when keyFieldName is such that the corresponding field type is a blob.


====================================================================================================
</pre>
</font>
##BD_END 


##PD  baseTableName ^^  The name of the base table
##PD  tmpTableName ^^ The name of the temp table.
##PD  keyFieldName ^^ A field name of the base table.
##PD  keyFieldValue ^^ A value of that keyField column.
##PD  forceDeleteFlag ^^ This flag is set to 1 if the existing data of the temp table is to be deleted before getting populated
##PD  additonalWhereClause ^^ A condition depending on which the temp table will be populated.
##PD  useTmpTableAsBase ^^ It is set to 1 if the tmp table needs to exist in DICTCOL.
##PD  display ^^ It set to an apppropriate integer value and is used for debugging(default it is set to 0).

##RD  ret_status ^^ Status is returned.

*/
as
begin

   set nocount on
   
  /*
  This will copy records from the base table to a temp table
  insert into tmpTable select * from baseTable where keyField = keyValue
  */
   declare @sSql varchar(max)
   declare @i int
   declare @fieldType char(1)
   declare @whereConnector char(8)
   declare @tableName char(120)
   declare @HasIdentity int
   declare @Sql1 varchar(max)
   declare @colNm varchar(max)
   declare @ret_status 			integer
   
   set @sSql = ''
   set @whereConnector = ' where '
   set @tableName = @baseTableName
   if @useTmpTableAsBase = 1
   begin
      set @tableName = @tmpTableName
   end
   if @display > 1
   begin
      print 'baseTableName = '+@baseTableName
      print 'tmpTableName = '+@tmpTableName
      print 'keyFieldName = '+@keyFieldName
      print 'keyFieldValue = '+@keyFieldValue
   end
   -- just in case he tries to do his own table, do not let him
   if rtrim(ltrim(@baseTableName)) = rtrim(ltrim(@tmpTableName))
   begin
      set @ret_status = -1
      return @ret_status
   end  -- -1same table
   if(select count(*) from sys.tables where name = @baseTableName) = 0
   begin
      set @ret_status = -2
      return @ret_status
   end  -- -1 missing source table
   if(select count(*) from sys.tables where name = @tmpTableName) = 0
   begin
      set @ret_status = -3
      return @ret_status
   end  -- -1 missing dest table
   -- begin our create SQL statement
     set @Sql1='Select NAME From SYS.SYSCOLUMNS Where object_name(id)=''' + rtrim(ltrim(@tmpTableName))  + ''''
     exec  absp_util_geninlist @ColNm output, @Sql1 , 'S',0
     set @sSql = @sSql + 'insert into '+ rtrim(ltrim(@tmpTableName))+ replace(substring(@colNm,4,len(@colNm)),'''','') + ' select * from '+@baseTableName

     -- see if we need the where clause
   if rtrim(ltrim(@keyFieldName)) <> ''
   begin
    -- we need to know the type
      select   @fieldType = case when FIELDTYPE = 'A' then 'N'
      when FIELDTYPE = 'B' then 'U'
      when FIELDTYPE = 'C' then 'C'
      when FIELDTYPE = 'F' then 'N'
      when FIELDTYPE = 'G' then 'N'
      when FIELDTYPE = 'I' then 'N'
      when FIELDTYPE = 'K' then 'N'
      when FIELDTYPE = 'S' then 'N'
      when FIELDTYPE = 'T' then 'C'
      when FIELDTYPE = 'V' then 'C'
      -- we need to do it differently based on type
    end  from DICTCOL where
      TABLENAME = rtrim(ltrim(@tableName)) and FIELDNAME = rtrim(ltrim(@keyFieldName))
      if @display > 3
      begin
         PRINT '@fieldType = '+@fieldType
      end
      set @sSql = @sSql+' where '+@keyFieldName+' = '
      if @fieldType = 'U'
      begin
         set @ret_status = -4
         return @ret_status
      end  -- illegal - you cannot do where on blob
      if @fieldType = 'N'
      begin
         set @sSql = @sSql+rtrim(ltrim(@keyFieldValue))
      end
      if @fieldType = 'C'
      begin
         set @sSql = @sSql+''''+@keyFieldValue+''''
      end
      set @whereConnector = ' and '
   end
   -- do we have an incoming where clause "?"
    if rtrim(ltrim(@additonalWhereClause)) <> ''
    begin
       set @sSql = @sSql+@whereConnector+@additonalWhereClause
    end
    -- see if we need to remove existing target records
    if @forceDeleteFlag = 1
    begin
     execute('delete '+@tmpTableName)
    end
    if @display > 0
    begin
      print 'about to do '
      print @sSql
    end
    -- do it
    Select @HasIdentity= isnull(objectproperty ( object_id(@tmpTableName) , 'TableHasIdentity' ) ,-1)
    If @HasIdentity = 1   
    begin
          set @sSql = 'set identity_insert '+ @tmpTableName + ' on ' + @sSql + ' set identity_insert '+ @tmpTableName + ' off '
    end
    execute(@sSql)
    set @ret_status = 1
    return @ret_status
end


