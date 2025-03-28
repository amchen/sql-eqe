if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNodeParent') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindNodeParent
end
 go
create procedure absp_FindNodeParent @ret_parentKey int output ,@ret_parentType int output ,@nodeKey int,@nodeType int,@folderKey int = 0 ,@forCaseTheProgKey int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return 
1. The parent key and the type of the parent node for a given node via the parentKey & parentType OUTPUT parameters
2. The returned code signifying whether the parent node is found

Returns:       A single value @lastcode
1. @lastcode = -1, a parent node is not found
2. @lastcode = 1, a parent node is found
3. @lastcode = 2, a currency parent node is found
4. @lastcode = 3, a folder parent node is found
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_parentKey ^^ The key of the parent node, returned as an OUTPUT parameter.
##PD  @ret_parentType ^^ The type of the parent node, returned as an OUTPUT parameter.
##PD  @nodeKey ^^  The key of the node for which the parent node needs to be identified. 
##PD  @nodeType ^^  The type of the node for which the parent node needs to be identified.
##PD  @folderKey ^^  In case the child node is a folder, it is the parent folder key[used to test if the parent folder has any child folder of the given nodetype and nodeKey].
##PD  @forCaseTheProgKey ^^  If the node type is a case and forCaseTheProgKey then this is the key of the parent program.

##RD @lastCode ^^ A single value signifying whether a parent node is found or not and also if the node is found, then whether it is a folder or a currency folder.

*/
-- Touched on 21 Oct 2004
as
begin

   set nocount on
   
   declare @lastCode int
   declare @currNode char(1)
  -- message 'in absp_FindNodeParent , nodeKey, nodeType  = ', nodeKey , ', ', nodeType;
  -- message 'forCaseTheProgKey = ', forCaseTheProgKey;
   set @ret_parentKey = -1
   set @ret_parentType = -1
   set @lastCode = -1
  
  -- Fixed code to handle Multi-Treaty Node
  
  -- Fixed code to handle Multi-Treaty Node
  
    -- here nodeKey is portid
    
    -- here nodeKey is portid
    
    -- somewhere this was written long ago and someone wanted the RPORT not the PROG as parent
    
  -- Fixed code to handle Multi-Treaty Node
  
    -- somewhere this was written long ago and someone wanted the RPORT not the PROG as parent
   if @nodeType = 0
   begin
      execute @lastCode = absp_FindNodeParentFolder @ret_parentKey output,@ret_parentType output,@nodeKey,@nodeType
   end
   else
   begin
      if @nodeType = 1
      begin
         execute @lastCode = absp_FindNodeParentAport @ret_parentKey output,@ret_parentType output, @nodeKey,@nodeType
      end
      else
      begin
         if @nodeType = 2
         begin
            execute @lastCode = absp_FindNodeParentPport @ret_parentKey output,@ret_parentType output,@nodeKey,@nodeType
         end
         else
         begin
            if @nodeType = 3 or @nodeType = 23
            begin
               execute @lastCode = absp_FindNodeParentRport @ret_parentKey output,@ret_parentType output,@nodeKey,@nodeType
            end
            else
            begin
               if @nodeType = 7
               begin
                  select top 1 @ret_parentKey = RPORT_KEY  from RPORTMAP where CHILD_TYPE = 7 and CHILD_KEY = @nodeKey
                  set @ret_parentType = 3
                  set @lastCode = 1
               end
               else
               begin
                  if @nodeType = 27
                  begin
                     select top 1 @ret_parentKey = RPORT_KEY  from RPORTMAP where CHILD_TYPE = 27 and CHILD_KEY = @nodeKey
                     set @ret_parentType = 23
                     set @lastCode = 1
                  end
                  else
                        begin
                           if @nodeType = 10
                           begin
                              if @forCaseTheProgKey = 0
                              begin
                                 select top 1 @ret_parentKey = RPORT_KEY  from RPORTMAP where CHILD_TYPE = 7 and CHILD_KEY =(select  PROG_KEY from CASEINFO where CASE_KEY = @nodeKey)
                                 set @ret_parentType = 3
                                 set @lastCode = 1
                              end
                              else
                              begin
                                 select  @ret_parentKey = PROG_KEY  from CASEINFO where CASE_KEY = @nodeKey
                                 set @ret_parentType = 7 -- my program parent
                                 set @lastCode = 1
                              end
                           end
                           else
                           begin
                              if @nodeType = 30
                              begin
                                 if @forCaseTheProgKey = 0
                                 begin
                                    select top 1 @ret_parentKey = RPORT_KEY  from RPORTMAP where CHILD_TYPE = 27 and CHILD_KEY =(select  PROG_KEY from CASEINFO where CASE_KEY = @nodeKey)
                                    set @ret_parentType = 23
                                    set @lastCode = 1
                                 end
                                 else
                                 begin
                                    select  @ret_parentKey = PROG_KEY  from CASEINFO where CASE_KEY = @nodeKey
                                    set @ret_parentType = 27 -- my mt program parent
                                    set @lastCode = 1
                                 end
                              end
                           end
                  end
               end
            end
         end
      end
   end
  --message '^^^in absp_FindNodeParent , parentKey   = ', ret_parentKey , ' parentType   = ', ret_parentType ;
   if @ret_parentType = 0
   begin
      select  @currNode = left(CURR_NODE,1)  from FLDRINFO where
      FOLDER_KEY = @ret_parentKey
    --message 'cn = ', @currNode ;
    -- user just wants to get the currency key 
    
    -- test if the folder has any children of the given nodetype and nodeKey
      if(@currNode = 'y')
      begin
         set @lastCode = 2
         return @lastCode
      end
      else
      begin
         if(@currNode = 'n' and @folderKey > 0 and @ret_parentKey = @folderKey)
         begin
            set @lastCode = 3
            return @lastCode
         end
      end
   end
   return @lastCode
end

go


