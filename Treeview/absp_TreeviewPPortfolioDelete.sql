if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewPPortfolioDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure dbo.absp_TreeviewPPortfolioDelete
end
go

create procedure dbo.absp_TreeviewPPortfolioDelete @parentNodeKey int ,@parentNodeType int ,@pportKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

The logical delete is performed here by setting the STATUS to DELETED.
The real delete is performed as a background process.

In case the pport has been paste linked, only the pport map is removed.


Returns:       It returns nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey 	^^  The key of the parent node for which the pport is to be deleted.
##PD  @parentNodeType 	^^  The parent node type for which the pport is to be deleted.
##PD  @pportKey 	^^ The key of the pport node that is to be deleted.

*/
as

begin
   set nocount on
   declare @cntPportkey int
   declare @exposure_Key int
   declare @cntPportkey2 int
   declare @sqlQuery varchar(max)
   declare @longName char(255)
   declare @rtroMapCnt int
   declare @rtroKey int
   declare @rtroKeyInList varchar(max);
   declare @curs cursor
   declare @curs1_ChildKey int
   declare @curs1 cursor
   declare @curs2_rtroKey int
   declare @curs2 cursor
   declare @sql	nvarchar(4000)
   declare @dbName varchar(120)
   declare @cfRefKey int
      
   set @dbName =DB_NAME()
   select @cfRefKey = CF_REF_KEY from commondb.dbo.CFldrInfo where DB_NAME= @dbName;
   
  -- first we need to see if this is the only instance
   select   @cntPportkey = count(*)  from dbo.FLDRMAP where CHILD_KEY = @pportKey and CHILD_TYPE = 2
   select   @cntPportkey2 = count(*)  from dbo.APORTMAP where CHILD_KEY = @pportKey and CHILD_TYPE = 2
   if @cntPportkey + @cntPportkey2 = 1
   begin
      
      --Mark ExposureInfo records as DELETED--
      set @curs = cursor fast_forward for select ExposureKey from ExposureMap where ParentKey = @pportKey and ParentType = 2
      open @curs
      fetch next from @curs into @exposure_Key
      while @@fetch_status = 0
      begin
          execute absp_TreeviewExposureDelete @exposure_Key,@pportKey,2
          fetch next from @curs into @exposure_Key
      end
      close @curs
      deallocate @curs
      
      
    -- Remove the Map entry from the parent table
      if @parentNodeType = 0
      begin
         delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
      end
      else
      begin
         if @parentNodeType = 1
         begin
            delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
         end
      end
      
    -- Change the name to append the key since the user can create a node with the same name as deleted node

      select   @longName = LONGNAME  from dbo.PPRTINFO where PPORT_KEY = @pportKey
      if(len(ltrim(rtrim(@longName))) = 115)
      begin
         select   @longName = right(ltrim(rtrim(@longName)),110)
      end
      set @longName = ltrim(rtrim(@longName))+ '_' + str(@pportKey)

    -- mark the STATUS as DELETED
      update PPRTINFO set STATUS = 'DELETED', LONGNAME = ltrim(rtrim(@longName)) where PPORT_KEY = @pportKey
    
      -- insert the INFO record in Results Database
      	exec absp_getDBName  @dbName out, @dbName, 0 -- Enclose within brackets--
        if RIGHT(rtrim(@dbName),4) != '_IR]'
        begin
          exec absp_getDBName  @dbName out, @dbName, 1
          set @sqlQuery = 'set identity_insert ' + @dbName + '..PPRTINFO on;'
          set @sqlQuery = @sqlQuery + 'insert into  ' + @dbName + '..PPRTINFO (PPORT_KEY,LONGNAME, STATUS) values (' + dbo.trim(cast(@pportKey as char))+ ',' + dbo.trim(cast(@pportKey as char))+', ''DELETED'' );'
          set @sqlQuery = @sqlQuery + 'set identity_insert  ' + @dbName + '..PPRTINFO off'
          execute (@sqlQuery)
        end

        update ELTSummary set STATUS = 'DELETED' where NodeType = 2 and NodeKey = @pportKey
   end
  
   else
   begin
    -- if &gt; 1 then just delete from map
      if @parentNodeType = 0
      begin
         delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
      end
      else
      begin
         if @parentNodeType = 1
         begin
            delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @pportKey and CHILD_TYPE = 2
         end
      end
   end

  -- SDG__00016507 -- Deleting a portfolio does not delete entries from RTROMAP
   if @parentNodeType = 1
   begin
---------------------------------------------------------
  -- SDG__00018285 - Deleting a paste link pport under an APORT causes all other APORTS using this portfolio to lose its treaty link
   --get the retroInfo keys of all retro treaties under the Aport.
	set @sqlQuery = 'select RTRO_KEY from dbo.RTROINFO where PARENT_KEY = ' + str(@parentNodeKey) + ' and PARENT_TYP = ' + str(@parentNodeType);
	exec absp_Util_GenInList @rtroKeyInList output, @sqlQuery;
	set @sqlQuery = 'select RTRO_KEY from dbo.RTROMAP where CHILD_APLY = ' + str(@pportKey) + ' and CHILD_TYPE = 2 and RTRO_KEY ' + @rtroKeyInList;
------------------------------------------------------------

	  set @sql = 'SET @curs2 = cursor fast_forward for ' + @sqlQuery + ' open @curs2'
      --set @curs2 = cursor fast_forward for select RTRO_KEY from dbo.RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
      --open @curs2
      exec sp_executesql @sql, N'@curs2 cursor output', @curs2 output
      fetch next from @curs2 into @curs2_rtroKey
      while @@fetch_status = 0
      begin
         set @rtroKey = @curs2_rtroKey
         select   @rtroMapCnt = count(*)  from dbo.RTROMAP where RTRO_KEY = @rtroKey
         if @rtroMapCnt = 1
         begin
            update dbo.RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
         end
         else
         begin
            delete from dbo.RTROMAP where rtro_key = @rtroKey and CHILD_APLY = @pportKey and CHILD_TYPE = 2
         end
         fetch next from @curs2 into @curs2_rtroKey
      end
      close @curs2
      deallocate @curs2
   end
   --Drop exposure browser filter tables--
   if @cntPportkey + @cntPportkey2 = 1
	exec absp_DropExposureFilterTables @pportKey,2

	--Delete DownloadInfo entries for this node--
	Delete from commondb..DownloadInfo where PportKey=@pportKey and NodeType=2 and DBRefKey=@cfRefKey
	Delete from commondb..TaskInfo where PportKey=@pportKey and NodeType=2 and DBRefKey=@cfRefKey
end