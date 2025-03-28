if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNewLookups') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_FindNewLookups
end
go
create procedure absp_FindNewLookups @targetDB varchar(130)
as
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:       This procedure checks if the sourceDB uses any new lookup. It clones the new lookups records
                in the target database.

 Returns:       An interger signifying that the lookups are already cloned or not

 ====================================================================================================
 </pre>
 </font>
 ##BD_END

 ##PD  @targetDB ^^  The database where the data is cloned.

 */

begin
set nocount on

	declare @sSql nvarchar(max)
	declare @eqeCol varchar(120)
	declare @userCol varchar(120)
	declare @userNameCol varchar(120)
	declare @oldEqeId int
	declare @lkupTbl varchar(120)
	declare @byCountry char(1)
	declare @lkupType char(1)
	declare @debug int
	declare @rule2 varchar(8000)
	declare @rule3 varchar(8000)
	declare @rule4 varchar(8000)
	declare @colName varchar(120)
	declare @colName2 varchar(120)
	declare @me varchar (20)
	declare @msg varchar (256)
	set @debug = 0
	set @me = 'absp_FindNewLookups'

	set @msg = @me + ' Starting'

	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me


	if @targetDB=''
		return 0

	--Enclose within square brackets--
	execute absp_getDBName @targetDB out, @targetDB


	----Exit if same database--
	if substring(@targetDB,2,len(@targetdb)-2)=DB_NAME()
		return 0



	--create a global temporary table to keep a check if lookups are getting updated (to prevent simultaneous lookup clone)
	if exists (select 1 from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME='##TMP_LKUPCLONE_STATUS')
	begin
		--if exists then check if lookups are already cloned or not--
		if exists(select 1 from ##TMP_LKUPCLONE_STATUS where DBNAME =@targetDB and SP_ID=@@SPID and UPDATE_STATUS='CLONED' )
		return 0 -- lookup temp tables already exists
	end
	else
	begin
		begin try
		create table ##TMP_LKUPCLONE_STATUS (DBNAME varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS,SP_ID smallint,UPDATE_STATUS varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS)
		end try
		begin catch
			if exists(select 1 from ##TMP_LKUPCLONE_STATUS where DBNAME =@targetDB and SP_ID=@@SPID and UPDATE_STATUS='CLONED' )
				return 0 -- lookup temp tables already exists
		end catch
	end

	insert into ##TMP_LKUPCLONE_STATUS values (@targetDB,@@SPID ,'')

	--Drop all temporary lookup tables--
	exec absp_DropTmpLookupTables

	--Create Rules table
	create table #TMP_RULE (TABLENAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, RULE2 varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS,RULE3 varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS,RULE4 varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS)

	--Get new lookups and clone them before this update LOOKUPSTATUS table  to prevent concurrent updation--
	while(1=1)
	begin
		if not exists (select 1 from ##TMP_LKUPCLONE_STATUS where UPDATE_STATUS ='LOCKED' and DBNAME =@targetDB )
		begin
			update ##TMP_LKUPCLONE_STATUS set UPDATE_STATUS ='LOCKED' where DBNAME=@targetDB AND SP_ID =@@SPID
			break
		end

		execute absp_Util_Log_Info  'Another Copy Paste Process is updating lookup tables under this Currency Folder. See ##TMP_LKUPCLONE_STATUS table. Retrying...', @me
		exec absp_Util_Sleep 50
	end

	--Handle D0410 first--
	execute absp_LookUpTableClone 'D0410','TRANS_ID',@targetDB

	--Handle other lookups--
	declare cursLookup  cursor fast_forward for
		select distinct T1.TABLENAME, T2.TYPE,T2.EQECOL ,T2.USERCOL,T2.UNAMECOL
	        from DICTLOOK T1,DICTTBLX T2
			where T1.TABLENAME=T2.TABLENAME
			 and T2.TABLENAME not in (select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Lookup'))
	open cursLookup
	fetch next from cursLookup into  @lkupTbl ,@lkupType,@eqeCol,@userCol,@userNameCol
	while @@fetch_status = 0
	begin
		set @rule2=''
		set @rule3=''
		set @rule4=''

		--Insert rules
		if @lkupType = 'A' or @lkupType = 'P'
		begin

				--set @rule2 = 'rtrim(cast(T1.TRANS_ID as char(10)))+ isnull(dbo.trim(T1.' + @userCol + '),'''') + isnull(dbo.trim(T1.'+ @userNameCol+'),'''')'
				--set @rule3 = 'rtrim(cast(T1.TRANS_ID as char(10)))+ isnull(dbo.trim(T1.' + @userNameCol+'),'''') '
				--set @rule4 =  @userCol

				set @rule2 = ' T1.TRANS_ID = T2.TRANS_ID and T1.' + @userCol + ' = T2.' + @userCol + ' and T1.'+ @userNameCol + ' = T2.' + @userNameCol
				set @rule3 = ' T1.TRANS_ID = T2.TRANS_ID and T1.' + @userNameCol +  ' = T2.' + @userNameCol
				set @rule4 = @userCol
		end

		else if @lkupTbl='CIL'
		begin
				--set @rule2 = 'isnull(dbo.trim(T1.COVER_TYPE),'''')+ rtrim(cast(T1.TRANS_ID as char(10)))+ isnull(dbo.trim(T1.U_COVER_ID),'''')+ isnull(dbo.trim(T1.U_COV_NAME),'''')'
				--set @rule3 =  'isnull(dbo.trim(T1.COVER_TYPE),'''')+ rtrim(cast(T1.TRANS_ID as char(10)))+ isnull(dbo.trim(T1.U_COV_NAME),'''')'
				--set @rule4 =  'U_COVER_ID'

				set @rule2 = ' T1.COVER_TYPE = T2.COVER_TYPE and T1.TRANS_ID = T2.TRANS_ID and T1.U_COVER_ID = T2.U_COVER_ID and T1.U_COV_NAME = T2.U_COV_NAME '
				set @rule3 = ' T1.COVER_TYPE = T2.COVER_TYPE and T1.TRANS_ID = T2.TRANS_ID and T1.U_COV_NAME = T2.U_COV_NAME '
				set @rule4 = 'U_COVER_ID'
		end

		else if @lkupTbl='DTL' or @lkupTbl='LTL' or @lkupTbl='PTL' or @lkupTbl='SHIFTL'
		begin
				if @lkupTbl ='DTL'
					set @colName = 'DEDUCT_NO'
				else if @lkupTbl ='LTL'
					set @colName='LIMIT_NO'
				else if @lkupTbl ='PTL'
					set @colName='PERIL_ID'
				else if @lkupTbl ='SHIFTL'
					set @colName='SHIFT_NO'

				set @rule2 = ' T1.TRANS_ID = T2.TRANS_ID and T1.' + @userCol + ' = T2.' + @userCol + ' and T1.' + @colName + ' = T2.' + @colName + ' and T1.' + @userNameCol + ' = T2.' + @userNameCol
				set @rule3 = ' T1.TRANS_ID = T2.TRANS_ID and T1.' + @colName + ' = T2.' + @colName + ' and T1.' + @userNameCol + ' = T2.' + @userNameCol
				set @rule4 = @userCol
		end

		else if @lkupTbl='EOTDL' or @lkupTbl='WOTDL' or @lkupTbl='FOTDL'
		begin
				if @lkupTbl ='EOTDL'
				begin
					set @colName = 'E_OCCPY_NO'
					set @colName2 = 'E_OCC_DESC'
				end
				else if  @lkupTbl ='FOTDL'
					begin
					set @colName = 'F_OCCPY_NO'
					set @colName2 = 'F_OCC_DESC'
				end
				else if  @lkupTbl ='WOTDL'
				begin
					set @colName = 'W_OCCPY_NO'
					set @colName2 = 'W_OCC_DESC'
				end

				--set @rule2 = 'isnull(dbo.trim(T1.COUNTRY_ID),'''') + isnull(rtrim(cast(T1.' + @colName + ' as Char(10))),'''')+rtrim(cast(T1.TRANS_ID as Char(10))) +isnull(dbo.trim(T1.'+ @userCol+'),'''') +  isnull(dbo.trim(T1.' +@colName2+ '),'''')'
				--set @rule3 =' isnull(dbo.trim(T1.COUNTRY_ID),'''') + isnull(rtrim(cast(T1.' + @colName + ' as Char(10))),'''')+rtrim(cast(T1.TRANS_ID as Char(10)))+ isnull(dbo.trim(T1.'+@colName2+'),'''')'
				--set @rule4 =   @userCol

				set @rule2 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.TRANS_ID = T2. TRANS_ID and T1.' + @colName + ' = T2.' + @colName + ' and T1.'+ @userCol + ' = T2. ' + @userCol + ' and T1.' + @colName2 + ' = T2.' + @colName2
				set @rule3 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.TRANS_ID = T2. TRANS_ID and T1.' + @colName + ' = T2.' + @colName + ' and T1.' + @colName2 + ' = T2.' + @colName2
				set @rule4 = @userCol
		end

		else if @lkupTbl='ESDL' or @lkupTbl='WSDL' or @lkupTbl='FSDL'
		begin
				if @lkupTbl ='ESDL'
					set @colName = 'USER_EQ_ID'
				else if  @lkupTbl ='FSDL'
					set @colName = 'USER_FD_ID'

				else if  @lkupTbl ='WSDL'
					set @colName = 'USER_WS_ID'

				/*
				set @rule2 = 'isnull(dbo.trim(T1.COUNTRY_ID),'''') + rtrim(cast(T1.TRANS_ID as Char(10))) + isnull(dbo.trim(T1.'+ @colName+'),'''')
					+ isnull(dbo.trim(T1.REGION),'''')+isnull(dbo.trim(T1.COMP_DESCR),'''')+isnull(dbo.trim(T1.STORY_MIN),'''')+isnull(dbo.trim(T1.STORY_MAX),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_1),'''')+isnull(dbo.trim(T1.STR_PRCT_1),'''')+isnull(dbo.trim(T1.STR_TYPE_2),'''')+isnull(dbo.trim(T1.STR_PRCT_2),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_3),'''')+isnull(dbo.trim(T1.STR_PRCT_3),'''')+isnull(dbo.trim(T1.STR_TYPE_4),'''')+isnull(dbo.trim(T1.STR_PRCT_4),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_5),'''')+isnull(dbo.trim(T1.STR_PRCT_5),'''')'
				set @rule3 = 'isnull(dbo.trim(T1.COUNTRY_ID),'''') + rtrim(cast(T1.TRANS_ID as Char(10)))
					+ isnull(dbo.trim(T1.REGION),'''')+isnull(dbo.trim(T1.COMP_DESCR),'''')+isnull(dbo.trim(T1.STORY_MIN),'''')+isnull(dbo.trim(T1.STORY_MAX),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_1),'''')+isnull(dbo.trim(T1.STR_PRCT_1),'''')+isnull(dbo.trim(T1.STR_TYPE_2),'''')+isnull(dbo.trim(T1.STR_PRCT_2),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_3),'''')+isnull(dbo.trim(T1.STR_PRCT_3),'''')+isnull(dbo.trim(T1.STR_TYPE_4),'''')+isnull(dbo.trim(T1.STR_PRCT_4),'''')
					+ isnull(dbo.trim(T1.STR_TYPE_5),'''')+isnull(dbo.trim(T1.STR_PRCT_5),'''')'
				set @rule4 =  @userCol
				*/

				set @rule2 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.TRANS_ID = T2. TRANS_ID and T1.' + @colName + ' = T2.' + @colName + ' and ' +
						' T1.REGION = T2.REGION and T1.COMP_DESCR = T2.COMP_DESCR  and T1.STORY_MIN = T2.STORY_MIN and T1.STORY_MAX = T2.STORY_MAX and ' +
						' T1.STR_TYPE_1 = T2.STR_TYPE_1 and T1.STR_PRCT_1 = T2.STR_PRCT_1 and T1.STR_TYPE_2 = T2.STR_TYPE_2 and T1.STR_PRCT_2 = T2.STR_PRCT_2 and ' +
					 	' T1.STR_TYPE_3 = T2.STR_TYPE_3 and T1.STR_PRCT_3 = T2.STR_PRCT_3 and T1.STR_TYPE_4 = T2.STR_TYPE_4 and T1.STR_PRCT_4 = T2.STR_PRCT_4 and ' +
						' T1.STR_TYPE_5 = T2.STR_TYPE_5 and T1.STR_PRCT_5 = T2.STR_PRCT_5 '
				set @rule3 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.TRANS_ID = T2. TRANS_ID and ' +
						' T1.REGION = T2.REGION and T1.COMP_DESCR = T2.COMP_DESCR  and T1.STORY_MIN = T2.STORY_MIN and T1.STORY_MAX = T2.STORY_MAX and ' +
						' T1.STR_TYPE_1 = T2.STR_TYPE_1 and T1.STR_PRCT_1 = T2.STR_PRCT_1 and T1.STR_TYPE_2 = T2.STR_TYPE_2 and T1.STR_PRCT_2 = T2.STR_PRCT_2 and ' +
						' T1.STR_TYPE_3 = T2.STR_TYPE_3 and T1.STR_PRCT_3 = T2.STR_PRCT_3 and T1.STR_TYPE_4 = T2.STR_TYPE_4 and T1.STR_PRCT_4 = T2.STR_PRCT_4 and ' +
						' T1.STR_TYPE_5 = T2.STR_TYPE_5 and T1.STR_PRCT_5 = T2.STR_PRCT_5 '
				set @rule4 =  @userCol
		end

		else if @lkupTbl='RLOBL'
		begin
				set @rule2 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.R_LOB_ID = T2.R_LOB_ID and T1.FILETYP_ID = T2.FILETYP_ID '
				set @rule3 = ' T1.COUNTRY_ID = T2.COUNTRY_ID and T1.R_LOB_NO = T2.R_LOB_NO and T1.TRANS_ID = T2.TRANS_ID and T2.LOB_NAME = T2.LOB_NAME '
				set @rule4 = 'R_LOB_ID'

		end

		insert into #TMP_RULE values(@lkupTbl,@rule2,@rule3,@rule4 )

		exec absp_LookUpTableClone @lkupTbl,@eqeCol,@targetDB
		fetch next from cursLookup into  @lkupTbl,@lkupType,@eqeCol,@userCol,@userNameCol

	end
	close cursLookup
	deallocate cursLookup

	update  ##TMP_LKUPCLONE_STATUS set UPDATE_STATUS='CLONED'  where DBNAME=@targetDB and SP_ID =@@SPID

	set @msg = 'After ##TMP_LKUPCLONE_STATUS set UPDATE_STATUS = CLONED'

	execute absp_Util_Log_Info  @msg, @me

	set @msg = @me + ' Completed'

	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me

	return 1
end
