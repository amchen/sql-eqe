if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetNodeInfoData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGetNodeInfoData
end
go

create procedure absp_TreeviewGetNodeInfoData
	@nodeType int,				-- your node type
	@uniqueName varchar(max),		-- your name
	@parentName varchar(max),		-- parent name
	@parentKey int,				-- only needed for create OR in case of CASE where name is not unique
	@policyPportName varchar(max),		-- used for policy + site nodes
	@currencyFolderName varchar(max),	-- currency folder
	@createFlag int,			-- am i looking or creating
	@autoCreateFlag int,			-- if true create my parent if not already there
	@grandParentName varchar(max) = '',	-- in case of create, what is your gparent name
	@grandParentType int = 0,		-- in case of create, what is your gparent type
	@parentType INT = 0,			-- in case of create, what is your parent type
	@note varchar(max) = ''			-- in case of create, an optional note
AS
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a single result containing the node, parent node and parent currency node 
information for a given node.It creates a new node if the createFlag is on.


Returns:       A single resultset containing the following information for a given node:-
Node_key,node_type,node_name,parent_key,parent_type,parent_name,currency_key,currency_name,
currschema_key,currschema_name,port_id,grandparent_key,grandparent_type,grandparent_name 



====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^  The type of node which is to be created or whose information is to be retrieved. 
##PD  @uniqueName ^^  The longname of node which is to be created or whose information is to be retrieved. 
##PD  @parentName ^^  The parent name of the node which is to be created or whose information is to be retrieved. 
##PD  @parentKey ^^  The parent node key of node which is to be created or whose information is to be retrieved. 
##PD  @policyPportName ^^  The parent pport name in case of policy nodes and sites. 
##PD  @currencyFolderName ^^  The name of the parent currency folder of node which is to be created or whose information is to be retrieved. 
##PD  @createFlag ^^  A flag indicating whether the node is to be created or not. 
##PD  @autoCreateFlag ^^  A flag indicating whether the parent is to be created if it does not exist.
##PD  @grandParentName ^^  The grand parent node name for the node which is to be created. 
##PD  @grandParentType ^^  The type of the grandparent node for which the node is to be created. 
##PD  @parentType ^^ The type of parent for the node which is to be created. 
##PD  @note ^^  The user notes for the node which is to be created. 

##RS  NODE_KEY ^^  The key of the given node.
##RS  NODE_TYPE ^^  The node type.
##RS  NODE_NAME ^^  The node name.
##RS  PARENT_KEY ^^  The parent key.
##RS  PARENT_TYPE ^^  The parent type.
##RS  PARENT_NAME ^^  The name of the parent
##RS  CURRENCY_KEY ^^  The parent currency folder key
##RS  CURRENCY_NAME ^^  The parent currency folder name
##RS  CURRSCHEMA_KEY ^^  The key of the parent currency schema 
##RS  CURRSCHEMA_NAME ^^  The name of the parent currency schema
##RS  PORT_ID ^^  The portId in case of Policies & sites.
##RS  GRANDPARENT_KEY ^^  The key of the grandparent node.
##RS  GRANDPARENT_TYPE ^^  The type of the grandparent node.
##RS  GRANDPARENT_NAME ^^  The name of the grandparent node.

*/
begin
 
   set nocount on
   
 -- this procedure has two modes.
  -- if create is false, then you are looking to get info back, so it will
  -- try to find your key based on name (and in case of case your parent)
  -- and then find your currency and schema after that.
  -- in create mode, it will try to make you, and if the autocreate is set,
  -- it will try to make your parent if it does not exist.
  --
  -- Important:  With the new ReinsuanceAccount, Account and Treaty nodes,
  --   a record may be found with the requested name, but the wrong MT_FLAG state.
  --   In this case, autoCreate must fail because two records cannot have the same name.
  --   The caller must inspect the returned nodeType to see if matches the desired one.
  -- SDG__00014957 -- ICMS -- WceRequest @description needs to create a USRNOTES record
   declare @nodeKey int
   declare @origNodeType int
   declare @parentKey2 int
   declare @parentType2 int
   declare @parentName2 varchar(max)
   declare @currencyKey int
   declare @currencyName varchar(max)
   declare @currSchemaKey int
   declare @currSchemaName varchar(max)
   declare @last int
   declare @portId int
   declare @policyKey int
   declare @siteKey int
   declare @policyNum varchar(max)
   declare @grandParentKey int
   declare @grandParentType2 int
   declare @grandParentName2 varchar(max)
   declare @pportKey int
   declare @rportKey int
   declare @lportKey int
   declare @folderKey int
   declare @newKey int
   declare @mtFlag char(1)
   set @origNodeType = @nodeType
   set @nodeKey = -1
   set @parentKey2 = -1
   set @currencyKey = -1
   set @currSchemaKey = -1
   set @parentType2 = -1
   set @portId = -1
   set @policyKey = -1
   set @siteKey = -1
   set @grandParentKey = -1
   set @grandParentType2 = -1
   set @pportKey = -1
   set @rportKey = -1
   set @lportKey = -1
   set @newKey = -1
   set @folderKey = -1
   set @parentName2 = ''
   set @currencyName = @currencyFolderName
   set @currSchemaName = ''
   set @policyNum = ''
   set @grandParentName2 = ''
   set @mtFlag = ''
  -- --------------------------------------- debug msg ----------------------------------------   
   if 1 = 0
   begin
      execute absp_MessageEx 'absp_TreeviewGetNodeInfoData'
      print 'nodeType = '
      print @nodeType
      print 'uniqueName = '
      print @uniqueName
      print 'parentName = '
      print @parentName
      print 'parentKey = '
      print @parentKey
      print 'policyPportName = '
      print @policyPportName
      print 'currencyFolderName = '
      print @currencyFolderName
      print 'grandParentName = '
      print @grandParentName
      print 'grandParentType = '
      print @grandParentType
      print 'parentType = '
      print @parentType
   end
  -- --------------------------------------- Handle Default Currency section ---------------------------  
   if @currencyName = 'default'
   begin
      select   @currencyName = VALUE  from ICMSCTRL where CATEGORY = 'DEFAULTS' and NAME = 'CURRENCY_FOLDER' and PROPERTY = 'DEFAULT'
      if @currencyName = 'default'
      begin
         select   @currencyName = LONGNAME  from fldrinfo where FOLDER_KEY = 1 and CURR_NODE = 'Y'
         if @currencyName <> 'default'
         begin
   
            insert into ICMSCTRL(CATEGORY,NAME,PROPERTY,VALUE) values('DEFAULTS','CURRENCY_FOLDER','DEFAULT',@currencyName)
            
         end
      end
   end
  -- --------------------------------------- get my key section ----------------------------------------  
  -- first get the key for the node of interest
  
  -- folder
  
  -- aport
  
  -- pport
  
  -- rport
  
  -- multi-treaty rport
  
  -- prog
  
  -- multi-treaty prog
  
  -- policy
  
    -- must have a pport name
    -- and by the by in the case of duplicate names i return the first one i fond.
    -- not my fault no one enforces no dupes.
    
  -- site
  
    -- must have a pport name
    
  -- case
  
    -- dumb choice but we made case name non-unique.
    -- you must give us either parent key or parent name
    
  -- multi-treaty case
  
    -- dumb choice but we made case name non-unique.
    -- you must give us either parent key or parent name
   if @nodeType = 0
   begin
      select   @nodeKey = FOLDER_KEY  from fldrinfo where LONGNAME = @uniqueName and CURR_NODE = 'N'
   end
   else
   begin
	  if @nodeType = 12
      begin
         select   @nodeKey = FOLDER_KEY  from cfldrinfo where LONGNAME = @uniqueName
      end
      else
      begin
		  if @nodeType = 1
		  begin
			 select   @nodeKey = APORT_KEY  from Aprtinfo where LONGNAME = @uniqueName
		  end
		  else
		  begin
			 if @nodeType = 2
			 begin
				select   @nodeKey = PPORT_KEY  from PPRTINFO where LONGNAME = @uniqueName
			 end
			 else
			 begin
				if @nodeType = 3
				begin
				   select   @nodeKey = RPORT_KEY, @mtFlag = MT_FLAG  from RPRTINFO where LONGNAME = @uniqueName
				end
				else
				begin
				   if @nodeType = 23
				   begin
					  select   @nodeKey = RPORT_KEY, @mtFlag = MT_FLAG  from RPRTINFO where LONGNAME = @uniqueName
				   end
				   else
				   begin
					  if @nodeType = 7
					  begin
						 select   @nodeKey = PROG_KEY, @mtFlag = MT_FLAG  from PROGINFO where LONGNAME = @uniqueName
					  end
					  else
					  begin
						 if @nodeType = 27
						 begin
							select   @nodeKey = PROG_KEY, @mtFlag = MT_FLAG  from PROGINFO where LONGNAME = @uniqueName
						 end
							   else
							   begin
								  if @nodeType = 10
								  begin
									 if @parentKey = 0 and @parentName <> ''
									 begin
										select   @parentKey = PROG_KEY  from PROGINFO where LONGNAME = @parentName
									 end
									 select   @nodeKey = CASE_KEY, @mtFlag = MT_FLAG  from caseinfo where LONGNAME = @uniqueName and PROG_KEY = @parentKey
								  end
								  else
								  begin
									 if @nodeType = 30
									 begin
										if @parentKey = 0 and @parentName <> ''
										begin
										   select   @parentKey = PROG_KEY  from PROGINFO where LONGNAME = @parentName
										end
										select   @nodeKey = CASE_KEY, @mtFlag = MT_FLAG  from caseinfo where LONGNAME = @uniqueName and PROG_KEY = @parentKey
									 end
								  end
							   end
							end
				   end
				end
			 end
		end
      end
   end
  -- must alter the nodeType if the desired MT_FLAG is not the desired state, so the
  -- caller has a means to know a record was found, but the wrong node type.
   if(@nodeType = 3 or @nodeType = 7 or @nodeType = 10) and @mtFlag = 'Y'
   begin
      set @nodeType = @nodeType+20
   end
   if(@nodeType = 23 or @nodeType = 27 or @nodeType = 30) and @mtFlag = 'N'
   begin
      set @nodeType = @nodeType -20
   end
  -- --------------------------------------- creation section ----------------------------------------    
  -- if -1, it does not exist
   if @nodeKey = -1 and @createFlag > 0
   begin
      execute @nodeKey = absp_TreeviewGetNodeInfoDataCreateSide @nodeType,@uniqueName,@parentName,@parentKey output,@policyPportName,@currencyName,@createFlag,@autoCreateFlag,@grandParentName,@grandParentType,@parentType,@note
   end
  -- --------------------------------------- creation section end ----------------------------------------    
  -- the 1 at the end tell this routine to give me my prog parent not my rport parent
  -- and the 0 is not used, for folder key for some other purpose
   if(@nodeKey <> -1)
   begin
      if( @nodeType = 12) -- absp_FindNodeParent does not support nodeType 12
		set @last = 2
	  else
		execute @last = absp_FindNodeParent @parentKey2 output,@parentType2 output,@nodeKey,@nodeType,0,1
      
      -- absp_FindNodeParent always returns 0 as parentNodeType irrespective of folder or currency
      -- So we need to set parentNodeType to 12 if it finds a currency parent node 
      if(@last = 2)		
      begin
		set @parentType2 = 12
      end
   end
  -- message '-------';
  -- message '@last = ', @last;
  -- message '@parentKey = ', @parentKey;
  -- --------------------------------------- get my parents et al section ---------------------------------------- 
   if @last = 1 or @last = 2
   begin
      if @nodeType = 12					-- absp_FindNodeCurrencyKey does not support nodeType 12
		set @currencyKey = @nodeKey		
	  else
		execute @currencyKey = absp_FindNodeCurrencyKey @nodeKey,@nodeType
      select   @currencyName = rtrim(ltrim(LONGNAME)), @currSchemaKey = CURRSK_KEY  from fldrinfo where FOLDER_KEY = @currencyKey
      select   @currSchemaName = rtrim(ltrim(LONGNAME))  from CURRINFO where CURRSK_KEY = @currSchemaKey
      if @parentType2 = 0
      begin
         select   @parentName2 = rtrim(ltrim(LONGNAME))  from fldrinfo where FOLDER_KEY = @parentKey2 and CURR_NODE = 'N'
      end
      else
      begin
		if @parentType2 = 12
         begin
            select   @parentName2 = rtrim(ltrim(LONGNAME))  from fldrinfo where FOLDER_KEY = @parentKey2 and CURR_NODE = 'Y'
         end
         else
         begin
			 if @parentType2 = 1
			 begin
				select   @parentName2 = rtrim(ltrim(LONGNAME))  from Aprtinfo where APORT_KEY = @parentKey2
			 end
			 else
			 begin
				if @parentType2 = 2
				begin
				   select   @parentName2 = rtrim(ltrim(LONGNAME))  from PPRTINFO where PPORT_KEY = @parentKey2
				end
				else
				begin
				   if @parentType2 = 3
				   begin
					  select   @parentName2 = rtrim(ltrim(LONGNAME))  from RPRTINFO where RPORT_KEY = @parentKey2
				   end
				   else
				   begin
					  if @parentType2 = 23
					  begin
						 select   @parentName2 = rtrim(ltrim(LONGNAME))  from RPRTINFO where RPORT_KEY = @parentKey2
					  end
					  else
					  begin
						 if @parentType2 = 7
						 begin
							select   @parentName2 = rtrim(ltrim(LONGNAME))  from PROGINFO where PROG_KEY = @parentKey2
						 end
						 else
						 begin
							if @parentType2 = 27
							begin
							   select   @parentName2 = rtrim(ltrim(LONGNAME))  from PROGINFO where PROG_KEY = @parentKey2
							end
						 end
					  end
				   end
				end
			end
         end
      end
   end
  -- one more thing - get grandparent key (note this will be the FIRST one in paste-link situations
  -- and in some cases does not even make sense
   if @origNodeType <> 9
   begin
      execute @last = absp_FindNodeParent @grandParentKey output,@grandParentType2 output,@parentKey2,@parentType2,0,1
      
      -- absp_FindNodeParent always returns 0 as parentNodeType irrespective of folder or currency
      -- So we need to set parentNodeType to 12 if it finds a currency parent node 
      if(@last = 2)
      begin
		set @grandParentType2 = 12
      end
      
      if @grandParentType2 = 0
      begin
         select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from fldrinfo where FOLDER_KEY = @grandParentKey and CURR_NODE = 'N'
      end
      else
      begin
		if @grandParentType2 = 12
		 begin
			select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from fldrinfo where FOLDER_KEY = @grandParentKey and CURR_NODE = 'Y'
		 end
		 else
		 begin
			 if @grandParentType2 = 1
			 begin
				select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from Aprtinfo where APORT_KEY = @grandParentKey
			 end
			 else
			 begin
				if @grandParentType2 = 2
				begin
				   select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from PPRTINFO where PPORT_KEY = @grandParentKey
				end
				else
				begin
				   if @grandParentType2 = 3
				   begin
					  select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from RPRTINFO where RPORT_KEY = @grandParentKey
				   end
				   else
				   begin
					  if @grandParentType2 = 23
					  begin
						 select   @grandParentName2 = rtrim(ltrim(LONGNAME))  from RPRTINFO where RPORT_KEY = @grandParentKey
					  end
				   end
				end
			 end
		end
      end
   end
  -- If the @currencyKey is still unknown but I was given a currencyName, attempt to fill the @currencyKey
   if @currencyKey < 1 and LEN(@currencyName) > 0
   begin
      select   @currencyKey = FOLDER_KEY  from fldrinfo where LONGNAME = @currencyName and CURR_NODE = 'Y'
   end
  -- --------------------------------------- return as best i could figure ----------------------------------------
   select   @nodeKey AS NODE_KEY, @nodeType AS NODE_TYPE, @uniqueName AS NODE_NAME, @parentKey2 AS PARENT_KEY, @parentType2 AS PARENT_TYPE, @parentName2 AS PARENT_NAME, @currencyKey AS CURRENCY_KEY, @currencyName AS CURRENCY_NAME, @currSchemaKey AS CURRSCHEMA_KEY, @currSchemaName AS CURRSCHEMA_NAME, @portId AS PORT_ID, @grandParentKey AS GRANDPARENT_KEY, @grandParentType2 AS GRANDPARENT_TYPE, @grandParentName2 AS GRANDPARENT_NAME
end




