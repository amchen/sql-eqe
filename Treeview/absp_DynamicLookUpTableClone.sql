
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DynamicLookUpTableClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_DynamicLookUpTableClone
end
go

create procedure absp_DynamicLookUpTableClone
	@lkupTbl varchar(120),
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
begin try
set nocount on

	declare @fieldNames varchar(max)
	declare @crFieldNames varchar(max)
	declare @uNameCol varchar(200)
	declare @debug int
	declare @sSql nvarchar(max)
	declare @tmpTbl varchar(140)
	declare @colNames varchar(max)
	declare @Name varchar(200)
	declare @oldEqeId int
	declare @newID int

	declare @me varchar (50)
	declare @msg varchar (256)


	set @debug = 1

	set @me = 'absp_DynamicLookUpTableClone'

	set @msg = @me + ' Starting for '  + @lkupTbl

	if (@debug = 1)	execute absp_Util_Log_Info  @msg, @me

	--create temp table for  lookup to hold old and new ids--
	set @tmpTbl ='TMP_' + dbo.trim( @lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))

	set @sSql ='create table ' + @tmpTbl  + '(OLD_VAL int , NEW_VAL int)'
	if @debug = 1 execute absp_messageEx @sSql
	execute (@sSql)

	execute absp_DataDictGetFields @fieldNames output, @lkupTbl  , 1 
	execute absp_DataDictGetFields @crFieldNames output, @lkupTbl  , 0,'T1.'

	select @uNameCol = dbo.trim(UNAMECOL) from DICTTBLX where tableName=@lkupTbl


 	--Get lookups which exist in target--
 	set @sSql='begin transaction; insert into ' + @tmpTbl + ' select distinct  T1.' + @eqeCol + ',T2.' + @eqeCol + ' from ' + @lkupTbl + ' T1,'+ dbo.trim(@targetDB)+ '..' + @lkupTbl + ' T2 '+
		   ' where T1.' +  @uNameCol +'= T2.'+@uNameCol+'; commit transaction;'
	if @debug = 1 	execute absp_messageEx @sSql
	execute (@sSql)

	--create a temp table to hold the rows that do not match--
	if exists (Select 1 from SYS.TABLES Where NAME='TMP_MISMATCHED_LOOKUPS')
		drop table TMP_MISMATCHED_LOOKUPS

	execute absp_Util_CreateTableScript @sSql output, @lkupTbl,'TMP_MISMATCHED_LOOKUPS','',0,0,0
    	set @sSQl=replace(@sSql,'IDENTITY(1,1)','') --We do not need identity
    	exec (@sSQL)

 	--For lookups which do not exists-- we need to clone
	set @sSql= 'begin transaction; insert into TMP_MISMATCHED_LOOKUPS 
			select distinct ' + @crFieldNames +' from ' + @lkupTbl +
			' T1 left outer join ' + dbo.trim(@targetDB)+ '..' + @lkupTbl +
			' T2 on T1.' + dbo.trim(@uNameCol) + '=T2.'+ dbo.trim(@uNameCol) +
			' where T2.'+ dbo.trim(@uNameCol) + ' is NULL; commit transaction;'

			
	 if @debug = 1 execute absp_messageEx @sSql
	exec(@sSql)
 
	--Clone mismatched lookup---
	--================================

 	--Insert mismatched rows in target--
 	set @sSql=  'begin transaction; insert into '+ dbo.trim(@targetDB) + '..'+   dbo.trim(@lkupTbl) +' ( '+@fieldNames+' )'+'
					select  '+@fieldNames+' from TMP_MISMATCHED_LOOKUPS; commit transaction;'
	
	if @debug = 1 	execute absp_messageEx @sSql
	exec(@sSql)
	
	--Insert old and new keys in temp table--
	set @sSql= 'begin transaction; insert into '+@tmpTbl   +
			' select T1.' + @eqeCol + ',T2.' + @eqeCol + ' from TMP_MISMATCHED_LOOKUPS T1 inner join ' 
			+ dbo.trim(@targetDB) + '..'+   dbo.trim(@lkupTbl) +
			' T2 on T1.Name = T2.Name; commit transaction;'
			  	
	if @debug=1 execute absp_messageEx @sSql
	execute (@sSql)
 
	--For IDs values 0 or NULL --
	set @sSql='delete from ' + @tmpTbl + ' where OLD_VAL=0 and NEW_VAL=0;insert into ' + @tmpTbl +' values(0,0)'
	execute(@sSql)
	set @sSql='begin transaction; insert into ' + @tmpTbl +' values(NULL,NULL); commit transaction;'
	execute(@sSql)
	set @sSql='begin transaction; insert into ' + @tmpTbl +' values(-1,-1); commit transaction;'
	execute(@sSql)
	set @sSql='if not exists (select 1 from ' + @tmpTbl + ' where OLD_VAL=1 ) begin	begin transaction; insert into ' + @tmpTbl +' values(1,1); commit transaction; end;'
	execute(@sSql)

 	if exists (Select 1 from SYS.TABLES Where NAME='TMP_MISMATCHED_LOOKUPS')
		drop table TMP_MISMATCHED_LOOKUPS

	set @msg = @me + ' Completed'

	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch