
if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewProgramPartsClone') and objectproperty(ID,N'isprocedure') = 1)
begin;
   drop procedure dbo.absp_TreeviewProgramPartsClone;
end;
go

create procedure dbo.absp_TreeviewProgramPartsClone @oldProgKey int,
                                                    @newProgKey int,                                                
                                                    @resultsFlag int = 0 ,
                                                    @temp_Prog_Table varchar(120) = '',
                                                    @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones all the program parts for a given program key. It inserts clone records in the
tables storing the inuring cover details, file information, analysis results, exposure completion
times and intermediate results (if required) for the given program.

Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldProgKey ^^  The key of the program whose parts are to be cloned.
##PD  @newProgKey ^^  The new program key that is assigned to the new program parts.
##PD  @resultsFlag ^^  A flag to indicate whether the intermediate results are to be cloned or not.

*/
as;


BEGIN TRY;
  -- clones all the child parts of a Program
   set nocount on;

   declare @whereClause varchar(max);
   declare @progkeyTrio varchar(max);
   declare @whereClause2 varchar(max);
   declare @progkeyTrio2 varchar(max);
   declare @whereClause3 varchar(max);
   declare @progkeyTrio3 varchar(max);
   declare @fieldNames varchar(max);
   declare @replNames varchar(max);
   declare @myTableName char(12);
   declare @newInurKey int;
   declare @newLayrKey int;
   declare @newFileKey int;
   declare @sql nvarchar(max);
   declare @sSql nvarchar(max);
   declare @tabSep char(10);
   declare @temp_Table_Exists int;
   declare @TblExists int;
   declare @cursInur_IKey int;
   declare @cursInurLayr_ILayrKey int;
   declare @cursDictTbl_tname char(10);
   declare @curs1DictTbl_tblname char(10);
   declare @progType int;
   declare @targetIRDB varchar(130);

   set @TblExists = 0;

   if @targetDB=''
   	set @targetDB = DB_NAME();

   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB;

   execute absp_getDBName @targetIRDB out, @targetDB, 1;

   if (charindex('_IR',dbo.trim(DB_NAME())) = 0)
   begin;
   	set @sql = 'execute @TblExists = ' + @targetDB + '..absp_Util_CheckIfTableExists ''' + dbo.trim(@temp_Prog_Table) + '''';
   	execute sp_executesql @sql, N'@TblExists int output', @TblExists output;
   end;

   select   @temp_Table_Exists = @TblExists;
   execute dbo.absp_GenericTableCloneSeparator @tabSep output;

  -- these are used over and over
   set @whereClause = ' PROG_KEY = '+cast(@oldProgKey as char);
   set @progkeyTrio = 'INT'+@tabSep+' PROG_KEY '+@tabSep+cast(@newProgKey as char);
  -- the first thing we have to do is copy inurinfo

    -- get each inur_key we need to clone
   declare cursInurInfo  cursor fast_forward for select INUR_KEY  from dbo.INURINFO where  PROG_KEY = @oldProgKey;
   open cursInurInfo;
   fetch next from cursInurInfo into @cursInur_IKey;
   while @@fetch_status = 0
   begin;
      set @whereClause = ' PROG_KEY = '+cast(@oldProgKey as char)+' and MT.INUR_KEY = '+cast(@cursInur_IKey as char);

    -- clones the old inur_key to a new one
      execute @newInurKey = dbo.absp_GenericTableCloneRecords 'INURINFO',1,@whereClause,@progkeyTrio,0,@targetDB;

    -- now for each layr associated with that inur_key
      declare cursInurLayr  cursor fast_forward for select INLAYR_KEY from dbo.INURLAYR where INUR_KEY = @cursInur_IKey;
      open cursInurLayr;
      fetch next from cursInurLayr into @cursInurLayr_ILayrKey;
      while @@fetch_status = 0
      begin;
         set @whereClause2 = 'INLAYR_KEY = '+cast(@cursInurLayr_ILayrKey as char);
         set @progkeyTrio2 = 'INT'+@tabSep+' INUR_KEY '+@tabSep+cast(@newInurKey as char);
      -- change over the INUR_KEY


         execute @newLayrKey = dbo.absp_GenericTableCloneRecords 'INURLAYR',1,@whereClause2,@progkeyTrio2,0,@targetDB;

      -- now for each layer we have to clone the pieces
         set @whereClause3 = 'INLAYR_KEY = '+cast(@cursInurLayr_ILayrKey as char);
         set @progkeyTrio3 = 'INT'+@tabSep+' INUR_KEY '+@tabSep+cast(@newInurKey as char)+@tabSep+'INT'+@tabSep+' INLAYR_KEY '+@tabSep+cast(@newLayrKey as char);
      -- change over the INUR_KEY an layr_key
        -- execute dbo.absp_GenericTableCloneRecords 'INURTRIG',1,@whereClause3,@progkeyTrio3,0,@targetDB;
         execute dbo.absp_GenericTableCloneRecords 'INUREXCL',1,@whereClause3,@progkeyTrio3,0,@targetDB;

      -- At this point, LineofBusiness on the target database has been populated with resolved lookup IDs and tags
      -- clone InurLineOfBusiness Table with new InLayerKey and new LineofBusinessID based on the matching LOB tag Name

      set @sql = 'begin transaction; insert into ' + @targetDB + '.dbo.InurLineOfBusiness ' +
                  'select ' + rtrim(str(@newLayrKey)) + ' as InLayerKey, l2.LineOfBusinessID ' + 
                  'from ( ' + @targetDB + '.dbo.LineOfBusiness l2 join LineOfBusiness l1 on l2.Name = l1.Name) ' +
                  'join InurLineOfBusiness il1 on il1.LineOfBusinessID = l1.LineOfBusinessID ' +
                  'where il1.InLayerKey = ' + rtrim(str(@cursInurLayr_ILayrKey))+'; commit transaction; '
      --print @sql
      execute(@sql)           

         
         fetch next from cursInurLayr into @cursInurLayr_ILayrKey;
      end;
      close cursInurLayr;
      deallocate cursInurLayr;

    -- the zero =all_layers= options
      set @whereClause3 = 'INLAYR_KEY = 0 AND MT.INUR_KEY = '+cast(@cursInur_IKey as char);
      set @progkeyTrio3 = 'INT'+@tabSep+' INUR_KEY '+@tabSep+cast(@newInurKey as char)+@tabSep+'INT'+@tabSep+' INLAYR_KEY '+@tabSep+cast(0 as char);
     -- execute dbo.absp_GenericTableCloneRecords 'INURTRIG',1,@whereClause3,@progkeyTrio3,0,@targetDB;
      execute dbo.absp_GenericTableCloneRecords 'INUREXCL',1,@whereClause3,@progkeyTrio3,0,@targetDB;
      fetch next from cursInurInfo into @cursInur_IKey;
   end;
   close cursInurInfo;
   deallocate cursInurInfo;

   -- Exposure Summary tables
   set @progkeyTrio = 'INT'+@tabSep+' PROG_KEY'+@tabSep+cast(@newProgKey as char);

   -- EXPDONE table
   --set @whereClause = ' PPORT_KEY = 0 and PROG_KEY = '+cast(@oldProgKey as char);
   --execute dbo.absp_GenericTableCloneRecords 'EXPDONE',0,@whereClause,@progkeyTrio,0,@targetDB;

  -- SDG__00011484/SDG__00009292 clone intermediate results if resultsFlag is true
  -- SDG__00011777 add EVENT* tables

   if @resultsFlag <> 0 and @temp_Table_Exists = 0
   begin;
      set @whereClause = ' PROG_KEY = '+cast(@oldProgKey as char);
      declare curs1DictTbl cursor fast_forward for select TABLENAME from dbo.absp_Util_GetTableList('Program.ProgKey+Ebe.Rport.Blob');
      open curs1DictTbl;
      fetch next from curs1DictTbl into @curs1DictTbl_tblname;
      while @@fetch_status = 0
      begin;

         execute dbo.absp_GenericTableCloneRecords @curs1DictTbl_tblname,0,@whereClause,@progkeyTrio,0,@targetDB;
         execute dbo.absp_GenericTableCloneRecords @curs1DictTbl_tblname,0,@whereClause,@progkeyTrio,0,@targetIRDB;
         
 

         fetch next from curs1DictTbl into @curs1DictTbl_tblname;
      end;
      close curs1DictTbl;
      deallocate  curs1DictTbl;
   end;
   else
   begin;
      if @resultsFlag <> 0 and @temp_Table_Exists = 1
      begin;
         set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..' +@temp_Prog_Table+' set TARGET_PROG_KEY = '+str(@newProgKey)+' where SRC_PROG_KEY = '+str(@oldProgKey) + ' commit transaction; ';
         execute sp_executesql @sql, N'@temp_Prog_Table varchar(70),@newProgKey int,@oldProgKey int', @temp_Prog_Table = @temp_Prog_Table, @newProgKey = @newProgKey ,@oldProgKey=@oldProgKey;
      end;
   end;
END TRY
BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH