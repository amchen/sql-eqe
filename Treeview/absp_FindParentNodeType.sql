if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindParentNodeType') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_FindParentNodeType
end
go

create procedure absp_FindParentNodeType @parentNodeName varchar(255),@childNodeType int 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the parent nodeType for the given parentName and childNodeType.

                 
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@parentNodeName ^^  The longname of the parent 
##PD  @@childNodeType ^^  The type of chile node 
 */
as

begin

      set nocount on
      
      declare @nodeKey int;
	  declare @parentType int;
      set @nodeKey=-1;
   
      if @childNodeType=0 or @childNodeType=1--If Folder/Aport, Parent will be a folder--
      begin
            select @nodeKey=Folder_Key, @parentType = case when CURR_NODE = 'N' then 0 else 12 end from FldrInfo where LongName=@parentNodeName 
      end
      else if @childNodeType=2 or @childNodeType=23--If Pport/Rport, Parent will be a folder/Aport--
      begin
            select @nodeKey=Folder_Key, @parentType = case when CURR_NODE = 'N' then 0 else 12 end from FldrInfo where LongName=@parentNodeName 
            if @nodeKey=-1
                  select @nodeKey=Aport_Key, @parentType = 1 from AprtInfo where LongName=@parentNodeName 
      end
      if @childNodeType=27--If Program, Parent will be an Rport--
      begin
            select @nodeKey=Rport_Key, @parentType = 23 from RprtInfo where LongName=@parentNodeName 
      end
      if @childNodeType=30--If Case, Parent will be an Program--
      begin
            select @nodeKey=Prog_Key, @parentType = 27 from ProgInfo where LongName=@parentNodeName 
      end
      
      select isnull(@parentType, -1) as NodeType
end

