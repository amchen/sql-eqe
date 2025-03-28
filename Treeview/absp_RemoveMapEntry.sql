if exists(select * from sysobjects where id = object_id(N'absp_RemoveMapEntry') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop Procedure absp_RemoveMapEntry
end
 go
create procedure absp_RemoveMapEntry
@nodeKey int,
@nodeType int,
@parentKey int,
@parentType int,
@policyKey int = 0,
@siteKey int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure removes the mapping of a given node from its parent.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node whose map is to be removed.
##PD  @nodeType ^^  The type of the node whose map is to be removed.
##PD  @parentKey ^^  The parent node key of the node whose map is to be removed.
##PD  @parentType ^^  The parent node type of the node whose map is to be removed.  
##PD  @policyKey ^^  The policy key of the policy node whose map is to be removed.  
##PD  @siteKey ^^  The site key of the site node whose map is to be removed.

*/
as
begin

   set nocount on
   
   declare @commit int
   declare @lportKey int
   declare @msgText varchar(255)
   declare @progName varchar(1000)
   set @msgText = 'absp_RemoveMapEntry: remove map entry for '+str(@nodeKey)+'|'+str(@nodeType)+'|'+str(@parentKey)+'|'+str(@parentType)+'|'+str(@policyKey)+'|'+str(@siteKey)
   execute absp_messageEx @msgText
  --declare @chasKey int;
   set @lportKey = 0
   set @commit = 1
   -- node is under a folder
     -- node is under a currency folder
     -- node is under an APort
     -- program node is under a RPort
     -- program node is under a RPort
     -- case node is under a program
     -- case node is under a program
 
   if @parentType = 0
   begin
      if @nodeType = 0 or @nodeType = 1 or @nodeType = 2 or @nodeType = 3 or @nodeType = 23
      begin
         delete from FLDRMAP where FOLDER_KEY = @parentKey and
         CHILD_KEY = @nodeKey and CHILD_TYPE = @nodeType
      end
   end
   else
   begin
      if @parentType = 12
      begin
         if @nodeType = 0 or @nodeType = 1 or @nodeType = 2 or @nodeType = 3 or @nodeType = 23
         begin
            delete from FLDRMAP where FOLDER_KEY = @parentKey and
            CHILD_KEY = @nodeKey and CHILD_TYPE = @nodeType
         end
      end
      else
      begin
         if @parentType = 1
         begin
            if @nodeType = 2 or @nodeType = 3 or @nodeType = 23
            begin
               delete from APORTMAP where APORT_KEY = @parentKey and CHILD_KEY = @nodeKey and
               CHILD_TYPE = @nodeType
               delete from RTROMAP where
               CHILD_APLY = @nodeKey and
               child_type = @nodeType
            end
         end
         else
         begin
            if @parentType = 3
            begin
               if @nodeType = 7
               begin
                  delete from RPORTMAP where RPORT_KEY = @parentKey and CHILD_KEY = @nodeKey and CHILD_TYPE = @nodeType
               end
            end
            else
            begin
               if @parentType = 23
               begin
                  if @nodeType = 27
                  begin
                     delete from RPORTMAP where RPORT_KEY = @parentKey and CHILD_KEY = @nodeKey and CHILD_TYPE = @nodeType
                  end
               end
               else
               begin
                  if @parentType = 7
                  begin
                     if @nodeType = 10
                     begin
                        --update PROGINFO set PROG_KEY = 0  where BCASE_KEY = @nodeKey
                        select @progName=LONGNAME from PROGINFO where BCASE_KEY = @nodeKey
                        update proginfo set LONGNAME='dummy progName' where BCASE_KEY = @nodeKey
                        set identity_insert PROGINFO on
			insert into PROGINFO (PROG_KEY,LONGNAME,CREATE_DAT,STATUS,CREATE_BY,GROUP_KEY,LPORT_KEY,BCASE_KEY,
					      CURRNCY_ID,IMPXCHRATE,INCEPT_DAT,EXPIRE_DAT,GROUP_NAM,BROKER_NAM,PROGSTAT,PORT_ID,MT_FLAG) 
					      SELECT 0,@progName,CREATE_DAT,STATUS,CREATE_BY,GROUP_KEY,LPORT_KEY,BCASE_KEY,
					      CURRNCY_ID,IMPXCHRATE,INCEPT_DAT,EXPIRE_DAT,GROUP_NAM,BROKER_NAM,PROGSTAT,PORT_ID,MT_FLAG FROM PROGINFO  where BCASE_KEY = @nodeKey
						
			delete from PROGINFO where PROG_KEY >0  and BCASE_KEY = @nodeKey
			set identity_insert PROGINFO off
                        update CASEINFO set PROG_KEY = 0  where CASE_KEY = @nodeKey
                     end
                  end
                  else
                  begin
                     if @parentType = 27
                     begin
                        if @nodeType = 30
                        begin
                           update CASEINFO set PROG_KEY = 0  where CASE_KEY = @nodeKey
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



