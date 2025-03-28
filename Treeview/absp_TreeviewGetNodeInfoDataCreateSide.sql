if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetNodeInfoDataCreateSide') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGetNodeInfoDataCreateSide;
end
go

create procedure absp_TreeviewGetNodeInfoDataCreateSide
 		@nodeType int, 							-- your node type
 		@uniqueName varchar(max),				-- your name
 		@parentName varchar(max),				-- parent name
 		@parentKey int output,					-- only needed for create OR in case of CASE where name is not unique
 		@policyPportName varchar(max),			-- used for pAolicy + site nodes
 		@currencyFolderName varchar(max),		-- currency folder
 		@createFlag int,						-- am i looking or creating"?"
 		@autoCreateFlag int,					-- if true create my parent if not already there
 		@grandParentName varchar(max) = '',	-- in case of create, what is your gparent name
 		@grandParentType int = 0,				-- in case of create, what is your gparent type
 		@parentType int = 0, 					-- in case of create, what is your parent type
		@note varchar(max) = '' 				-- in case of create, an optional note
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a new node under a given parent node and returns the node key. If the parent
node does not exist the procedure is called recursively to create the parent.


Returns:       The key of the created node.



====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^  The type of node which is to be created.
##PD  @uniqueName ^^  The longname of node which is to be created.
##PD  @parentName ^^  The parent name of the node which is to be created.
##PD  @parentKey ^^  The parent node key of node which is to be created. It is an INOUT parameter.
##PD  @policyPportName ^^  The parent pport name in case of policy nodes and sites.
##PD  @currencyFolderName ^^  The name of the parent currency folder of node which is to be created.
##PD  @createFlag ^^  A flag indicating whether the node is to be created or not.
##PD  @autoCreateFlag ^^  A flag indicating whether the parent is to be created if it does not exist.
##PD  @grandParentName ^^  The grand parent node name for the node which is to be created.
##PD  @grandParentType ^^  The type of the grandparent node for which the node is to be created.
##PD  @parentType ^^ The type of parent for the node which is to be created.
##PD  @note ^^  The user notes for the node which is to be created.

##RD @nodeKey ^^ The key of the new node.
*/

begin

   set nocount on

 -- in create mode, it will try to make you, and if the autocreate is set,
  -- it will try to make your parent if it does not exist.
   declare @nodeKey int
   declare @origNodeType int
   declare @parentKey2 int
   declare @parentType2 int
   declare @parentName2 varchar(max)
   declare @currencyKey int
   declare @currencyName varchar(max)
   declare @defaultCurrencyFolderKey int
   declare @currencyFolderKey int
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
   declare @progKey int
   declare @newKey int
   declare @mt_flag char(1)
   declare @mt_node_type int
   declare @createDt  char(14)
   declare @inceptDt  char(14)
   declare @expireDt char(10)
   declare @expireDate datetime
   declare @theDate datetime
   declare @chdate varchar(max)
   declare @suffix varchar(max)
   declare @dummyName varchar(max)


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
   set @progKey = -1
   set @parentName2 = ''
   set @currencyName = ''
   set @currSchemaName = ''
   set @policyNum = ''
   set @grandParentName2 = ''

  -- --------------------------------------- debug msg ----------------------------------------
   if 1 = 0
   begin
      execute absp_MessageEx 'absp_TreeviewGetNodeInfoDataCreateSide'
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
   -- --------------------------------------- creation section ----------------------------------------



	-- SDG__00024688, SDG__00024690 --  Procedure absp_TreeviewGetNodeInfoDataCreateSide is BAD
	-- Wait until the number of milliseconds increments and use its value as a suffix to make a dummy name
	WAITFOR DELAY '00:00:00:011'

	-- get the current date and remove all punctuation -- converts from 2010-03-04 17:44:14.180 to 	@suffix = 20100304174414180
	-- create name as 'sdg' + @suffix
	select @theDate = DATEADD (ms , 0, GETDATE())
	SELECT @suffix = convert(varchar, @theDate, 121)
	select @suffix = replace(@suffix, '-', '')
	select @suffix = replace(@suffix, '.', '')
	select @suffix = replace(@suffix, ':', '')
	select @suffix = replace(@suffix, ' ', '')
	set @dummyName = ''''+'sdg' + @suffix + cast(@@SPID as varchar) + ''''


   -- assume since you were called, it does not exist
   if @createFlag > 0
   begin
   	   if len(@uniqueName)=0
	        	return -1

    -- Get the default Currency Folder Key --
       select @defaultCurrencyFolderKey = min(FOLDER_KEY)  from FLDRINFO where CURR_NODE = 'Y'
       select @currencyFolderKey = FOLDER_KEY from FLDRINFO where CURR_NODE = 'Y' and LONGNAME = @currencyFolderName ;

    --Set parent as CurrencyFolder if parentName is not provided
      	if @parentName='default' or @parentName = ''
   		begin
   			if @currencyFolderKey <> 0
   				set @parentKey2 = @currencyFolderKey
   			else
   				set @parentKey2 = @defaultCurrencyFolderKey   -- forcing use of .Root
   		    set @parentType = 0
   		end
    -- ----------------------------------- create Folder section ----------------------------------------
    -- if Folder try to make it

      /*
      CreateFolder action:
      1.  If @parentName is not blank.    Folder is created under @parentName folder.   Else
      2.  If @currencyFolder is not blank.   Folder is created under @currencyFolder.   Else
      3.  All names are blank..  Use Default currencyFolder, which must be defined in ICMSCTRL table.
      Until we define how that table is maintained, the folder will be created under the CurrencyFolder
      where FOLDER_KEY = 1 (.Root).
      */

      if(@nodeType = 0)
      begin
         if @parentKey2 < 1
            select   @parentKey2 = FOLDER_KEY, @parentType = case when CURR_NODE = 'N' then 0 else 12 end from fldrinfo where LONGNAME = @parentName

         -- if parentName folder not found
         if @parentKey2 < 1 and @autoCreateFlag > 0
         begin
               -- then create parentFolder under the CurrencyFolder.
               execute @parentKey2 = absp_TreeviewGetNodeInfoDataCreateSide @nodeType,@parentName,'',@newKey output,@policyPportName,@currencyFolderName,@createFlag,@autoCreateFlag,'',0

               -- fail if unable to create the parent folder
               if @parentKey2 < 1
               begin
                  set @nodeKey = -1
                  return @nodeKey
               end
          end

      	-- if I get here and still do not have a valid @parentKey, it means both I was not
      	-- given a folder or currencyFolder name.  So, force use of the Default Currency Folder.
      	-- For today, use folder key 1 (.Root).   Soon, use table ICMSCTRL to
      	-- look up the default Folder Name.

         if @parentKey2 < 1
         begin
            set @parentKey2 = 1
         end

         -- Check if folder or currency folder exists with the same name
    	if exists(select 1 from FLDRINFO where LONGNAME = @uniqueName)
    	begin
    		set @nodeKey = -1
    		return @nodeKey
    	end

         --execute @folderKey = absp_GenericTableGetNewKey 'FLDRINFO','CREATE_BY',0
         execute @folderKey = absp_GenericTableGetNewKey 'FLDRINFO','LONGNAME',@dummyName
      	-- update some info for him
         exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'

         update fldrinfo
         	set LONGNAME = @uniqueName,
         		STATUS = 'ACTIVE',
         		CREATE_DAT =@createDt,
         		CURR_NODE = 'N',
         		CURRSK_KEY = 0,
         		GROUP_KEY = 0
         	where FOLDER_KEY = @folderKey


      	 -- add me to the map
         insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@folderKey,0)
         set @nodeKey = @folderKey
      end
      else if(@nodeType = 12)
      begin
      -- --------------------------------------- create Curr Folder section ----------------------------------------
      -- if Curr Folder try to make it
      	if(len(@parentName) > 0)
		    select   @currencyKey = CURRSK_KEY  from CURRINFO where LONGNAME = @parentName
		else
            select @currencyKey =  min(CURRSK_KEY)  from CURRINFO;

        if @currencyKey > 0
        begin

        	-- Check if folder exists with the same name
        	if exists(select 1 from FLDRINFO where LONGNAME = @uniqueName)
        	begin
        		return @nodeKey
        	end

        	--execute @folderKey = absp_GenericTableGetNewKey 'FLDRINFO','CREATE_BY',0
            execute @folderKey = absp_GenericTableGetNewKey 'FLDRINFO','LONGNAME',@dummyName

            -- update some info for him
			exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
            update fldrinfo
            	set LONGNAME = @uniqueName,
               		STATUS = 'ACTIVE',
               		CREATE_DAT = @createDt,
               		CURR_NODE = 'Y',
               		CURRSK_KEY = @currencyKey,
               		GROUP_KEY = 0
               	where FOLDER_KEY = @folderKey

        	-- add me to the map
           	insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(0,@folderKey,0)
           	set @nodeKey = @folderKey
         end
       end
       else if(@nodeType = 1)
       begin
       		-- --------------------------------------- create APortfolio section ----------------------------------------
			-- make APort
			-- my parent could be a folder
			if @parentKey2 < 1
            	select   @parentKey2 = FOLDER_KEY, @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from FLDRINFO where LONGNAME = @parentName

            --if parentName is not found, check for parentKey
			if @parentKey2 < 1 and @parentKey > 0
				select   @parentKey2 = FOLDER_KEY , @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from FLDRINFO where FOLDER_KEY = @parentKey

			-- if we cannot find parent, then see if we should create it
			if @parentKey2 < 1 and @autoCreateFlag > 0
            begin
			   	execute @parentKey2 =  absp_TreeviewGetNodeInfoDataCreateSide   @parentType,@parentName,
						 @grandParentName, @newKey, @policyPportName, @currencyFolderName,
						 @createFlag, @autoCreateFlag, '', 0,@grandParentType

				-- fail if unable to create the parent folder
				if @parentKey2 < 1
                begin
					    set @nodeKey = -1
					    return @nodeKey
			    end
            end
      		-- if i got a parent key we be in business; have to handle no case later
            if @parentKey2 > 0
            begin
        	    -- execute @nodeKey = absp_GenericTableGetNewKey 'APRTINFO','CREATE_BY',0
				execute @nodeKey = absp_GenericTableGetNewKey 'APRTINFO','LONGNAME',@dummyName

        		-- update some info for him
				  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
                  update Aprtinfo
                  	set LONGNAME = @uniqueName,
                  		STATUS = 'ACTIVE',
                  		CREATE_DAT = @createDt,
                  		GROUP_KEY = 1
                  	where APORT_KEY = @nodeKey

                   if @parentType = 0 or @parentType = 12
                   begin
                     insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@nodeKey,1)
                   end
             end
        end
        else  if(@nodeType = 2)
        begin
        	-- --------------------------------------- create PPortfolio section ----------------------------------------
		    -- make PPort
		    -- my parent could be a folder
			if(@parentType = 0 or @parentType = 12 or @parentType = -1) and @parentKey2 < 1
			begin
			    select   @parentKey2 = FOLDER_KEY, @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from fldrinfo where LONGNAME = @parentName
				--if parentName is incorrect, check for parentKey
				if @parentKey2 < 1 and @parentKey > 0
					select   @parentKey2 = FOLDER_KEY, @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from fldrinfo where FOLDER_KEY = @parentKey
			end

      		-- my parent could be an aport
			if(@parentType = 1 or @parentType = -1) and @parentKey2 < 1
			begin
           		select   @parentKey2 = APORT_KEY , @parentType = 1 from Aprtinfo where LONGNAME = @parentName
				if @parentKey2 < 1 and @parentKey > 0
               		select   @parentKey2 = APORT_KEY  from Aprtinfo where APORT_KEY = @parentKey

             end

			-- if we cannot find parent, then see if we should create it
			if @parentKey2 < 1 and @autoCreateFlag > 0
			begin
					execute @parentKey2 =  absp_TreeviewGetNodeInfoDataCreateSide   @parentType,@parentName,
								 @grandParentName, @newKey, @policyPportName, @currencyFolderName,
								 @createFlag, @autoCreateFlag, '', 0,@grandParentType

 				-- fail if unable to create the parent folder
				if @parentKey2 < 1
            	begin
			    	set @nodeKey = -1
			    	return @nodeKey
		    	end
 			end
            -- if i got a parent key we be in business; have to handle no case later
              if @parentKey2 > 0
              begin
              	--execute @nodeKey = absp_GenericTableGetNewKey 'PPRTINFO','CREATE_BY',0
 				execute @nodeKey = absp_GenericTableGetNewKey 'PPRTINFO','LONGNAME',@dummyName

        		-- update some info for him
				exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
                update PPRTINFO
                	set LONGNAME = @uniqueName,
                		STATUS = 'ACTIVE',
                		CREATE_DAT = @createDt,
                		GROUP_KEY = 1
                	where PPORT_KEY = @nodeKey
                if @parentType = 0 or @parentType = 12
                begin
                	insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@nodeKey,2)
                end
                if @parentType = 1
                begin
                	insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@nodeKey,2)
            	end
        	end
        end
		else if(@nodeType = 3 or @nodeType = 23)
        begin
        	-- --------------------------------------- create RPortfolio section ----------------------------------------
			-- make RPort
			-- my parent could be a folder
			if(@parentType = 0 or @parentType = 12 or @parentType = -1) and @parentKey2 < 1
			begin
           		select   @parentKey2 = FOLDER_KEY, @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from fldrinfo where LONGNAME = @parentName

           		--if parentName is incorrect, check for parentKey
            	if @parentKey2 < 1 and @parentKey > 0
               		select   @parentKey2 = FOLDER_KEY , @parentType = case when CURR_NODE = 'N' then 0 else 12 end  from fldrinfo where FOLDER_KEY = @parentKey
			end

      		-- my parent could be an aport
			if(@parentType = 1 or @parentType = -1) and @parentKey2 < 1
			begin
            	select   @parentKey2 = APORT_KEY , @parentType = 1 from Aprtinfo where LONGNAME = @parentName
				if @parentKey2 < 1 and @parentKey > 0
                	select   @parentKey2 = APORT_KEY , @parentType = 1 from Aprtinfo where APORT_KEY = @parentKey
			end

			-- if we cannot find parent, then see if we should create it
			if @parentKey2 < 1 and @autoCreateFlag > 0
            begin
				execute @parentKey2 =  absp_TreeviewGetNodeInfoDataCreateSide   @parentType,@parentName,
							 @grandParentName, @newKey, @policyPportName, @currencyFolderName,
							 @createFlag, @autoCreateFlag, '', 0,@grandParentType
				-- fail if unable to create the parent folder
				if @parentKey2 < 1
                begin
					    set @nodeKey = -1
					    return @nodeKey
			    end

            end
      		-- if i got a parent key we be in business; have to handle no case later
            if @parentKey2 > 0
            begin
            	--execute @nodeKey = absp_GenericTableGetNewKey 'RPRTINFO','CREATE_BY',0
 				execute @nodeKey = absp_GenericTableGetNewKey 'RPRTINFO','LONGNAME',@dummyName

                if(@nodeType = 3)
                begin
                	set @mt_flag = 'N'
                end
                else
                begin
                	if(@nodeType = 23)
                    begin
                    	set @mt_flag = 'Y'
                    end
                end
        		-- update some info for him
				exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
                update RPRTINFO
                	set LONGNAME = @uniqueName,
                		STATUS = 'ACTIVE',
                		CREATE_DAT = @createDt,
                		GROUP_KEY = 1,
                		MT_FLAG = @mt_flag
                	where RPORT_KEY = @nodeKey

                if @parentType = 0 or @parentType = 12
                begin
                    insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@nodeKey,@nodeType)
                end
                if @parentType = 1
                begin
                    insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@parentKey2,@nodeKey,@nodeType)
				end
			end
		end
		else if(@nodeType = 7 or @nodeType = 27)
        begin
        	-- --------------------------------------- create Program section ----------------------------------------
			-- if Program, try to make it and containing RPort as needed

            -- the mt_node_type here is actually the type for the RPORT parent
            if(@nodeType = 7)
            begin
            	set @mt_flag = 'N'
                set @mt_node_type = 3  --rport
            end
            else
            begin
                if(@nodeType = 27) --rport MT
                begin
                	set @mt_flag = 'Y'
                    set @mt_node_type = 23
                end
            end
      		-- first see of we can find our parent
      		-- if a named parent, try to get him
            if rtrim(ltrim(@parentName)) <> ''
            begin
            	select   @rportKey = RPORT_KEY  from RPRTINFO where LONGNAME = @parentName
            end
            else
            begin
        		-- if not named, but specific key passed in, get him
                if @parentKey > 0
                begin
                	select   @rportKey = RPORT_KEY  from RPRTINFO where RPORT_KEY = @parentKey
                end
            	else
            	begin
          			-- otherwise assume for a moment we want a parent named same as me
                	select   @rportKey = RPORT_KEY  from RPRTINFO where LONGNAME = @uniqueName
            	end
            end
      		-- if we cannot find it, then see if we should create the parent rport
            if @rportKey < 1
            begin
            	if @autoCreateFlag > 0
                begin
          			-- see if we can find our grandparent
          			/*
          			special case for currencyFolderName = default.   Later we need to actually look up the
          			default currencyFolderName from ICMSCTRL table.
          			*/
                    if @currencyFolderName = 'default' and LEN(@grandParentName) = 0
                    begin
                    	set @grandParentKey = @defaultCurrencyFolderKey -- forcing use of .Root
                        set @grandParentType = 0
                    end
                    else
                    begin
                    	if @grandParentType = -1
                        begin
                           set @grandParentType = 0
                        end

              			-- see if he gave me a good gparent name
                        if @grandParentType = 0
                        begin
                        	select   @grandParentKey = FOLDER_KEY  from fldrinfo where LONGNAME = @grandParentName
              				-- as a last resort see if he gave us a currency folder
                            if @grandParentKey < 1
                            begin
                            	select   @grandParentKey = FOLDER_KEY  from fldrinfo where LONGNAME = @currencyFolderName
                            end
                         end
                         else
                         begin
                         	if @grandParentType = 1
                            begin
                            	select   @grandParentKey = APORT_KEY  from Aprtinfo where LONGNAME = @grandParentName
                            end
                         end
                    end
          			-- OK, so if we found a place to hook up, we can make an rport
                    if @grandParentKey > 0
                    begin
                    	-- EXECUTE @rportKey = absp_GenericTableGetNewKey 'RPRTINFO','CREATE_BY',0
						execute @rportKey = absp_GenericTableGetNewKey 'RPRTINFO','LONGNAME',@dummyName


            			-- SDG__00023991, SDG__00023987
						--  When I send in the XML to import a Program, the RPort name created on my behalf is a blank
						if len(rtrim(ltrim(@parentName))) = 0
						begin
            				set @parentName = @uniqueName
						end

						-- update some info for him
            			exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
                        update RPRTINFO
                        	set LONGNAME = @parentName,
                        		STATUS = 'NEW',
                        		CREATE_DAT = @createDt,
                        		GROUP_KEY = 1,
                        		MT_FLAG = @mt_flag
                        	where RPORT_KEY = @rportKey
                        -- add me to the map
                        if @grandParentType = 0
                        begin
                        	insert into fldrmap(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(@grandParentKey,@rportKey,@mt_node_type)
                        end
                        else
                        begin
                        	if @grandParentType = 1
                            begin
                            	insert into APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) values(@grandParentKey,@rportKey,@mt_node_type)
                            end
                        end
                    end
				end
			end
      		-- if we have a parent then make me
       		-- if no parent and no flag to create it, then we fail
            if @rportKey > 0
            begin
            	-- EXECUTE @newKey = absp_GenericTableGetNewKey 'PROGINFO','CREATE_BY',0
				execute @newKey = absp_GenericTableGetNewKey 'PROGINFO','LONGNAME',@dummyName

            end
            else
            begin
                set @newKey = 0
            end
      		-- if i exist or got made then add me to map
            if @newKey > 0
            begin
        		-- set up some dummy defaults;  the caller should override
				exec absp_Util_GetDateString @inceptDt output,'yyyymmdd'
				exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
				set @expireDate = dateadd(dd,365,GetDate())
				exec absp_Util_GetDateString @expireDt output,'yyyymmdd', @expireDate
            	update PROGINFO
            	set LONGNAME = @uniqueName,
            		STATUS = 'ACTIVE',
            		CREATE_DAT = @createDt,
            		INCEPT_DAT = @inceptDt,
            		EXPIRE_DAT = @expireDt,
            		GROUP_KEY = 1,
            		GROUP_NAM =(select top 1 NAME from RGROUP),BROKER_NAM =(select top 1 NAME from RBROKER),PROGSTAT =(select top 1 PROGSTAT from RPRGSTAT),MT_FLAG = @mt_flag  where
                           PROG_KEY = @newKey
            	set @nodeKey = @newKey
        		-- now add me to my parent rport
            	insert into RPORTMAP(RPORT_KEY,CHILD_KEY,CHILD_TYPE) values(@rportKey,@nodeKey,@nodeType)
            end
		end
    	else if(@nodeType = 10 or @nodeType = 30)
    	begin
    		-- --------------------------------------- create Case section ----------------------------------------
    		-- if Case try to make it and containing Prog, RPort as needed

    	    if(@nodeType = 10)
           	begin
    			set @mt_flag = 'N'
           	end
           	else
           	begin
           		if(@nodeType = 30)
               	begin
           	    	set @mt_flag = 'Y'
               	end
           	end
      		-- first see of we can find our parent prog
      		-- if a named parent, try to get him
           	if rtrim(ltrim(@parentName)) <> ''
           	begin
      	   		select   @progKey = PROG_KEY  from PROGINFO where LONGNAME = @parentName
           	end
        	else
        	begin
      	  		-- if not named, but specific key passed in, get him
          		if @parentKey > 0
          		begin
      	    		select   @progKey = PROG_KEY  from PROGINFO where PROG_KEY = @parentKey
          		end
          		else
          		begin
      		  		-- otherwise assume for a moment we want a parent named same as me
             		select   @progKey = PROG_KEY  from PROGINFO where LONGNAME = @uniqueName
          		end
        	end
        	-- if we cannot find it, then see if we should create it
        	if @progKey < 1
        	begin
        		-- if we cannot find it, then see if we should create the parent prog
            	if @autoCreateFlag > 0
            	begin
          			-- see if we can find our great-grandparent for where the rport goes
          			-- try the currency folder he gave us
                	select   @grandParentKey = FOLDER_KEY  from fldrinfo where LONGNAME = @currencyFolderName
                	if @grandParentKey > 0
                	begin
          	      		set @grandParentName2 = @currencyFolderName
                	end
          			else
         			begin
            			-- if that failed then get the first one we can
            			select  top 1 @grandParentName2 = rtrim(ltrim(LONGNAME))  from fldrinfo where FOLDER_KEY > 0 order by FOLDER_KEY asc
            		end
          			-- OK, so try to recursively call myself to create the prog and rport i need
            		if(@mt_flag = 'N')
            		begin
                		execute @progKey = absp_TreeviewGetNodeInfoDataCreateSide 7,@parentName,@parentName,@newKey  OUTPUT,@policyPportName,@grandParentName2,@createFlag,@autoCreateFlag,@grandParentName2,0
            		end
            		else
            		begin
            			execute @progKey = absp_TreeviewGetNodeInfoDataCreateSide 27,@parentName,@parentName,@newKey OUTPUT,@policyPportName,@grandParentName2,@createFlag,@autoCreateFlag,@grandParentName2,0
            		end
       		end
   		end
   		if @progKey > 0
   		begin
      		-- execute @newKey = absp_GenericTableGetNewKey 'CASEINFO','CREATE_BY',0
			execute @newKey = absp_GenericTableGetNewKey 'CASEINFO','LONGNAME',@dummyName

      		if @newKey > 0
      		begin
				-- SDG__00014995 -- ICMS server creates a Case with no name if the TreatySetRequest fails
				--    Need to update the LONGNAME and other fields after creating the new key.

				-- SDG__00019722,SDG__00019749 -- Results are missing for certain case/treaty analysis submitted by ICMS
				--   only set BASE_KEY with MT_FLAG is N

				-- Fixed Defect: SDG__00021081
				-- We need to set the case as a base case only if the program has no base case set.
				-- If a base case is already set then do not update PROGINFO to set the newly created as the base case.

				if not exists (select 1 from PROGINFO where PROG_KEY = @progKey and BCASE_KEY > 0 and @mt_flag = 'N')
				begin
					update PROGINFO set BCASE_KEY = @newKey  where PROG_KEY = @progKey and @mt_flag = 'N'
				end

        		exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
        		update caseinfo
        			set PROG_KEY = @progKey,
        				LONGNAME = @uniqueName,
        				STATUS = 'ACTIVE',
        				CREATE_DAT = @createDt,
        				MT_FLAG = @mt_flag
        			where  CASE_KEY = @newKey
        	set @nodeKey = @newKey
			end
		end
	end
  end
  -- --------------------------------------- creation section ----------------------------------------
  -- SDG__00014957 -- ICMS -- WceRequest @description needs to create a USRNOTES record
   if @nodeKey > 0 and LEN(@note) > 0
   begin
    -- note:  I have to map the NODE_TYPE to a NOTE_TYPE.   Dumb that they are not the same
      insert into USRNOTES(NOTE_KEY,NOTE_TYPE,NOTES) values(@nodeKey,case @nodeType
      when 0 then 7
      when 12 then 7
      when 3 then 1
      when 23 then 1
      when 7 then 2
      when 27 then 2
      when 10 then 3
      when 30 then 3
      when 2 then 4
      when 1 then 8
   end,cast(@note as varchar(max)))
   end

   return @nodeKey
end
