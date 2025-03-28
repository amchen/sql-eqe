if exists ( select 1 from sysobjects where name =  'absp_Test_BlobCount' and type = 'P' )
begin
    drop procedure absp_Test_BlobCount ;
end
Go
create procedure absp_Test_BlobCount @resetFlag BIT = 0
AS
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
===============================================================================================================
DB Version:    MSSQL
Purpose:

    This procedure this will create a counts table and stick blob table counts from master + results into it.

Returns : Returns 0.

================================================================================================================

</pre>
</font>
##BD_END

##PD  @resetFlag ^^ Given reset flag, which will decide whether the table 'BLOBCNTS' should dropped or not

##RD  @retVal  ^^ Returns 0.
*/
begin

   declare @sSql varchar(max)
   declare @sSql2 varchar(max)
   declare @sSql3 varchar(max)
   declare @retVal int
   declare @cnt int
   declare @resultCnt int
   declare @fieldMaster char(14)
   declare @fieldResults char(14)
   declare @tableName char(120)
   declare @fieldName char(120)
   declare @tblname_delctrl1 char(120)
   declare @keyname_delctrl1 char(120)
   declare @tblname_delctrl2 char(120)
   declare @keyname_delctrl2 char(120)
   declare @xtrawhere_delctrl char(254)
   declare lp1  cursor dynamic  for select  rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(KEYNAME)) as KN,rtrim(ltrim(EXTRAWHERE)) as XW from DELCTRL where BLOB_DB = 'R' order by KEYNAME asc,TABLENAME asc
   declare @sqlQry varchar(2000)
   declare @sSql4 varchar(4000)
   declare @mode int
   declare @IR_DBName varchar(2000)

   
   if @resetFlag = 1
   begin
        if Exists(select 1 from sysobjects where name = 'BLOBCNTS' and type = 'U')
            begin
                drop table BLOBCNTS
            end
   end
   if Exists(select 1 from sysobjects where name = 'BLOBCNTS' and type = 'U')
       begin
            create table BLOBCNTS
                (
                      TABLENAME CHAR(120)   null,
                      FIELDNAME CHAR(120)   null

                )

             insert into BLOBCNTS
                                select  rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(KEYNAME)) as KN
                                from DELCTRL where BLOB_DB = 'R'
                                order by KEYNAME asc,TABLENAME asc
        end

      select @cnt =  max ( ( sys.syscolumns.colid - 1 ) / 2 ) + 1
      from sys.syscolumns join sysobjects on sys.syscolumns.id = sysobjects.id
      where sysobjects.name = 'BLOBCNTS'

    if @cnt > 25
         begin
              set @retVal = -1
              return @retVal
         end

      set @fieldMaster = 'RUN'+rtrim(ltrim(str(@cnt)))+'_MSTR'
      set @fieldResults = 'RUN'+rtrim(ltrim(str(@cnt)))+'_RSLT'
      set @sqlQry =' alter table BLOBCNTS add '+ @fieldMaster + ' integer '
      execute (@sqlQry)
      set @sqlQry ='alter table BLOBCNTS add '+@fieldResults+' integer'
      execute (@sqlQry)

      open lp1

         fetch next from lp1 into @tblname_delctrl2, @keyname_delctrl2, @xtrawhere_delctrl
         while @@FETCH_STATUS = 0
         begin

                set @tableName = @tblname_delctrl2
                set @fieldName = @keyname_delctrl2
                print @tableName  + '  ' + @fieldName
                set @sSql3 = 'select  count ( * )  from ' + ltrim(rtrim(@tableName)) + ' where ' + ltrim(rtrim(@fieldName)) + ' > 0 ' + ltrim(rtrim(@xtrawhere_delctrl))
                set @sqlQry = 'update BLOBCNTS set ' + @fieldMaster + ' = (' + @sSql3 + ') where TABLENAME = ' + '''' + @tableName + ''''
                execute (@sqlQry)
                begin
                     exec @mode=absp_Util_IsSingleDB
                     if @mode=0
                     begin
                           set @IR_DBName = DB_NAME() + '_IR'

                           set @sSql4 = 'select count ( * ) from ' + @IR_DBName + '..' + dbo.trim(@tableName) + 
                                     ' where ' + dbo.trim(@fieldName) + ' > 0 ' +  dbo.trim(@xtrawhere_delctrl)
                     end
                     else
                           set @sSql4 = 'select * from openquery(resultdb,'''+ ltrim(rtrim(@sSql3)) +''')'

                        execute('declare curs0 cursor fast_forward global for '+ @sSql4)
                        open curs0
                        fetch next from curs0 into @resultCnt
                        while @@FETCH_STATUS =0
                        begin
                            set @sqlQry = 'update BLOBCNTS set '+ @fieldResults + ' = ' + rtrim(ltrim(str(@resultCnt)))+ ' where TABLENAME = ' + ''''+ @tableName + ''''
                            execute (@sqlQry)
                            fetch next from curs0 into @resultCnt
                        end
                        close curs0
                        deallocate curs0
               end
              fetch next from  lp1 into @tblname_delctrl2,@keyname_delctrl2,@xtrawhere_delctrl
        end

   close lp1
   deallocate lp1
   set @retVal = 0
   return @retVal
end


