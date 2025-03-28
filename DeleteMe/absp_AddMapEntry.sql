if EXISTS(select * FROM sysobjects WHERE id = object_id(N'absp_AddMapEntry') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_AddMapEntry
end
 GO
create procedure absp_AddMapEntry 	@nodeKey INT,
									@nodeType INT,
									@parentKey INT,
									@parentType INT,
									@policyKey INT = 0,
									@siteKey INT = 0,
									@rtroKey INT = 0 
 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a map entry for a given node under a parent.
If node type is policy or site, node_key is the portId and the additional
policy key and site key are also provided. 
This procedure has been modified to support multi treaty.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  nodeKey ^^  The key of the node to be mapped.
##PD  nodeType ^^  The type of the node to be mapped.
##PD  parentKey ^^  The parent node key of the node to be mapped.
##PD  parentKey ^^  The parent node type of the node to be mapped.  
##PD  policyKey ^^  The policy key of the policy node to be mapped.  
##PD  siteKey ^^  The site key of the site node to be mapped.
##PD  rtroKey ^^  The retro key of the node in RTROMAP


*/
AS
begin

   declare @progName varchar(1000)
 
   set nocount on
   
  declare @commit INT
   DECLARE @SWV_func_absp_messageEx_par01 VARCHAR(255)
   set @SWV_func_absp_messageEx_par01 = 'absp_AddMapEntry: ADD map entry for '+str(@nodeKey)+'|'+str(@nodeType)+'|'+str(@parentKey)+'|'+str(@parentType)+'|'+str(@policyKey)+'|'+str(@siteKey)+'|'+str(@rtroKey)
   EXECUTE absp_messageEx @SWV_func_absp_messageEx_par01
   set @commit = 1
   -- node is under a folder
     -- node is under a currency folder
     -- node is under an APort
     -- program node is under a RPort
     -- program node is under an MT RPort
     -- case node is under a program
     -- case node is under an MT program
   if @parentType = 0
   begin
      if @nodeType = 0 or @nodeType = 1 or @nodeType = 2 or @nodeType = 3 or @nodeType = 23
      begin
         insert into FLDRMAP values(@parentKey,@nodeKey,@nodeType)
      end
   end
   else
   begin
      if @parentType = 12
      begin
         if @nodeType = 0 or @nodeType = 1 or @nodeType = 2 or @nodeType = 3 or @nodeType = 23
         begin
            insert into FLDRMAP values(@parentKey,@nodeKey,@nodeType)
         end
      end
      else
      begin
         if @parentType = 1
         begin
            if @nodeType = 2 or @nodeType = 3 or @nodeType = 23
            begin
               insert into APORTMAP values(@parentKey,@nodeKey,@nodeType)
               if @rtroKey > 0
               begin
                  insert into RTROMAP values(@rtroKey,@nodeKey,@nodeType)
               end
            end
         end
         else
         begin
            if @parentType = 3
            begin
               if @nodeType = 7
               begin
                  insert into RPORTMAP values(@parentKey,@nodeKey,@nodeType)
               end
            end
            else
            begin
               if @parentType = 23
               begin
                  if @nodeType = 27
                  begin
                     insert into RPORTMAP values(@parentKey,@nodeKey,@nodeType)
                  end
               end
               else
               begin
                  if @parentType = 7
                  begin
                     if @nodeType = 10
                     begin
                        
                        set IDENTITY_INSERT  PROGINFO ON
			--update PROGINFO set PROG_KEY = @parentKey  where BCASE_KEY = @nodeKey
            
			-- Mantis 412 change longname to avoid unique index violation during the following insert
			select @progName=LONGNAME from PROGINFO where BCASE_KEY = @nodeKey
			update proginfo set LONGNAME='dummy progName' where BCASE_KEY = @nodeKey

			insert into PROGINFO(prog_key,Longname,Status,Create_dat,create_by,group_key,lport_key,bcase_key,currncy_id,
								 incept_dat, expire_dat, group_nam, broker_nam, progstat, mt_flag) 
							select @parentKey,@progName,Status,Create_dat,create_by,group_key,lport_key,bcase_key,currncy_id ,
								 incept_dat, expire_dat, group_nam, broker_nam, progstat, mt_flag 
								from PROGINFO where BCASE_KEY = @nodeKey 

			delete from PROGINFO where BCASE_KEY = @nodeKey and prog_key <> @parentKey
			set IDENTITY_INSERT  PROGINFO off
                        update CASEINFO set PROG_KEY = @parentKey  where CASE_KEY = @nodeKey
                     end
                  end
                  else
                  begin
                     if @parentType = 27
                     begin
                        if @nodeType = 30
                        begin
      --UPDATE PROGINFO set PROG_KEY = parentKey where BCASE_KEY = nodeKey;
                           update CASEINFO set PROG_KEY = @parentKey  where CASE_KEY = @nodeKey
                        end
                     end
                     else
                     begin
                        set @commit = 0
                     end
                  end
               end
            end
         end
      end
   end
   
end



