if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewPPortfolioMove') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewPPortfolioMove
end
 go

create procedure 
absp_TreeviewPPortfolioMove  @pportKey int ,@currentNodeKey int ,@currentNodeType int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure moves a pport from one node to another.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @pportKey ^^  The key of the pport node that is to be moved.
##PD  @currentNodeKey ^^  The key of the current parent of the pport that is to be moved.  
##PD  @currentNodeType ^^  The type of the current parent of the pport that is to be moved. 
##PD  @newNodeKey ^^  The key of the parent node under which the given pport is to be moved. 
##PD  @newNodeType ^^  The type of the parent node under which the given pport is to be moved. 


*/
as
begin
  set nocount on
   declare @sql nvarchar(4000)
   declare @mapTable char(10)
   declare @mapKey char(10)
   declare @isThere int
   declare @toCurrencyNodeKey int
   declare @fromCurrencyNodeKey int
   declare @rtroMapCnt int
   declare @rtroKey int
   declare @curs4_rtroKey int
   declare @curs2_rtroKey int 
   declare @curs3_rtroKey int
   
   if @currentNodeType = 0
   begin
      set @mapTable = 'FLDRMAP'
      set @mapKey = 'FOLDER_KEY'
   end
   else
   begin
      if @currentNodeType = 1
      begin
         set @mapTable = 'APORTMAP'
         set @mapKey = 'APORT_KEY'
      end
   end
   if @currentNodeType = @newNodeType
   begin
    -- this procedure will move a PPortfolio to a new parent
    -- update the map
    -- already there"?"
      
     set @sql = 'select @isThere = count(*) from '+ @mapTable + '  where '+@mapKey+'  = '+str(@newNodeKey)+' and CHILD_KEY = '+str(@pportKey)+' and CHILD_TYPE = 2 '
     exec sp_executesql @sql, N'@isThere int output', @isThere output 
      if @isThere = 0
      begin
    	 set @sql = 'update '+@mapTable+' set '+@mapKey+' = '+str(@newNodeKey)+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@pportKey)+' and CHILD_TYPE = 2 '
 	 execute (@sql)
         if @currentNodeType = 1
         begin
            declare curs4  cursor fast_forward  for select  RTRO_KEY from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
            open curs4
            fetch next from curs4 into @curs4_rtroKey
            while @@fetch_status = 0
            begin
               set @rtroKey = @curs4_rtroKey
               select  @rtroMapCnt = count(*)  from RTROMAP where rtro_key = @rtroKey
               if @rtroMapCnt = 1
               begin
                  update RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
               end
               else
               begin
                  delete from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
               end
               fetch next from curs4 into @curs4_rtroKey
            end
            close curs4
            deallocate curs4
   
         end
     end
      else
      begin
         set @sql = 'delete from '+@mapTable+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@pportKey)+' and CHILD_TYPE = 2 '
	 execute (@sql)
         if @currentNodeType = 1
         begin
            declare curs2  cursor fast_forward  for select  rtro_key from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
            open curs2
            fetch next from curs2 into @curs2_rtroKey
            while @@fetch_status = 0
            begin
               set @rtroKey = @curs4_rtroKey
               select  @rtroMapCnt = count(*)  from rtromap where rtro_key = @rtroKey
               if @rtroMapCnt = 1
               begin
                  update RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
               end
               else
               begin
                  delete from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
               end
               fetch next from curs2 into @curs2_rtroKey
            end
            close curs2
            deallocate curs2
         end
      end
   end
   else
   begin
        set @sql = 'delete from '+@mapTable+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@pportKey)+' and CHILD_TYPE = 2 '
	execute (@sql)	
	
      if @newNodeType = 0
      begin
         set @mapTable = ' FLDRMAP'
         set @mapKey = 'FOLDER_KEY'
      end
      else
      begin
         if @newNodeType = 1
         begin
            set @mapTable = 'APORTMAP'
            set @mapKey = 'APORT_KEY'
         end
      end -- already there"?"
      set @sql = 'select @isThere =  count(*) from ' + @mapTable+'  where ' + @mapKey+ '  = ' + str(@newNodeKey)+' and CHILD_KEY = ' + str(@pportKey)+' and CHILD_TYPE = 2 '
      exec sp_executesql @sql,  N'@isThere int output', @isThere output 
      if @isThere = 0
      begin
      	set @sql = 'insert into '+@mapTable+'  values ( '+str(@newNodeKey)+' , '+str(@pportKey)+' , 2) '
	execute (@sql)
      end
      if @currentNodeType = 1
      begin
         declare curs3  cursor fast_forward  for select  RTRO_KEY from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
         open curs3
         fetch next from curs3 into @curs3_rtroKey
         while @@fetch_status = 0
         begin
	    set @rtroKey = @curs3_rtroKey
            select  @rtroMapCnt = count(*)  from rtromap where rtro_key = @rtroKey
            if @rtroMapCnt = 1
            begin
               update RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
            end
            else
            begin
               delete from RTROMAP where CHILD_APLY = @pportKey and CHILD_TYPE = 2
            end
            fetch next from curs3 into @curs3_rtroKey
         end
         close curs3
         deallocate curs3
       end
   end
  -- if the portfolio is moved to different currency node then we need to set the REF_PPTKEY to 0.
   execute @fromCurrencyNodeKey = absp_FindNodeCurrencyKey @currentNodeKey,@currentNodeType
   execute @toCurrencyNodeKey = absp_FindNodeCurrencyKey @newNodeKey,@newNodeType
   if @fromCurrencyNodeKey <> @toCurrencyNodeKey
   begin
      update pprtinfo set ref_pptkey = 0  where ref_pptkey = @pportKey
      update pprtinfo set ref_pptkey = 0  where @pportKey = @pportKey
   end
   

end




