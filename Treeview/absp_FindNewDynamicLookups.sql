if exists(select * from SYSOBJECTS where ID = object_id(N'absp_FindNewDynamicLookups') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_FindNewDynamicLookups
end
go

create procedure absp_FindNewDynamicLookups @targetDB varchar(130)
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
	declare @userNameCol varchar(120)
	declare @lkupTbl varchar(120)
	declare @debug int
	declare @me varchar (50)
	declare @msg varchar (256)

	set @debug = 0
	set @me = 'absp_FindNewDynamicLookups'

	set @msg = @me + ' Starting'

	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me


	if @targetDB=''
		return 0

	--Enclose within square brackets--
	execute absp_getDBName @targetDB out, @targetDB


	--Exit if same database--
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
		create table ##TMP_LKUPCLONE_STATUS (DBNAME varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS,SP_ID smallint,UPDATE_STATUS varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS)
	end

	insert into ##TMP_LKUPCLONE_STATUS values (@targetDB,@@SPID ,'')

	--Drop all temporary lookup tables--
	exec absp_DropTmpLookupTables


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

	--Handle each lookup table --
	declare cursLookup  cursor fast_forward  for  select distinct TableName, EqeCol, UnameCol
	        from DictTblX T1
		where TableName in (select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Lookup'))
	open cursLookup
	fetch next from cursLookup into  @lkupTbl ,@eqeCol,@userNameCol
	while @@fetch_status = 0
	begin
		exec absp_DynamicLookUpTableClone @lkupTbl,@eqeCol,@targetDB

		fetch next from cursLookup into  @lkupTbl,@eqeCol,@userNameCol

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

