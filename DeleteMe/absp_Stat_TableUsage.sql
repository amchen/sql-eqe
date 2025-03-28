if exists(select * FROM SYSOBJECTS WHERE id = object_id(N'absp_Stat_TableUsage') and OBJECTPROPERTY(Id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_Stat_TableUsage
end
go 

create procedure absp_Stat_TableUsage @debugFlag INT = 0  -- always last variable in list
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates 2 tables and populates them as follows:-
1) STATINFO containing data of all the INFO tables
2) STATMAPS containing data from all the MAP tables.


Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @debugFlag ^^  The debug Flag


*/
as
begin
 
   set nocount on
   
 /*
  Put a description of what this does here.
  This is a sample starter for new procedures

  */
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @sql varchar(255)
   declare @folderInfo int
   declare @aportInfo int
   declare @pportInfo int
   declare @rportInfo int
   declare @progInfo int
   declare @caseInfo int
   declare @pofInfo int
   declare @rtroInfo int
   declare @inurInfo int
   declare @chasInfo int
   declare @currInfo int
   declare @crolInfo int
   declare @userInfo int
   declare @groupInfo int
   declare @mt_rport int
   declare @mt_prog int
   declare @mt_case int
   declare @msgText varchar(255)
     -- initialize standard items
   set @me = 'absp_Stat_TableUsage: ' -- set to my name = name_of_proc plus ': '
   set @debug = @debugFlag -- initialize
  -- set the node types
   set @folderInfo = 0
   set @aportInfo = 1
   set @pportInfo = 2
   set @rportInfo = 3
   set @progInfo = 7
   set @caseInfo = 10
   set @pofInfo = 8
   set @rtroInfo = 101
   set @inurInfo = 107
   set @chasInfo = 20
   set @currInfo = 200
   set @crolInfo = 201
   set @userInfo = 202
   set @groupInfo = 203
   set @mt_rport = 23
   set @mt_prog = 27
   set @mt_case = 30
  -- ------------ begin --------------------
   if @debug > 0
   begin
      set @msgText = @me+'starting'
      execute absp_messageEx @msgText
   end
  -- new tables to start
   if exists(select  1 from sysobjects where name = 'STATINFO' and type = 'U')
   begin
      drop table STATINFO
   end
   if exists(select  1 from sysobjects where name = 'STATMAPS' and type = 'U')
   begin
      drop table STATMAPS
   end
  -- create new tables
   create table STATINFO
   (
      NODE_TYPE int   null,
      NODE_KEY int   null,
      LONGNAME char(120)   null,
      STATUS char(10)   null,
      CREATE_DAT char(14)   null,
      CREATE_BY int   null,
      GROUP_KEY int   null, -- copy over Treeview INFO tables
      XTRAKEY1 int   null,
      XTRAKEY2 int   null
   )
   create table STATMAPS
   (
      NODE_TYPE int   null,
      NODE_KEY int   null,
      CHILD_KEY int   null,
      CHILD_TYPE int   null,
      XTRAKEY1 int   null
   )
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @folderInfo,FOLDER_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,0,0 from
   FLDRINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @aportInfo,APORT_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,REF_APTKEY,0 from
   APRTINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @pportInfo,PPORT_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,REF_PPTKEY,0 from
   PPRTINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @rportInfo,RPORT_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,REF_RPTKEY,0 from
   RPRTINFO where mt_flag = 'N'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @mt_rport,RPORT_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,REF_RPTKEY,0 from
   RPRTINFO where mt_flag = 'Y'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @progInfo,PROG_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,LPORT_KEY,0 from
   PROGINFO where mt_flag = 'N'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @mt_prog,PROG_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,GROUP_KEY,LPORT_KEY,0 from
   PROGINFO where mt_flag = 'Y'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @caseInfo,CASE_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,0,PROG_KEY,TTYPE_ID from
   CASEINFO where mt_flag = 'N'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @mt_case,CASE_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,0,PROG_KEY,TTYPE_ID from
   CASEINFO where mt_flag = 'Y'
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @rtroInfo,RTRO_KEY,LONGNAME,'','','',
      TTYPE_ID,INUR_ORDR,REIN_COUNT from
   RTROINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @inurInfo,INUR_KEY,'','','',
      str(PROG_KEY),TTYPE_ID,INUR_ORDR,REIN_COUNT from
   INURINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @chasInfo,CHAS_KEY,'','','','',
      FILE_TYPE,FILE_KEY,CURRSK_KEY from
   CHASINFO
  
  -- other INFOs not in main treeview
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @currInfo,CURRSK_KEY,LONGNAME,STATUS,
      CREATE_DAT,CREATE_BY,REV_ID,0,0 from
   CURRINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @crolInfo,CALCR_ID,LONGNAME,'','','',
      0,0,0 from
   CROLINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @userInfo,USER_KEY,USER_NAME,STATUS,'','',
      GROUP_KEY,0,0 from
   USERINFO
   
   insert into STATINFO(NODE_TYPE,NODE_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,XTRAKEY1,XTRAKEY2)
   select  @groupInfo,GROUP_KEY,GROUP_NAME,'','','',
      GROUP_KEY,0,0 from
   USERGRPS
   
   
  -- Maps
   insert into STATMAPS(NODE_TYPE,NODE_KEY,CHILD_KEY,CHILD_TYPE,XTRAKEY1)
   select  @folderInfo,FOLDER_KEY,CHILD_KEY,CHILD_TYPE,0 from
   FLDRMAP
   
   insert into STATMAPS(NODE_TYPE,NODE_KEY,CHILD_KEY,CHILD_TYPE,XTRAKEY1)
   select  @aportInfo,APORT_KEY,CHILD_KEY,CHILD_TYPE,0 from
   APORTMAP
   
   insert into STATMAPS(NODE_TYPE,NODE_KEY,CHILD_KEY,CHILD_TYPE,XTRAKEY1)
   select  @rportInfo,RPORT_KEY,CHILD_KEY,CHILD_TYPE,0 from
   RPORTMAP
   
   insert into STATMAPS(NODE_TYPE,NODE_KEY,CHILD_KEY,CHILD_TYPE,XTRAKEY1)
   select  @mt_rport,RPORT_KEY,CHILD_KEY,CHILD_TYPE,0 from
   RPORTMAP
   
   
  -- ------------ end --------------------
   if @debug > 0
   begin
      set @msgText = @me+'complete'
      execute absp_messageEx @msgText
   end
end



