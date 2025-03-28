
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_LookUpTableClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_LookUpTableClone
end
go
create procedure absp_LookUpTableClone @lkupTbl varchar(120),
										@eqeCol varchar(120),
										@targetDB varchar(130)=''
as
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:       This procedure clones the Lookup Table records for the given PortId if it does not already exist
                in the target database.
 
 Returns:       Nothing.
 
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
 
 ##PD  @portId ^^  The portId for which the lookups are to be cloned.
 ##PD  @tableName ^^  The tableName for which the loopups are to be cloned
 ##PD  @targetDB ^^  The database where the data is cloned.
  
 */
begin
set nocount on
	
	declare @tmpTbl_D0410 varchar(140)
	declare @lookupCopy varchar(140)
	declare @fieldNames varchar(max)
	declare @colList varchar(max)
	declare @colList1 varchar(max)
	declare @colList2 varchar(max)
	declare @debug int	
	declare @sSql nvarchar(max)
	declare @tmpTbl varchar(140)
	declare @colNames varchar(max)
	declare @eqeUnq varchar(100)
	declare @cntryBased char(10)
	declare @me varchar (50)
	declare @msg varchar (256)
	set @debug = 0

	set @me = 'absp_LookUpTableClone'

	set @msg = @me + ' Starting for '  + @lkupTbl
	
	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me
 
	
	set @tmpTbl_D0410='TMP_D0410_'+dbo.trim(cast (@@SPID as varchar))
	
		
	--create temp table for  lookup to hold old and new ids--
	set @tmpTbl ='TMP_' + dbo.trim( @lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))	
	set @sSql ='create table ' + @tmpTbl  + '(COUNTRY_ID char(3) COLLATE SQL_Latin1_General_CP1_CI_AS, OLD_VAL int , NEW_VAL int)'
	if @debug = 1
		execute absp_messageEx @sSql
	execute (@sSql)
			
	execute absp_DataDictGetFields @fieldNames output, @lkupTbl  , 0   
	set @colNames=' ' + @fieldNames	

 	if @lkupTbl='D0410'
		set @lookupCopy=@lkupTbl
	else
	begin
		--In case we have the same lookup schema in 2 databases with different trans_id
		--create a copy of the lookup table and update the transIds--
		set @lookupCopy=dbo.trim(@lkupTbl) + '_COPY'+'_'+dbo.trim(cast (@@SPID as varchar))
		set @sSql='begin transaction; select * into ' +  @lookupCopy + ' from ' + @lkupTbl+'; commit transaction; '
		if @debug = 1
			execute absp_messageEx @sSql
		execute(@sSql)
		
		set @sSql='begin transaction; update ' +  @lookupCopy + ' set TRANS_ID = T2.NEW_VAL from '+ @tmpTbl_D0410 + ' T2 where  TRANS_ID =T2.OLD_VAL; commit transaction; '
		if @debug = 1
			execute absp_messageEx @sSql
		execute(@sSql)

	end
	
	select @eqeUnq = EQEUNQ, @cntryBased=CNTRYBASED from DICTLOOK where tableName=@lkupTbl
	--Compare all columns execpt eqecol,dflt_row,in_list
 	set @colNames = replace(replace(replace(@colNames,', DFLT_ROW',''),', IN_LIST',''),' ' + @eqeUnq + ', ','')
  
 	set @colList = 'isnull(cast('+replace(@colNames ,',',' as varchar),'''') + isnull(cast(')+ ' as varchar),'''')'
 	set @colList1=REPLACE(@colList,'cast(','cast(T1.')
 	set @colList2 =REPLACE (@colList1,'T1.','T2.')
 	
 	--Get lookups which exist in target--
 	if @cntryBased='Y'
 		set @sSql='begin transaction; insert into ' + @tmpTbl + ' select distinct T1.COUNTRY_ID, T1.' + @eqeCol + ',T2.' + @eqeCol + ' from ' + @lookupCopy + ' T1,'+ dbo.trim(@targetDB)+ '..' + @lkupTbl + ' T2 '+
		   ' where ' +  @colList1 +'='+@colList2 +'; commit transaction; ' 
 	else
		set @sSql='begin transaction; insert into ' + @tmpTbl + ' select distinct '''', T1.' + @eqeCol + ',T2.' + @eqeCol + ' from ' + @lookupCopy + ' T1,'+ dbo.trim(@targetDB)+ '..' + @lkupTbl + ' T2 '+
		   ' where ' +  @colList1 +'='+@colList2 +'; commit transaction; ' 
	if @debug = 1
		execute absp_messageEx @sSql
	execute (@sSql)

	--create a temp table to hold the rows that do not match--
	if exists (Select 1 from SYS.TABLES Where NAME='TMP_MISMATCHED_LOOKUPS')
		drop table TMP_MISMATCHED_LOOKUPS
	
	execute absp_Util_CreateTableScript @sSql output,  @lkupTbl,'TMP_MISMATCHED_LOOKUPS','',0,0,1 
        exec(@sSql)  
 	--For lookups which do not exists-- we need to clone
	set @sSql= 'begin transaction; insert into TMP_MISMATCHED_LOOKUPS select distinct ' + @fieldNames +' from ' + @lookupCopy +
		   ' where ' + @colList + ' in (' +
		   ' select ' + @colList + ' from '+ @lookupCopy +
		   ' except '+
		   ' select ' + @colList + ' from ' + dbo.trim(@targetDB)+ '..' + @lkupTbl +
		   ' ) ; commit transaction; ' 
	 if @debug = 1
		execute absp_messageEx @sSql
	exec(@sSql)  
	
	exec absp_LookUpTableCloneRecords @lkupTbl, @targetDB
	
	--For IDs values 0 or NULL --
	set @sSql='delete from ' + @tmpTbl + ' where OLD_VAL=0 and NEW_VAL=0;insert into ' + @tmpTbl +' values('''',0,0)'
	execute(@sSql)
	set @sSql='begin transaction; insert into ' + @tmpTbl +' values('''',NULL,NULL); commit transaction; '
	execute(@sSql)
	set @sSql='begin transaction; insert into ' + @tmpTbl +' values('''',-1,-1); commit transaction; '
	execute(@sSql)
	set @sSql='begin transaction; if not exists (select 1 from ' + @tmpTbl + ' where OLD_VAL=1 and COUNTRY_ID='''')	insert into ' + @tmpTbl +' values('''',1,1); commit transaction; '
	execute(@sSql)
	
 	if exists (Select 1 from SYS.TABLES Where NAME='TMP_MISMATCHED_LOOKUPS')
		drop table TMP_MISMATCHED_LOOKUPS
		
	set @msg = @me + ' Completed' 
	
	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me
end