if exists ( select 1 from sysobjects where name =  'absp_Util_GetNodeNameByKey' and type = 'P' ) 
begin
        drop procedure absp_Util_GetNodeNameByKey ;
end
go

create procedure absp_Util_GetNodeNameByKey @ret_NodeName varchar(max) output , @nodeKey int , @nodeType int ,  @extraKey1 int = 0, @extraKey2 int = 0
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure returns the node name for a specified node key and type. For policy, site and 
     case nodes,the extra keys are also specified.
     
    	    
Returns:       Nothing  
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_NodeName   ^^ The node name for the given node key and type. 
##PD  nodeKey  ^^  The key of the node (portfolio) for which the node name is to be found.
##PD  nodeType ^^ The type of node for which the node name is to be found.
##PD  extraKey1 ^^ The parent progKey in case of case node and portId in case of policies & sites 
##PD  extraKey2 ^^  The parent policyKey in case of a site.

*/


BEGIN 

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

  declare @nodeName varchar(max);
  declare @siteNumber varchar(255);
  declare @siteName varchar(255);
  declare @accountNumber varchar(255);
  declare @accountName varchar(255);

  -- This will return the node name for a given node type and node key when it finds the unique name 
  -- for a given node type.
  -- Returns <empty string> if not found.
  -- Note Case is unique only within context of parent Program

   set @nodeName = '';
   set @siteNumber = '';
   set @siteName = '';
   set @accountNumber = '';
   set @accountName = '';

   if @nodeType = 0 
   begin
        select @nodeName  = ltrim(rtrim (LONGNAME)) from FLDRINFO where FOLDER_KEY = @nodeKey;
   end
   else if @nodeType = 1 
   begin
        select @nodeName  = ltrim(rtrim (LONGNAME)) from APRTINFO where APORT_KEY = @nodeKey;
   end
   else if @nodeType = 2
   begin
        select @nodeName  = ltrim(rtrim (LONGNAME)) from PPRTINFO where PPORT_KEY = @nodeKey;
   end

   else if @nodeType =  3 
   begin        
         select @nodeName  = ltrim(rtrim  (LONGNAME)) from RPRTINFO where RPORT_KEY = @nodeKey;
   end
   else if @nodeType = 4 
   begin
         select @accountNumber = AccountNumber, @accountName = AccountName 
         from Account where AccountKey = @nodeKey and ExposureKey = @extraKey1;

         set @nodeName =  isnull(ltrim(rtrim(@accountNumber)),'') + ', ' + isnull(ltrim(rtrim(@accountName)),'');
    end ; 
   else if @nodeType =  23 
   begin
	select @nodeName  = ltrim(rtrim (LONGNAME)) from RPRTINFO where RPORT_KEY = @nodeKey;
   end
   else if @nodeType = 7  
   begin                
	select @nodeName  = ltrim(rtrim  (LONGNAME)) from PROGINFO where PROG_KEY = @nodeKey;
   end
   else if @nodeType =  27  
   begin
        select @nodeName  = ltrim(rtrim  (LONGNAME))  from PROGINFO where PROG_KEY = @nodeKey;
   end
   else if @nodeType = 9 
   begin
         select @siteNumber = SiteNumber, @siteName = SiteName 
         from site where SiteKey = @nodeKey and AccountKey = @extraKey1 and ExposureKey = @extraKey2;

         set @nodeName =  isnull(ltrim(rtrim(@siteNumber)),'') + ', ' + isnull(ltrim(rtrim(@siteName)),'');
    end ;             
    else if @nodeType =  10 
    begin           
        select @nodeName = ltrim(rtrim (LONGNAME))from CASEINFO where CASE_KEY = @nodeKey and PROG_KEY = @extraKey1;
    end
    else if @nodeType =  30 
    begin
        select @nodeName = ltrim(rtrim (LONGNAME)) from CASEINFO where CASE_KEY = @nodeKey and PROG_KEY = @extraKey1;
    end
    else if @nodeType =  12 
    begin
	 set @nodeName = '';
         select @nodeName = ltrim(rtrim (LONGNAME)) from FLDRINFO where FOLDER_KEY = @nodeKey;
    end
    else if @nodeType = 20 
    begin
         select @nodeName = ltrim(rtrim (LONGNAME)) from CURRINFO where CURRSK_KEY = @nodeKey;
    end ;


     set @ret_NodeName = @nodeName
end;
