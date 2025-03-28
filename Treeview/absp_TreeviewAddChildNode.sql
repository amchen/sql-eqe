if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewAddChildNode') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAddChildNode
end
 go

create procedure absp_TreeviewAddChildNode @currentNodeKey int ,@currentNodeType int ,@childType int ,@longName char(120) ,@createBy int ,@groupKey int ,@extraKey int 
-- this procedure will insert a data element then add it to the appropriate map
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new node, adds it to its parent and returns the new node Key.

Returns:    The Key of the new node. Zero will be returned in case of invalid currentNodeType & childType

====================================================================================================
</pre>
</font>
##BD_END

##PD  @currentNodeKey ^^  The key of the parent node to which the node will be added.
##PD  @currentNodeType ^^  The type of the parent node to which the node will be added.
##PD  @childType ^^  The type of node to which is to be created.
##PD  @longName ^^  The name of the new node.
##PD  @createBy ^^  The user key of the user creating the node.
##PD  @groupKey ^^  The group key of the user creating the rport.
##PD  @extraKey ^^  Unused parameter.

##RD  @lastKey ^^  The key of the new node.

*/
as
begin
 
   set nocount on
   
 --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --Prog = 7;
  --Lport = 8;
  --MTRPORT = 23;
  --MTPROG = 27;
   declare @infoTableName char(12)
   declare @mapTableName char(12)
   declare @lastKey int
   declare @sqlStmt char(4096)
   declare @createDt char(14)
   declare @extraSQLVars char(200)
   declare @extraSQLParms char(200)
   declare @mt_Flag_Parm char(1)
   set @infoTableName = '-'
   set @mapTableName = '-'
   set @extraSQLVars = ''
   set @extraSQLParms = ''
   set @mt_Flag_Parm = ''
  -- now date + time
  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
  -- base things on current node first
  
  -- If at Program, you can add a case
   if @currentNodeType = 0
   begin
      set @mapTableName = 'FLDRMAP'
      if @childType = 0
      begin
         set @infoTableName = 'FLDRINFO'
      end
      else
      begin
         if @childType = 1
         begin
            set @infoTableName = 'APRTINFO'
         end
         else
         begin
            if @childType = 2
            begin
               set @infoTableName = 'PPRTINFO'
            end
            else
            begin
               if @childType = 3
               begin
                  set @infoTableName = 'RPRTINFO'
                  set @mt_Flag_Parm = 'N'
                  set @extraSQLVars = ', MT_FLAG'
                  set @extraSQLParms = ','''+@mt_Flag_Parm+''''
               end
               else
               begin
                  if @childType = 23
                  begin
                     set @infoTableName = 'RPRTINFO'
                     set @mt_Flag_Parm = 'Y'
                     set @extraSQLVars = ', MT_FLAG'
                     set @extraSQLParms = ','''+@mt_Flag_Parm+''''
                  end
                  else
                  begin
                     print 'unsupported child type'
                  end
               end
            end
         end
      end
   end
   else
   begin
      if @currentNodeType = 1
      begin
         set @mapTableName = 'APORTMAP'
         if @childType = 1
         begin
            set @infoTableName = 'APRTINFO'
         end
         else
         begin
            if @childType = 2
            begin
               set @infoTableName = 'PPRTINFO'
            end
            else
            begin
               if @childType = 3
               begin
                  set @infoTableName = 'RPRTINFO'
                  set @mt_Flag_Parm = 'N'
                  set @extraSQLVars = ', MT_FLAG'
                  set @extraSQLParms = ','''+@mt_Flag_Parm+''''
               end
               else
               begin
                  if @childType = 23
                  begin
                     set @infoTableName = 'RPRTINFO'
                     set @mt_Flag_Parm = 'Y'
                     set @extraSQLVars = ', MT_FLAG'
                     set @extraSQLParms = ','''+@mt_Flag_Parm+''''
                  end
                  else
                  begin
                     print 'unsupported child type'
                  end
               end
            end
         end
      end
      else
      begin
            if @currentNodeType = 3
            begin
               set @mapTableName = 'RPORTMAP'
               set @mt_Flag_Parm = 'N'
               set @extraSQLVars = ', MT_FLAG'
               set @extraSQLParms = ','''+@mt_Flag_Parm+''''
               if @childType = 7
               begin
                  set @infoTableName = 'PROGINFO'
      -- Fixed code to handle Multi-Treaty Node
                  set @mt_Flag_Parm = 'N'
      -- we have to set these extra variables or when pulling back you get join exceptions
                  set @extraSQLVars = ',GROUP_NAM, BROKER_NAM, PROGSTAT, MT_FLAG'
                  set @extraSQLParms = ' ,'''+'None'+''','''+'None'+''''+',''Bound'''+','''+@mt_Flag_Parm+''''
               end
               else
               begin
                  print 'unsupported child type'
               end
            end
            else
            begin
               if @currentNodeType = 23
               begin
                  set @mapTableName = 'RPORTMAP'
                  set @mt_Flag_Parm = 'Y'
                  set @extraSQLVars = ', MT_FLAG'
                  set @extraSQLParms = ','''+@mt_Flag_Parm+''''
                  if @childType = 27
                  begin
                     set @infoTableName = 'PROGINFO'
      -- Fixed code to handle Multi-Treaty Node
                     set @mt_Flag_Parm = 'Y'
      -- we have to set these extra variables or when pulling back you get join exceptions
                     set @extraSQLVars = ',GROUP_NAM, BROKER_NAM, PROGSTAT, MT_FLAG'
                     set @extraSQLParms = ' ,'''+'None'+''','''+'None'+''''+',''Bound'''+','''+@mt_Flag_Parm+''''
                  end
               end
               else
               begin
                  if @currentNodeType = 7
                  begin
    -- case
                     if @childType = 10
                     begin
                        execute @lastKey = absp_TreeviewCaseAdd @currentNodeKey,10,@longName,@createDt,@createBy
      -- have to set ttype_id or get join execption
                        update CASEINFO set TTYPE_ID = 1  where CASE_KEY = @lastKey
                        return @lastKey
                     end
                     else
                     begin
                        if @childType = 6
                        begin
                           print '1'
                        end
                        else
                        begin
                           print 'unsupported child type'
                        end
                     end
                  end
                  else
                  begin
                     if @currentNodeType = 27
                     begin
                        if @childType = 30
                        begin
                           execute @lastKey = absp_TreeviewCaseAdd @currentNodeKey,30,@longName,@createDt,@createBy
      -- have to set ttype_id or get join execption
                           update CASEINFO set TTYPE_ID = 1  where CASE_KEY = @lastKey
                           return @lastKey
                        end
                     end
                     else
                     begin
                        print 'unsupported node type'
                     end
               end
            end
         end
      end
   end
  -- make sure that something was picked
   if @infoTableName = '-'
   begin
    --return 0;
      set @lastKey = 0
      return @lastKey
   end
   if @mapTableName = '-'
   begin
    --return 0;
      set @lastKey = 0
      return @lastKey
   end
  --prepare the statement
   set @sqlStmt = 'insert into '+@infoTableName+' ( LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY'+@extraSQLVars+') '+' values ('''+@longName+''','''+'NEW'+''','''+@createDt+''','+rtrim(ltrim(str(@createBy)))+','+rtrim(ltrim(str(@groupKey)))+@extraSQLParms+')'
   print '$$$$$$$$$$$$   '+@sqlStmt
  -- do it
   execute(@sqlStmt)
  -- get the key of the new item
   set @lastKey = @@identity
  -- update the map
   set @sqlStmt = 'insert into '+@mapTableName+' values( '+rtrim(ltrim(str(@currentNodeKey)))+','+rtrim(ltrim(str(@lastKey)))+', '+rtrim(ltrim(str(@childType)))+')'
  -- do it
   execute(@sqlStmt)
   return @lastKey
end



