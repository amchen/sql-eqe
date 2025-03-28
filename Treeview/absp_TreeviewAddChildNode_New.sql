if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewAddChildNode_New') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAddChildNode_New
end
 go

create procedure absp_TreeviewAddChildNode_New @currentNodeKey int ,@currentNodeType int ,@childType int ,@longName varchar(120) ,@createBy int ,@groupKey int ,@extraKey int, @createMode int = 0 
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
##PD  @createMode ^^  create mode: 0 = don't create, 1 = create new, 2 = auto create.

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
   declare @inceptDt  char(10)
   declare @expireDate datetime
   declare @expireDt char(10)
   declare @extraSQLVars char(200)
   declare @extraSQLParms char(200)
   declare @mt_Flag_Parm char(1)
   declare @tmpLongName varchar(120)
   set @infoTableName = '-'
   set @mapTableName = '-'
   set @extraSQLVars = ''
   set @extraSQLParms = ''
   set @mt_Flag_Parm = ''
  -- now date + time
  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
  -- base things on current node first
  
  exec @lastKey = absp_Util_GetNodeKeyByName @longName, @childType, @currentNodeKey;
  print str(@lastKey)
  if @lastKey > 0 and (@createMode = 0 or @createMode = 2)
  begin
	select @lastKey as NodeKey, @longName as LongName;
	return;
  end
  else if @lastKey > 0 and @createMode = 1
  begin
  	set @tmpLongName = @longName + '_' + cast(@createDt as varchar(14));
  	print   @tmpLongName;
  	
  	if @tmpLongName = @longName
  		RAISERROR ('Unable to generate a unique name. Please try with a new name.', 1, 1)
  	else	
		exec absp_TreeviewAddChildNode_New @currentNodeKey, @currentNodeType, @childType, @tmpLongName, @createBy, @groupKey,@extraKey, @createMode
  	return;
  end
  
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

				  exec absp_Util_GetDateString @inceptDt output,'yyyymmdd'
				  set @expireDate = dateadd(dd,365,GetDate())
				  exec absp_Util_GetDateString @expireDt output,'yyyymmdd', @expireDate
      -- we have to set these extra variables or when pulling back you get join exceptions
                  set @extraSQLVars = ',GROUP_NAM, BROKER_NAM, PROGSTAT, MT_FLAG, INCEPT_DAT, EXPIRE_DAT'
                  set @extraSQLParms = ' ,'''+'None'+''','''+'None'+''''+',''Bound'''+','''+@mt_Flag_Parm+''', '''+@inceptDt+''','''+@expireDt+''''
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
				  exec absp_Util_GetDateString @inceptDt output,'yyyymmdd'
				  set @expireDate = dateadd(dd,365,GetDate())
				  exec absp_Util_GetDateString @expireDt output,'yyyymmdd', @expireDate
      -- we have to set these extra variables or when pulling back you get join exceptions
                  set @extraSQLVars = ',GROUP_NAM, BROKER_NAM, PROGSTAT, MT_FLAG, INCEPT_DAT, EXPIRE_DAT'
                  set @extraSQLParms = ' ,'''+'None'+''','''+'None'+''''+',''Bound'''+','''+@mt_Flag_Parm+''', '''+@inceptDt+''','''+@expireDt+''''
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
                        select @lastKey as NodeKey, @longName as LongName;
                        return;
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
                           select @lastKey as NodeKey, @longName as LongName;
                           return;
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
      set @longName = '';
      select @lastKey as NodeKey, @longName as LongName;
      return;
   end
   if @mapTableName = '-'
   begin
    --return 0;
      set @lastKey = 0
      set @longName = '';
      select @lastKey as NodeKey, @longName as LongName;
      return;
   end
  --prepare the statement
   set @sqlStmt = 'insert into '+@infoTableName+' ( LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY'+@extraSQLVars+') '+' values ('''+@longName+''','''+'ACTIVE'+''','''+@createDt+''','+rtrim(ltrim(str(@createBy)))+','+rtrim(ltrim(str(@groupKey)))+@extraSQLParms+')'
   print '$$$$$$$$$$$$   '+@sqlStmt
  -- do it
   execute(@sqlStmt)
  -- get the key of the new item
   set @lastKey = @@identity
  -- update the map
   set @sqlStmt = 'insert into '+@mapTableName+' values( '+rtrim(ltrim(str(@currentNodeKey)))+','+rtrim(ltrim(str(@lastKey)))+', '+rtrim(ltrim(str(@childType)))+')'
  -- do it
   execute(@sqlStmt)
   Select @lastKey as NodeKey, @longName as LongName;
end



