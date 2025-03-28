if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_isChildofNode') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_isChildofNode
end
 go
create procedure absp_isChildofNode @nodeKey int,@nodeType int,@parentNodeKey int,@parentNodeType int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure is used to find if a specified node is the child of a specified node.
If nodeType = 8 (policy) or 9 (site), the nodeKey should be the portID.

Returns:       A single value @lastcode
1. @lastcode = -1, the parent node specified is not the actual parent of the specified child node.
2. @lastcode &gt; 0, the node key of the parent node, signifying the parent node specified is the actual parent of the specified child node. 
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node for which the parent node needs to be identified. 
##PD  @nodeType ^^  The type of the node for which the parent node needs to be identified.
##PD  @parentNodeKey ^^ The key of a node whose child may be the node specified.
##PD  @parentNodeType ^^  The type of a node whose child may be the node specified.

##RD @lastCode ^^ A single value signifying whether the specified parent node is the actual parent node or not.
##RD @pKey ^^ A temporary variable in the cursor for storing the intermediate parentKey
*/
begin

set nocount on
   declare @lastKey int
   declare @lastType int
   declare @lastCode int
   declare @parentKey int
   declare @parentType int
   declare @bDone int
   declare @SWV_curs1_pKey int
   declare @curs1 cursor
   declare @SWV_curs2_pKey int
   declare @curs2 cursor
   declare @SWV_curs21_pKey int
   declare @curs21 cursor
   declare @SWV_curs3_pKey int
   declare @curs3 cursor
   declare @SWV_curs31_pKey int
   declare @curs31 cursor
   declare @SWV_curs7_pKey int
   declare @curs7 cursor
   declare @SWV_curs10_pKey int
   declare @curs10 cursor
  --      message '------------------------';
  --      message 'in absp_isChildofNode, nodeKey, nodeType, parentNodeKey  = ', nodeKey , nodeType, parentNodeKey;
   if @parentNodeKey <= 0 or @parentNodeType < 0
   begin
      set @lastCode = -1
      return @lastCode
   end
   set @lastKey = @nodeKey
   set @lastType = @nodeType
   set @lastCode = -1
  --  return if child and parent are mismatched
  --
   if @nodeType = 10 and(@parentNodeType = 9 or @parentNodeType = 8 or @parentNodeType = 2)
   begin
      return @lastCode
   end
   else
   begin
      if @nodeType = 9 and(@parentNodeType = 10 or @parentNodeType = 7 or @parentNodeType = 3 or @parentNodeType = 27 or @parentNodeType = 23 or @parentNodeType = 30)
      begin
         return @lastCode
      end
      else
      begin
         if @nodeType = 7 and(@parentNodeType = 7 or @parentNodeType = 8 or @parentNodeType = 2)
         begin
            return @lastCode
         end
         else
         begin
            if @nodeType = 8 and(@parentNodeType = 8 or @parentNodeType = 7 or @parentNodeType = 3 or @parentNodeType = 27 or @parentNodeType = 23)
            begin
               return @lastCode
            end
            else
            begin
               if @nodeType = 2 and(@parentNodeType = 2 or @parentNodeType = 3 or @parentNodeType = 7 or @parentNodeType = 8 or @parentNodeType = 27 or @parentNodeType = 23)
               begin
                  return @lastCode
               end
               else
               begin
                  if @nodeType = 3 and(@parentNodeType = 3 or @parentNodeType = 2 or @parentNodeType = 8 or @parentNodeType = 8 or @parentNodeType = 23)
                  begin
                     return @lastCode
                  end
                  else
                  begin
                     if @nodeType = 23 and(@parentNodeType = 3 or @parentNodeType = 2 or @parentNodeType = 8 or @parentNodeType = 23)
                     begin
                        return @lastCode
                     end
                     else
                     begin
                        if @nodeType = 27 and(@parentNodeType = 7 or @parentNodeType = 8 or @parentNodeType = 2)
                        begin
                           return @lastCode
                        end
                        else
                        begin
                           if @nodeType = 30 and(@parentNodeType = 9 or @parentNodeType = 8 or @parentNodeType = 2)
                           begin
                              return @lastCode
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
    --	in case you are trying to fool me
   if(@parentNodeKey+@parentNodeType) = 0 or(@nodeKey+@nodeType) = 0
   begin
      return @lastCode
   end
   if @parentNodeKey < 0 or @parentNodeType < 0 or @nodeKey < 0 or @nodeType < 0
   begin
      return @lastCode
   end
   set @bDone = 0
   while @bDone = 0
   begin
    -- # of parents for paste-link type nodes &gt; 1, we need to recursively call this procedure 
    
      -----------------------------------------------------------------------
      -- aport type. An aport may be paste-linked and be a child of a folder
      -----------------------------------------------------------------------
      
      --message 'in absp_isChildofNode-Aport: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
    
      -----------------------------------------------------------------------
      -- pport type. A pport may be paste-linked and be a child of an aport
      -----------------------------------------------------------------------
      
      --message 'in absp_isChildofNode-pportF: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;				 		 
    
      -----------------------------------------------------------------------
      -- Rport type. A rport may be paste-linked and be a child of an aport
      -----------------------------------------------------------------------
      
      --message 'in absp_isChildofNode-rportF: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
    
      -----------------------------------------------------------------------
      -- program type. A program may be paste-linked and be a child of a rport
      -----------------------------------------------------------------------
      
      --message 'in absp_isChildofNode-prog: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;			
    
      --------------------------------------------------------------------------------------------
      -- case type. A case may be under a paste-linked program which in turn is a child of a rport
      --------------------------------------------------------------------------------------------	
      if @nodeType = 1
      begin
         set @parentType = 0
      
        -- yes,  the target parent matches return 
         set @curs1 = cursor fast_forward for select FOLDER_KEY  from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 1)
         open @curs1
         fetch next from @curs1 into @SWV_curs1_pKey
         while @@fetch_status = 0
         begin
            if @SWV_curs1_pKey > 0 and @parentNodeKey = @SWV_curs1_pKey and @parentNodeType = @parentType
            begin
               print 'in absp_isChildofNode-Aport:@pKey, @parentType  = '
               print @lastCode
               print @SWV_curs1_pKey
               print @parentType
               return @SWV_curs1_pKey
            end
            else
            begin
               -- recursive call
               execute @lastCode = absp_isChildofNode @SWV_curs1_pKey,@parentType,@parentNodeKey,@parentNodeType
              -- yes,  the target parent matches return
               if @lastCode > 0
               begin
                  print 'in absp_isChildofNode-Aport: @lastCode, @pKey, @parentType  = '
                  print @lastCode
                  print @SWV_curs1_pKey
                  print @parentType
                  return @lastCode
               end
            end
            fetch next from @curs1 into @SWV_curs1_pKey
         end
         close @curs1
         deallocate @curs1
      end
      else
      begin
         if @nodeType = 2
         begin
            set @parentType = 1
      
            -- yes,  the target parent matches return 
            set @curs2 = cursor fast_forward for select APORT_KEY  from APORTMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 2)
            open @curs2
            fetch next from @curs2 into @SWV_curs2_pKey
            while @@FETCH_STATUS = 0
            begin
               if @SWV_curs2_pKey > 0 and @parentNodeKey = @SWV_curs2_pKey and @parentNodeType = @parentType
               begin
                  print 'in absp_isChildofNode-pport:@pKey, @parentType  = '
                  print @lastCode
                  print @SWV_curs2_pKey
                  print @parentType
                  return @SWV_curs2_pKey
               end
               else
               begin
                  -- recursive call
                  execute @lastCode = absp_isChildofNode @SWV_curs2_pKey,@parentType,@parentNodeKey,@parentNodeType
                  -- yes,  the target parent matches return
                  if @lastCode > 0
                  begin
                     print 'in absp_isChildofNode-pport: @lastCode, @pKey, @parentType  = '
                     print @lastCode
                     print @SWV_curs2_pKey
                     print @parentType
                     return @lastCode
                  end
               end
               fetch next from @curs2 into @SWV_curs2_pKey
            end
            close @curs2
            deallocate @curs2
      --message 'in absp_isChildofNode-pport: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
      -----------------------------------------------------------------------
      -- pport type. A pport may be paste-linked and be a child of a folder
      -----------------------------------------------------------------------
            if @lastCode < 0
            begin
               set @parentType = 0
               set @curs21 = cursor fast_forward for select FOLDER_KEY  from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 2)
               open @curs21
               fetch next from @curs21 into @SWV_curs21_pKey
               while @@fetch_status = 0
               begin
                  set @parentType = 0
                  -- yes,  the target parent matches return 
                  if @SWV_curs21_pKey > 0 and @parentNodeKey = @SWV_curs21_pKey and @parentNodeType = @parentType
                  begin
                     print 'in absp_isChildofNode-pportF:@pKey, @parentType  = '
                     print @lastCode
                     print @SWV_curs21_pKey
                     print @parentType
                     return @SWV_curs21_pKey
                  end
                  else
                  begin
                      -- recursive call
                     execute @lastCode = absp_isChildofNode @SWV_curs21_pKey,@parentType,@parentNodeKey,@parentNodeType
                    -- yes,  the target parent matches return
                     if @lastCode > 0
                     begin
                        print 'in absp_isChildofNode-pportF: @lastCode, @pKey, @parentType  = '
                        print @lastCode
                        print @SWV_curs21_pKey
                        print @parentType
                        return @lastCode
                     end
                  end
                  fetch next from @curs21 into @SWV_curs21_pKey
               end
               close @curs21
               deallocate @curs21
            end
         end
         else
         begin
            if @nodeType = 3 or @nodeType = 23
            begin
               set @parentType = 1
      
              -- yes,  the target parent matches return 
               set @curs3 = cursor fast_forward for select APORT_KEY   from APORTMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
               open @curs3
               fetch next from @curs3 into @SWV_curs3_pKey
               while @@FETCH_STATUS = 0
               begin
                  if @SWV_curs3_pKey > 0 and @parentNodeKey = @SWV_curs3_pKey and @parentNodeType = @parentType
                  begin
                     print 'in absp_isChildofNode-rport @pKey, @parentType  = '
                     print @lastCode
                     print @SWV_curs3_pKey
                     print @parentType
                     return @SWV_curs3_pKey
                  end
                  else
                  begin
                    -- recursive call
                     execute @lastCode = absp_isChildofNode @SWV_curs3_pKey,@parentType,@parentNodeKey,@parentNodeType
                    -- yes,  the target parent matches return
                     if @lastCode > 0
                     begin
                        print 'in absp_isChildofNode-rport: @lastCode, @pKey, @parentType  = '
                        print @lastCode
                        print @SWV_curs3_pKey
                        print @parentType
                        return @lastCode
                     end
                  end
                  fetch next from @curs3 into @SWV_curs3_pKey
               end
               close @curs3
               deallocate @curs3
      --message 'in absp_isChildofNode-rport: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
      -----------------------------------------------------------------------
      -- Rport type. A rport may be paste-linked and be a child of a folder
      -----------------------------------------------------------------------
               if @lastCode < 0
               begin
                  set @parentType = 0
        
                  -- yes,  the target parent matches return 
                  set @curs31 = cursor fast_forward for 
                     select FOLDER_KEY from FLDRMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
                  open @curs31
                  fetch next from @curs31 into @SWV_curs31_pKey
                  while @@fetch_status = 0
                  begin
                     if @SWV_curs31_pKey > 0 and @parentNodeKey = @SWV_curs31_pKey and @parentNodeType = @parentType
                     begin
                        print 'in absp_isChildofNode-rportF @pKey, @parentType  = '
                        print @lastCode
                        print @SWV_curs31_pKey
                        print @parentType
                        return @SWV_curs31_pKey
                     end
                     else
                     begin
                        -- recursive call
                        execute @lastCode = absp_isChildofNode @SWV_curs31_pKey,@parentType,@parentNodeKey,@parentNodeType
                        -- yes,  the target parent matches return
                        if @lastCode > 0
                        begin
                           print 'in absp_isChildofNode-rportF: @lastCode, @pKey, @parentType  = '
                           print @lastCode
                           print @SWV_curs31_pKey
                           print @parentType
                           return @lastCode
                        end
                     end
                     fetch next from @curs31 into @SWV_curs31_pKey
                  end
                  close @curs31
                  deallocate @curs31
               end
            end
            else
            begin
               if @nodeType = 7 or @nodeType = 27
               begin
                  set @parentType = 3
      
                  -- yes,  the target parent matches return 
                  set @curs7 = cursor fast_forward for 
                     select RPORT_KEY  from RPORTMAP where(CHILD_KEY = @nodeKey) and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
                  open @curs7
                  fetch next from @curs7 into @SWV_curs7_pKey
                  while @@FETCH_STATUS = 0
                  begin
                     if @SWV_curs7_pKey > 0 and @parentNodeKey = @SWV_curs7_pKey and @parentNodeType = @parentType
                     begin
                        print 'in absp_isChildofNode-prog: @pKey, @parentType  = '
                        print @lastCode
                        print @SWV_curs7_pKey
                        print @parentType
                        return @SWV_curs7_pKey
                     end
                     else
                     begin
                        -- recursive call
                        execute @lastCode = absp_isChildofNode @SWV_curs7_pKey,@parentType,@parentNodeKey,@parentNodeType
                        -- yes,  the target parent matches return
                        if @lastCode > 0
                        begin
                           print 'in absp_isChildofNode-prog: @lastCode, @pKey, @parentType  = '
                           print @lastCode
                           print @SWV_curs7_pKey
                           print @parentType
                           return @lastCode
                        end
                     end
                     fetch next from @curs7 into @SWV_curs7_pKey
                  end
                  close @curs7
                  deallocate @curs7
               end
               else
               begin
                  if @nodeType = 10 or @nodeType = 30
                  begin
                     set @parentType = 3
      
                     -- yes,  the target parent matches return 
                     set @curs10 = cursor fast_forward for 
                          select RPORT_KEY  from RPORTMAP where(CHILD_TYPE = 7 or CHILD_TYPE = 27) 
                            and CHILD_KEY =(select PROG_KEY from CASEINFO where CASE_KEY = @nodeKey)
                     open @curs10
                     fetch next from @curs10 into @SWV_curs10_pKey
                     while @@FETCH_STATUS = 0
                     begin
                        if @SWV_curs10_pKey > 0 and @parentNodeKey = @SWV_curs10_pKey and @parentNodeType = @parentType
                        begin
                           print 'in absp_isChildofNode-progCase: @pKey, @parentType  = '
                           print @lastCode
                           print @SWV_curs10_pKey
                           print @parentType
                           return @SWV_curs10_pKey
                        end
                        else
                        begin
                           -- recursive call
                           execute @lastCode = absp_isChildofNode @SWV_curs10_pKey,@parentType,@parentNodeKey,@parentNodeType
                           -- yes,  the target parent matches return
                           if @lastCode > 0
                           begin
                              print 'in absp_isChildofNode-progCase: @lastCode, @pKey, @parentType  = '
                              print @lastCode
                              print @SWV_curs10_pKey
                              print @parentType
                              return @lastCode
                           end
                        end
                        fetch next from @curs10 into @SWV_curs10_pKey
                     end
                     close @curs10
                     deallocate @curs10
                  end
                  else
                  begin
                      --message 'in absp_isChildofNode-progCase: @lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;	
                     execute @lastCode = absp_FindNodeParent @parentKey output,@parentType output,@lastKey,@lastType,@parentNodeKey
                  end
               end
            end
         end
      end
      --message 'in absp_isChildofNode ,@lastCode, @parentKey, @parentType  = ', @lastCode, @parentKey, @parentType;
      set @lastKey = @parentKey
      set @lastType = @parentType
      -- message 'in absp_isChildofNode , @lastCode, parentNodeKey, parentNodeType  = ', @lastCode, parentNodeKey, parentNodeType;  
      --  check if the node found 
      if @lastCode > 0 and @parentKey = @parentNodeKey and @parentType = @parentNodeType
      begin
         set @lastCode = @parentKey
         return @lastCode
      end
      else
      begin
        -- DONE if reaching currency node (@lastcode = 2) or cannot find parent (@parentKey &lt; 0...)                      
        -- message 'in absp_isChildofNode , @lastCode, parentNodeKey, parentNodeType  = ', @lastCode, parentNodeKey, parentNodeType;
         if @lastCode = 2 or @lastCode < 0 or @parentKey = -1 or @parentType = -1
         begin
            set @bDone = 1
         end
      end
   end
   set @lastCode = -1
   return @lastCode
end





