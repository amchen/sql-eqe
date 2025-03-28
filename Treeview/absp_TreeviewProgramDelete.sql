if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewProgramDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_TreeviewProgramDelete
end
go

create procedure  dbo.absp_TreeviewProgramDelete  @rportKey int ,@progKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:

The logical delete is performed here by setting the STATUS to DELETED.
The	real delete is performed as a background process.

Returns:       It returns nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The key of the parent rport node for which the program node is to be deleted.
##PD  @progKey ^^  The program node key of the program that is to be deleted.

*/
as


BEGIN TRY
   set nocount on;
   declare @cntProgkey int;
   declare @exposure_Key int;
   declare @sqlQuery varchar(max);
   declare @longname varchar(255);
   declare @curs1_CaseKey int;
   declare @curs1 cursor;
   declare @curs2_lportKey int;
   declare @progType int;
   declare @curs2 cursor;
   declare @curs cursor;
   declare @dbName varchar(120);
   declare @irDBName varchar(max)
   declare @sql varchar(max)
   declare @cfRefKey int

   set @dbName =DB_NAME();
   select @cfRefKey = CF_REF_KEY from commondb.dbo.CFldrInfo where DB_NAME= @dbName
   set @irDBName = '';
   exec absp_getDBName  @irDBName out, @dbName, 1;

  -- first we need to see if this is the only instance
   select   @cntProgkey = count(*)  from dbo.RPORTMAP where CHILD_KEY = @progKey and CHILD_TYPE = 27
   if @cntProgkey = 1
   begin
    -- first we need mark all underlying cases as DELETED
      set @curs1 = cursor fast_forward for select CASE_KEY from dbo.CASEINFO where PROG_KEY = @progKey
      open @curs1
      fetch next from @curs1 into @curs1_CaseKey
      while @@fetch_status = 0
      begin
         execute dbo.absp_TreeviewCaseDelete @progKey,@curs1_CaseKey,1
         fetch next from @curs1 into @curs1_CaseKey
      end
      close @curs1
      deallocate @curs1

      -- Remove the Map entry from the parent table
      delete from dbo.RPORTMAP where RPORT_KEY = @rportKey and CHILD_KEY = @progKey and CHILD_TYPE = 27

	--Mark ExposureInfo records as DELETED--
      set @curs = cursor fast_forward for select ExposureKey,ParentType from ExposureMap where ParentKey = @progKey and ParentType =27
      open @curs
      fetch next from @curs into @exposure_Key,@progType
      while @@fetch_status = 0
      begin
          execute absp_TreeviewExposureDelete @exposure_Key,@progKey, @progType
          fetch next from @curs into @exposure_Key,@progType
      end
      close @curs
      deallocate @curs

      -- Change the name to append the key since the user can create a node with the same name as deleted node
      select   @longname = LONGNAME  from dbo.PROGINFO where PROG_KEY = @progKey
      if(len(ltrim(rtrim(@longname))) = 115)
      begin
         select   @longname = right(ltrim(rtrim(@longname)),110)
      end
      set @longname = ltrim(rtrim(@longname))+'_'+str(@progKey)

      -- mark the STATUS as DELETED
      update PROGINFO set STATUS = 'DELETED', LONGNAME = rtrim(ltrim(@longname)) where PROG_KEY = @progKey;

      -- In INTRDONEA table the ExposureKey stores the PROGINFO as a negative key. Since we overloaded the column
      -- we cannot delete the entries of INTRDONEA (for Program) using DELCTRL hence we need to do it here.

      set @sql = 'delete ' + @irDBName + '..IntrDoneA where Exposurekey = -' + cast(@progKey as varchar(30));
      execute (@sql);

      -- insert the INFO record in Results Database
       	exec absp_getDBName  @dbName out, @dbName, 0 -- Enclose within brackets--

        if RIGHT(rtrim(@dbName),4) != '_IR]'
        begin
          exec absp_getDBName  @dbName out, @dbName, 1
          set @sqlQuery = 'set identity_insert ' + @dbName + '..PROGINFO on;'
          set @sqlQuery = @sqlQuery + 'insert into  ' + @dbName + '..PROGINFO (PROG_KEY,LONGNAME, STATUS) values (' + dbo.trim(cast(@progKey as char))+ ',' + dbo.trim(cast(@progKey as char))+', ''DELETED'' );'
          set @sqlQuery = @sqlQuery + 'set identity_insert  ' + @dbName + '..PROGINFO off'
          execute (@sqlQuery)
        end

      update ELTSummary set STATUS = 'DELETED' where NodeType = 27 and NodeKey = @progKey;
   end
   else
   begin
    -- if > 1 then just delete from map
      delete from dbo.RPORTMAP where RPORT_KEY = @rportKey and CHILD_KEY = @progKey and CHILD_TYPE = 27
   end
   
   --Drop exposure browser filter tables--
   if @cntProgkey = 1
  	 exec absp_DropExposureFilterTables @progKey,27

	--Delete DownloadInfo entries for this node--
	Delete from commondb..DownloadInfo where ProgramKey=@progKey and NodeType=27 and DBRefKey=@cfRefKey
	Delete from commondb..TaskInfo where ProgramKey=@progKey and NodeType=27 and DBRefKey=@cfRefKey

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
