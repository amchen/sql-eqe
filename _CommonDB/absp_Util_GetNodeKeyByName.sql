if exists(select * from sysobjects where ID = object_id(N'absp_Util_GetNodeKeyByName') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetNodeKeyByName
end
go
 
create procedure absp_Util_GetNodeKeyByName @nodeName varchar(255),@nodeType int,@parentKey int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the node key for a specified node name and type. For 'Case' nodes, the parentKey is
also specified as cases can have same names under different programs.


Returns:       It returns the node key for the given node name and type.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeName ^^  The longname of the node (portfolio) for which the node key is to be found.
##PD  @nodeType ^^  The type of node for which the node key is to be found.
##PD  @parentKey ^^  The key of parent node for which the node key is to be found.(Only for Case nodes).

##RD  @lastKey ^^  It returns the node key for the given node name and type. 
*/
as

begin

   set nocount on
   
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
  --Currency Schema = 20;
   declare @lastKey int
  -- This will return the key for a given node type when it finds the unique name for a given node type.
  -- Returns -1 if not found.
  -- Note Case is unique only within context of parent Program
   set @lastKey = -1
   if @nodeType = 0
   begin
	  select  @lastKey = FOLDER_KEY  from FLDRINFO where LONGNAME = @nodeName
   end
   else
   begin
   if @nodeType = 1
   begin
	 select  @lastKey = APORT_KEY  from APRTINFO where LONGNAME = @nodeName
   end
   else
   begin
	 if @nodeType = 2
	 begin
		select  @lastKey = PPORT_KEY  from PPRTINFO where LONGNAME = @nodeName
	 end
	 else
	 begin
         	if @nodeType = 3
         	begin
   	 	       select  @lastKey = RPORT_KEY  from RPRTINFO where LONGNAME = @nodeName
	 	end
	 	else
	 	begin
	 	  if @nodeType = 23
	 	  begin
			  select  @lastKey = RPORT_KEY  from RPRTINFO where LONGNAME = @nodeName
	 	  end
	 	  else
	 	  begin
			if @nodeType = 7
			begin
				 select  @lastKey = PROG_KEY  from PROGINFO where LONGNAME = @nodeName
	                end
	 		else
			begin
				if @nodeType = 27
				begin
					select  @lastKey = PROG_KEY  from PROGINFO where LONGNAME = @nodeName
				end
	                        else
				begin
					if @nodeType = 10
					begin
						select  @lastKey = CASE_KEY  from CASEINFO where LONGNAME = @nodeName and PROG_KEY = @parentKey
					end
					else
					begin
					   if @nodeType = 30
					   begin
						  select  @lastKey = CASE_KEY  from CASEINFO where LONGNAME = @nodeName and PROG_KEY = @parentKey
					   end
					   else
					   begin
						  if @nodeType = 12
						  begin
							set @lastKey = 0
							select  @lastKey = FOLDER_KEY  from FLDRINFO where LONGNAME = @nodeName
						  end
						  else
						  begin
						        if @nodeType = 20
							begin
								select  @lastKey = CURRSK_KEY  from CURRINFO where LONGNAME = @nodeName
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
 end
 -- send back the found key
  return @lastKey
end



