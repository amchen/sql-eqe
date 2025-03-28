if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DumpSystemStats') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_DumpSystemStats
end
go
create procedure absp_DumpSystemStats   @outputPath varchar(500),
					@userName varchar(100) = '',
					@password varchar(100) = ''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL

Purpose:	   This procedure dumps system statistics in the given path.

Returns: 	   Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @outputPath ^^ The path to dump lookup table data
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication

*/
as
begin

	set nocount on

	declare @cnt integer;
	declare @fileName varchar(1000)
	declare @exists int

	--Create folder to dump System statistics--
	set @outputpath = @outputpath + '\' + 'SYS_STATISTICS'
        exec @exists = absp_Util_IsValidFolder @outputpath
	if @exists = 1
		exec absp_Util_DeleteFolder @outputpath

        exec absp_util_createFolder @outputpath

	if exists(select 1 from SYS.TABLES where NAME='SYSTEMINFO')
		drop table SYSTEMINFO


	create table SYSTEMINFO (NAME char(120), CNT int);

	select @cnt = count(*) from PPRTINFO where REF_PPTKEY > 0;
	insert into SYSTEMINFO values ( 'Number of Portfolio using Reference Portfolio', @cnt);

	select @cnt = count(*) from RPRTINFO where REF_RPTKEY > 0;
	insert into SYSTEMINFO values ( 'Number of Portfolio using Reference Portfolio', @cnt);

	select @cnt = count(*) from CROLINFO;
	insert into SYSTEMINFO values ( 'Number of CROL Records', @cnt);

	select @cnt = count(*) from CURRINFO;
	insert into SYSTEMINFO values ( 'Number of Currency Schema Available', @cnt);

	select @cnt = count(*) from FLDRINFO where CURRSK_KEY > 0;
	insert into SYSTEMINFO values ( 'Number of Currency Folders Available', @cnt);

	select @cnt = max(FOLDER_KEY) from FLDRINFO;
	insert into SYSTEMINFO values ( 'Max Folder Key', @cnt);

	select @cnt = count(*) from FLDRINFO;
	insert into SYSTEMINFO values ( 'Number of Folders', @cnt);

	select @cnt = max(APORT_KEY) from APRTINFO;
	insert into SYSTEMINFO values ( 'Max APORT_KEY', @cnt);

	select @cnt = count(*) from APRTINFO;
	insert into SYSTEMINFO values ( 'Number of Accumulation Portfolio', @cnt);

	select @cnt = count(*) from RTROINFO;
	insert into SYSTEMINFO values ( 'Number of Retrocession Treaties', @cnt);

	select @cnt = max(PPORT_KEY) from PPRTINFO;
	insert into SYSTEMINFO values ( 'Max PPORT_KEY', @cnt);

	select @cnt = count(*) from PPRTINFO;
	insert into SYSTEMINFO values ( 'Number of Primary Portfolio', @cnt);

	select @cnt = max(RPORT_KEY) from RPRTINFO;
	insert into SYSTEMINFO values ( 'Max RPORT_KEY', @cnt);

	select @cnt = count(*) from RPRTINFO where MT_FLAG = 'N';
	insert into SYSTEMINFO values ( 'Number of Reinsurance Portfolio', @cnt);

	select @cnt = count(*) from RPRTINFO where MT_FLAG = 'Y';
	insert into SYSTEMINFO values ( 'Number of Reinsurance Account Portfolio', @cnt);

	select @cnt = max(PROG_KEY) from PROGINFO;
	insert into SYSTEMINFO values ( 'Max PROG_KEY', @cnt);

	select @cnt = count(*) from PROGINFO where MT_FLAG = 'N';
	insert into SYSTEMINFO values ( 'Number of Programs', @cnt);

	select @cnt = count(*) from INURINFO;
	insert into SYSTEMINFO values ( 'Number of Inuring Treaties', @cnt);

	select @cnt = count(*) from PROGINFO where MT_FLAG = 'Y';
	insert into SYSTEMINFO values ( 'Number of Reinsurance Account', @cnt);

	select @cnt = max(CASE_KEY) from CASEINFO;
	insert into SYSTEMINFO values ( 'Max CASE_KEY', @cnt);

	select @cnt = count(*) from CASEINFO where MT_FLAG = 'N';
	insert into SYSTEMINFO values ( 'Number of Cases', @cnt);

	select @cnt = count(*) from CASEINFO where MT_FLAG = 'Y';
	insert into SYSTEMINFO values ( 'Number of RAP Treaties', @cnt);

	select @cnt = count(*) from CHASINFO;
	insert into SYSTEMINFO values ( 'Number of Records in CHASINFO', @cnt);

	select @cnt = count(*) from CUST_RGN;
	insert into SYSTEMINFO values ( 'Number of Custom Regions', @cnt);

	select @cnt = count(*) from USERINFO;
	insert into SYSTEMINFO values ( 'Users', @cnt);

	select @cnt = count(*) from USERGRPS;
	insert into SYSTEMINFO values ( 'User Groups', @cnt);

	--unload SYSTEMINFO--
	set @fileName= @outputPath + '\_SYSTEMINFO.TXT'
	exec absp_Util_UnloadData
	    @unloadType = 'T',
	    @unloadText = 'SYSTEMINFO',
	    @outFile = @fileName,
	    @delimiter = '|',
	    @userName = '',
	    @password = ''

	--unload STATTRAK--
	set @fileName= @outputPath + '\_STATTRAK.TXT'
	exec absp_Util_UnloadData
	    @unloadType = 'T',
	    @unloadText = 'STATTRAK',
	    @outFile = @fileName,
	    @delimiter = '|',
	    @userName = '',
	    @password = ''


    --unload VERSION--
    set @fileName= @outputPath + '\_VERSION.TXT'
    exec absp_Util_UnloadData
        @unloadType = 'Q',
        @unloadText = 'select * from absvw_VERSION ',
        @outFile = @fileName,
        @delimiter = '|',
        @userName = '',
        @password = ''

	drop table SYSTEMINFO;

end
