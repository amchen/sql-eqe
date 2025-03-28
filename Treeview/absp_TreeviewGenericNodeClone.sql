if exists(select 1 from  SYSOBJECTS where ID = object_id(N'absp_TreeviewGenericNodeClone') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGenericNodeClone
end
go

create procedure absp_TreeviewGenericNodeClone @nodeKey int,
                                               @nodeType int,
                                               @newParentKey int,
                                               @newParentType int,
                                               @oldParentKey int,
                                               @oldParentType int,
                                               @createBy int,  
                                               @results int = 0,
                                               @temp_prog_table CHAR(70) = '',
                                               @fromAPORTClone int = 0,
                                               @targetDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure :
- Clones the given node and all its chidren and attaches it to the new parent.
- Returns the key of the clone node.

Returns:       A single value @lastKey
@lastKey >0   If the clone node is created (It returns the key of the created node)
@lastKey=0    If the clone node is not created

====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node that is to be cloned. 
##PD  @nodeType ^^  The type of node that is to be cloned.
##PD  @newParentKey ^^  The key of the parent to which the new node is to be be attached.
##PD  @newParentType ^^  The type of the parent to which new node is to be attached.
##PD  @oldParentKey ^^  The key of the parent to which the given node is attached.
##PD  @oldParentType ^^  The type of the parent to which given node is attached.
##PD  @createBy ^^  The user key of the user creating the clone. 
##PD  @results ^^  A flag indicating whether the intermediate results are to be cloned or not

##RD @lastKey ^^  The key of the new node.

*/
as


BEGIN TRY

  set nocount on
  
  --
  -- SDG__00011740 -- turn OFF results flag absp_TreeviewRPortfolioClone.  We do not copy intermediates
  --              when Folders or Accumulators are copied.
  --
  --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --FPort = 4;
  --Acct = 5;
  --Cert = 6;
  --Prog = 7;
  --Lport = 8;
  --Currency = 12;
  --MTRPORT = 23
  
   declare @lastKey INT
   
 
   if @targetDB=''
   		set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   

  --SDG_00006848 - added clone currency folder
  -- call the correct deleter based on the node type
   if @nodeType = 0
   begin
      execute @lastKey = absp_TreeviewFolderClone @nodeKey,@newParentKey,@createBy,@targetDB
   end
   else
   begin
      if @nodeType = 1
      begin
         execute @lastKey = absp_TreeviewAPortfolioClone @nodeKey,@newParentKey,@newParentType,@createBy,@results,@temp_prog_table,@targetDB
      end
      else
      begin
         if @nodeType = 2
         begin
            execute @lastKey = absp_TreeviewPPortfolioClone @nodeKey,@newParentKey,@newParentType,@oldParentKey,@oldParentType,@createBy,@fromAPORTClone,@targetDB
         end
         else
         begin
            if @nodeType = 3
            begin
               execute @lastKey = absp_TreeviewRPortfolioClone @nodeKey,@newParentKey,@newParentType,@oldParentKey,@oldParentType,@createBy,1,@results,1,1,@temp_prog_table,@fromAPORTClone,@targetDB
            end
            else
            begin
               if @nodeType = 23
               begin
                  execute @lastKey = absp_TreeviewRPortfolioClone @nodeKey,@newParentKey,@newParentType,@oldParentKey,@oldParentType,@createBy,1,@results,0,1,@temp_prog_table,@fromAPORTClone,@targetDB
               end
               else
--               begin
--                  if @nodeType = 4
--                  begin
--                     execute @lastKey = absp_TreeviewFPortfolioClone @nodeKey,@newParentKey,@newParentType,@createBy
--                  end
--                  else
                  begin
                     if @nodeType = 12
                     begin
                        execute @lastKey = absp_TreeviewFolderClone @nodeKey,@newParentKey,@createBy
                     end
--                  end
               end
            end
         end
      end
   end
  -- send back the new key
  
   
   return @lastKey
END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH

