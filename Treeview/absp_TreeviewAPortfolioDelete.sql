if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewAPortfolioDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_TreeviewAPortfolioDelete
end
 go

create procedure dbo.absp_TreeviewAPortfolioDelete @parentNodeKey int ,@parentNodeType int ,@aportKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

The logical delete is performed here by setting the STATUS to DELETED.
The real delete is performed as a background process.

In case the aport has been paste linked, only the aport map is removed.


Returns:       It returns nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey ^^  The key of the parent node for which the aport is to be deleted.
##PD  @parentNodeType ^^  The parent node type for which the aport is to be deleted.
##PD  @aportKey ^^ The key of the aport node that is to be deleted

*/
as

begin
   set nocount on
   declare @cntAportkey int
   declare @cntAportkey2 int
   declare @sqlQuery varchar(max)
   declare @longname varchar(255)
   declare @CHILD_KEY1 int
   declare @CHILD_TYPE1 smallint
   declare @curs1 cursor
   declare @dbName varchar(120)
   declare @cfRefKey int
   
   set @dbName =DB_NAME()
   select @cfRefKey = CF_REF_KEY from commondb.dbo.CFldrInfo where DB_NAME= @dbName;
   
  -- first we need to see if this is the only instance
   select   @cntAportkey = count(*)  from dbo.FLDRMAP where CHILD_KEY = @aportKey and CHILD_TYPE = 1
   select   @cntAportkey2 = count(*)  from dbo.APORTMAP where CHILD_KEY = @aportKey and CHILD_TYPE = 1
   if @cntAportkey+@cntAportkey2 = 1
   begin
	-- first we need to delete all the underlying PPorts and RPorts
	set @curs1 = cursor fast_forward for select CHILD_KEY,CHILD_TYPE from dbo.APORTMAP where APORT_KEY = @aportKey
	open @curs1
	fetch next from @curs1 into @CHILD_KEY1,@CHILD_TYPE1
	while @@fetch_status = 0
	begin
		execute dbo.absp_TreeviewGenericNodeDelete @aportKey,1,@CHILD_KEY1,@CHILD_TYPE1
		fetch next from @curs1 into @CHILD_KEY1,@CHILD_TYPE1
	end
	close @curs1
	deallocate @curs1

	 --Remove the Map entry from the parent table
	if @parentNodeType = 0
	begin
		delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
	end
	else
	begin
		if @parentNodeType = 1
		begin
			delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
		end
	end

	 --Change the name to append the key since the user can create a node with the same name as deleted node
	select @longname = LONGNAME  from dbo.APRTINFO where APORT_KEY = @aportKey
	if(len(ltrim(rtrim(@longname))) = 115)
	begin
		select @longname = right(ltrim(rtrim(@longname)),110)
	end
	set @longname = ltrim(rtrim(@longname))+'_'+ str(@aportKey)

	-- mark the STATUS as DELETED
	update dbo.APRTINFO set STATUS = 'DELETED', LONGNAME = ltrim(rtrim(@longname)) where APORT_KEY = @aportKey

	-- insert the INFO record in Results Database
	exec absp_getDBName  @dbName out, @dbName, 0 -- Enclose within brackets--
	if RIGHT(rtrim(@dbName),4) != '_IR]'
	begin
    		exec absp_getDBName  @dbName out, @dbName, 1 
    		set @sqlQuery = 'set identity_insert ' + @dbName + '..APRTINFO on;'
    		set @sqlQuery = @sqlQuery + 'insert into  ' + @dbName + '..APRTINFO (APORT_KEY,LONGNAME, STATUS) values (' + dbo.trim(cast(@aportKey as char))+ ',' + dbo.trim(cast(@aportKey as char))+', ''DELETED'' );'
    		set @sqlQuery = @sqlQuery + 'set identity_insert  ' + @dbName + '..APRTINFO off'
    		execute (@sqlQuery)
	end
	
	-- Remove RTROMAP entries
        delete from dbo.RTROMAP from dbo.RTROINFO where RTROMAP.RTRO_KEY = RTROINFO.RTRO_KEY
              and RTROINFO.PARENT_KEY = @aportKey and RTROINFO.PARENT_TYP = 1
              
       update ELTSummary set STATUS = 'DELETED' where NodeType = 1 and NodeKey = @aportKey
   end
   
   else
   begin
	-- if >1 then just delete from map
	if @parentNodeType = 0
	begin
		delete from dbo.FLDRMAP where FOLDER_KEY = @parentNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
	end
	else
	begin
		if @parentNodeType = 1
		begin
			delete from dbo.APORTMAP where APORT_KEY = @parentNodeKey and CHILD_KEY = @aportKey and CHILD_TYPE = 1
		end
	end
   end
   
   	--Delete DownloadInfo entries for this node--
	Delete from commondb..DownloadInfo where AportKey=@aportKey and NodeType=1 and DBRefKey=@cfRefKey
	Delete from commondb..TaskInfo where AportKey=@aportKey and NodeType=1 and DBRefKey=@cfRefKey
   
end