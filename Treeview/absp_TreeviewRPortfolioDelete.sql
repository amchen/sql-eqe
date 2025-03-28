if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewRPortfolioDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_TreeviewRPortfolioDelete
end
go

create procedure dbo.absp_TreeviewRPortfolioDelete @parentNodeKey int ,@parentNodeType int ,@rportKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

The logical delete is performed here by setting the STATUS to DELETED.
The	real delete is performed as a background process.

In case the rport has been paste linked, only the rport map is removed.


Returns:       It returns nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey ^^  The key of the parent node for which the rport is to be deleted.
##PD  @parentNodeType ^^  The parent node type for which the rport is to be deleted.
##PD  @rportKey ^^ The key of the rport node that is to be deleted.

*/
as


begin
   set nocount on
   declare @cntRportkey int
   declare @cntRportkey2 int
   declare @sqlQuery varchar(max)
   declare @longname varchar(255)
   declare @rtroMapCnt int
   declare @rtroKey int
   declare @curs1_ChildKey int
   declare @curs1 cursor
   declare @curs2_rtroKey int
   declare @rtroKeyInList nvarchar(1000);
   declare @rportType int
   declare @dbName varchar(120)
   declare @cfRefKey int
      
   set @dbName =DB_NAME()
   select @cfRefKey = CF_REF_KEY from commondb.dbo.CFldrInfo where DB_NAME= @dbName;
   
  -- first we need to see if this is the only instance
   select   @cntRportkey = count(*)  from dbo.FLDRMAP where CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
   select   @cntRportkey2 = count(*)  from dbo.APORTMAP where CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
   if @cntRportkey+@cntRportkey2 = 1
   begin
    -- First mark all the underlying Programs as DELETED
      set @curs1 = cursor fast_forward local for select CHILD_KEY from dbo.RPORTMAP where RPORT_KEY = @rportKey and(RPORTMAP.CHILD_TYPE = 7 or RPORTMAP.CHILD_TYPE = 27)
      open @curs1
      fetch next from @curs1 into @curs1_ChildKey
      while @@fetch_status = 0
      begin
         execute dbo.absp_TreeviewProgramDelete @rportKey,@curs1_ChildKey
         fetch next from @curs1 into @curs1_ChildKey
      end
      close @curs1
      deallocate @curs1
    -- Remove the Map entry from the parent table
      if @parentNodeType = 0
      begin
         delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
      end
      else
      begin
         if @parentNodeType = 1
         begin
            delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
         end
      end
      -- Change the name to append the key since the user can create a node with the same name as deleted node
      select   @longname = LONGNAME  from dbo.RPRTINFO where RPORT_KEY = @rportKey
      if(len(ltrim(rtrim(@longname))) = 115)
      begin
         select   @longname = right(ltrim(rtrim(@longname)),110)
      end
      set @longname = ltrim(rtrim(@longname))+'_'+ str(@rportKey)
      -- mark the STATUS as DELETED
      update RPRTINFO set STATUS = 'DELETED', LONGNAME = ltrim(rtrim(@longname)) where RPORT_KEY = @rportKey
      
      -- insert the INFO record in Results Database
      exec absp_getDBName  @dbName out, @dbName, 0 -- Enclose within brackets--
      if RIGHT(rtrim(@dbName),4) != '_IR]'
      begin
        exec absp_getDBName  @dbName out, @dbName, 1
        set @sqlQuery = 'set identity_insert ' + @dbName + '..RPRTINFO on;'
        set @sqlQuery = @sqlQuery + 'insert into  ' + @dbName + '..RPRTINFO (RPORT_KEY, LONGNAME, STATUS) values (' + cast(@rportKey as char)+ ',' + cast(@rportKey as char)+', ''DELETED'' );'
        set @sqlQuery = @sqlQuery + 'set identity_insert ' + @dbName + '..RPRTINFO off'
        execute (@sqlQuery)
      end
      
      update ELTSummary set STATUS = 'DELETED' where (NodeType = 3 or NodeType = 23) and NodeKey = @rportKey
   end
   else
   begin
    -- if > 1 then just delete from map
      if @parentNodeType = 0
      begin
         delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
      end
      else
      begin
         if @parentNodeType = 1
         begin
            delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
         end
      end
   end
  -- SDG__00016507 -- Deleting a portfolio does not delete entries from RTROMAP
   if @parentNodeType = 1
   begin
   
       -- SDG__00018285 - Deleting a paste link pport under an APORT causes all other APORTS using this portfolio to lose its treaty link
   
       -- get the retroInfo keys of all retro treaties under the Aport.
       set @sqlQuery = 'select RTRO_KEY from dbo.RTROINFO where PARENT_KEY = ' + str(@parentNodeKey) + ' and PARENT_TYP = ' + str(@parentNodeType);
       exec dbo.absp_Util_GenInList @rtroKeyInList Output, @sqlQuery
   
      set @sqlQuery = 'select RTRO_KEY from dbo.RTROMAP where CHILD_APLY = ' + str(@rportKey) + ' and(CHILD_TYPE = 3 or CHILD_TYPE = 23) and rtro_key in (' + ( Replace(Replace(@rtroKeyInList,'in (', ''),')', '')) + ')'
      exec('declare curs2_rpt cursor fast_forward global for '+@sqlQuery)      
      open curs2_rpt
      fetch next from curs2_rpt into @curs2_rtroKey
      while @@fetch_status = 0
      begin
         set @rtroKey = @curs2_rtroKey
         select   @rtroMapCnt = count(*)  from dbo.RTROMAP where RTRO_KEY = @rtroKey
         if @rtroMapCnt = 1
         begin
            update RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
         end
         else
         begin
            delete from dbo.RTROMAP where rtro_key = @rtroKey and CHILD_APLY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
         end
         fetch next from curs2_rpt into @curs2_rtroKey
      end
      close curs2_rpt
      deallocate curs2_rpt	      
   end

   	--Delete DownloadInfo entries for this node--
	Delete from commondb..DownloadInfo where RportKey=@rportKey and NodeType=23 and DBRefKey=@cfRefKey
	Delete from commondb..TaskInfo where RportKey=@rportKey and NodeType=23 and DBRefKey=@cfRefKey

end
