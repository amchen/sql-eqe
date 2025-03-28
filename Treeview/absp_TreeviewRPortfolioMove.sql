if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewRPortfolioMove') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewRPortfolioMove
end
 go

create procedure 
absp_TreeviewRPortfolioMove @rportKey int ,@currentNodeKey int ,@currentNodeType int ,@newNodeKey int ,@newNodeType int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure moves a rport from one node to another.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The key of the rport node that is to be moved.
##PD  @currentNodeKey ^^  The key of the current parent of the rport that is to be moved.  
##PD  @currentNodeType ^^  The type of the current parent of the rport that is to be moved. 
##PD  @newNodeKey ^^  The key of the parent node under which the given rport is to be moved. 
##PD  @newNodeType ^^  The type of the parent node under which the given rport is to be moved. 
*/
as
begin
set nocount on
   declare @sql nvarchar(4000)
   declare @mapTable char(10)
   declare @mapKey char(10)
   declare @isThere int
   declare @fromCurrencyNodeKey int
   declare @toCurrencyNodeKey int
   declare @rtroMapCnt int
   declare @rtroKey int
   declare @rport_node_type int
   declare @curs2_rtroKey int   
   declare @curs3_rtroKey int
   
   execute @rport_node_type = absp_Util_GetRPortType @rportKey
   if @currentNodeType = 0
   begin

      set @mapTable = ' FLDRMAP'
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

    -- this procedure will move an RPortfolio to a new parent
    -- update the map
    -- already there"?"
       set @sql = 'select @isThere = count(*)  from '+ @mapTable + '  where '+ @mapKey + '  = ' + str(@newNodeKey) + ' and CHILD_KEY = '+ str(@rportKey) + ' and CHILD_TYPE =  ' + str(@rport_node_type)

      exec sp_executesql @sql, N'@isThere int output', @isThere output
      if @isThere = 0
      begin

         set @sql = 'update '+@mapTable+' set '+@mapKey+' = '+str(@newNodeKey)+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@rportKey)+' and CHILD_TYPE = '+str(@rport_node_type)
         execute (@sql)

         if @currentNodeType = 1
         begin
         declare curs2  cursor fast_forward  for 
               select  RTRO_KEY from RTROMAP where CHILD_APLY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
            open curs2
            fetch next from curs2 into @curs2_rtroKey
            while @@fetch_status = 0
            begin
               set @rtroKey = @curs2_rtroKey
               select  @rtroMapCnt = count(*)  from RTROMAP where RTRO_KEY = @rtroKey
               if @rtroMapCnt = 1
               begin
                  update RTROMAP set CHILD_APLY = 0,CHILD_TYPE = 0  where RTRO_KEY = @rtroKey
               end
               else
               begin
                  delete from RTROMAP where CHILD_APLY = @rportKey and CHILD_TYPE = @rport_node_type
               end
               fetch next from curs2 into @curs2_rtroKey
            end
            close curs2
            deallocate curs2
         end
      end
      else
      begin

        set @sql = 'delete from '+@mapTable+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@rportKey)+' and CHILD_TYPE = '+str(@rport_node_type)
        execute (@sql) 
         if @currentNodeType = 1
         begin
            delete from RTROMAP where RTRO_KEY = any(select  RTRO_KEY from RTROINFO where PARENT_KEY = @currentNodeKey)
              and  CHILD_APLY = @rportKey and CHILD_TYPE = @rport_node_type
         end
      end
   end
   else
   begin
        set @sql = 'delete from '+@mapTable+'  where '+@mapKey+'  = '+str(@currentNodeKey)+' and CHILD_KEY = '+str(@rportKey)+' and CHILD_TYPE = '+str(@rport_node_type)
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
       set @sql = 'select @isThere = count(*)  from '+@mapTable+'  where '+@mapKey+'  = '+str(@newNodeKey)+' and CHILD_KEY = '+str(@rportKey)+' and CHILD_TYPE = '+str(@rport_node_type)
	  exec sp_executesql @sql, N'@isThere int output', @isThere output
      if @isThere = 0
      begin

         set @sql = 'insert into '+@mapTable+'  values ( '+str(@newNodeKey)+' , '+str(@rportKey)+' , '+str(@rport_node_type)+') '
         execute (@sql)

      end
      if @currentNodeType = 1
      begin
      declare curs3  cursor fast_forward  for select  rtro_key from rtromap where CHILD_APLY = @rportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
         open curs3
         fetch next from curs3 into @curs3_rtroKey
         while @@fetch_status = 0
         begin
            set @rtroKey = @curs3_rtroKey
            select  @rtroMapCnt = count(*)  from rtromap where rtro_key = @rtroKey
            if @rtroMapCnt = 1
            begin
               update rtromap set CHILD_APLY = 0,CHILD_TYPE = 0  where rtro_key = @rtroKey
            end
            else
            begin
               delete from RTROMAP where CHILD_APLY = @rportKey and CHILD_TYPE = @rport_node_type
            end
            fetch next from curs3 into @curs3_rtroKey
         end
         close curs3
         deallocate curs3
         end
   end
  -- delete the reference rprt_key if we move the portfolio to a different currency node 
  -- if the portfolio is moved to different currency node then we need to set the REF_PPTKEY to 0.
   execute @fromCurrencyNodeKey = absp_FindNodeCurrencyKey @currentNodeKey,@currentNodeType
   execute @toCurrencyNodeKey = absp_FindNodeCurrencyKey @newNodeKey,@newNodeType
   if @fromCurrencyNodeKey <> @toCurrencyNodeKey
   begin
      update rprtinfo set ref_rptkey = 0  where ref_rptkey = @rportKey
      update rprtinfo set ref_rptkey = 0  where rport_key = @rportKey
   end


end



