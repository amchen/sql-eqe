if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateTableBackup') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Migr_CreateTableBackup
end
go

create procedure absp_Migr_CreateTableBackup
    @thePostfix varchar(10),
    @baseTableName varchar(120),
    @tempPath varchar(248),
    @dropFirstFlag integer = 0,
    @userName varchar(100)='',
    @password varchar(100)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:	MSSQL
Purpose:

This procedure creates a backup of the given table. The table will not have any indexes
to improve performance.The tableName will have a postfix of the current version.


Returns:	Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @thePrefix 	^^ An string value for the prefix.
##PD  @thePostfix	^^ An string value for the postfix.
##PD  @baseTableName	^^ A string containing the base table name.
##PD  dropFirstFlag	^^ A flag to check if the table already exists and needs to be dropped first
*/
as

begin

	set nocount on

	declare @tmpTblNm varchar(120)
	declare @me       varchar(255)
	declare @sql      varchar(max)
	declare @msgTxt   varchar(255)
	declare @retCode  int
	declare @cnt1 bigint
	declare @cnt2 bigint

	set @retCode = 0

	set @me = 'absp_Migr_CreateTableBackup: '
	set @msgTxt = @me + 'Begin'
	execute absp_MessageEx @msgTxt

	set @baseTableName = dbo.trim(@baseTableName)
	set @tmpTblNm      = dbo.trim(@baseTableName) + dbo.trim(@thePostfix)

    --If the table is empty, no need to create backup
    select top (1)  @cnt1 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @baseTableName and INDID<2 order by indid desc,rowcnt desc   

    if (@cnt1 = 0)
    begin
        set @msgTxt = 'The table ' + @baseTableName  + ' has 0 records.'
        exec absp_MessageEx  @msgTxt
        return 0
    end

	if exists(select 1 from SYS.TABLES where NAME = @tmpTblNm)
	begin
		--Target Copy table exists--
		if @dropFirstFlag = 1
		begin
			--Drop the table first--
			set @msgTxt = 'The table ' + dbo.trim(@tmpTblNm)  + ' already exists. Drop the table first.'
			exec absp_MessageEx  @msgTxt
			execute('drop table ' + @tmpTblNm)
		end
		else
		begin
			--return doing nothing--
			set @msgTxt = 'The table ' + dbo.trim(@tmpTblNm)  + ' already exists. '
			exec absp_MessageEx  @msgTxt
			set @msgTxt =  @me+ 'End'
			exec absp_MessageEx  @msgTxt
			return 0
		end
	end

	--Create temporary table--
	if not exists(select 1 from SYS.TABLES where NAME =  @baseTableName)
	begin
		set @msgTxt = 'The table ' + dbo.trim(@baseTableName) + ' does not exist'
		exec absp_MessageEx @msgTxt
		return 1
	end

	exec absp_Util_CreateSysTableScript @sql output,  @baseTableName ,@tmpTblNm,'',0
	execute absp_MessageEx @sql
	execute(@sql)

	--Unload Base Table--
    set @tempPath = dbo.trim(@tempPath) + '\' + dbo.trim(@tmpTblNm) + dbo.trim(cast(db_id() as varchar(5))) + '.txt'
	exec @retCode = absp_Util_UnloadData 'T',@baseTableName,@tempPath,'|','','','','','',@userName,@password
	if @retCode=0
	begin
		exec @retCode = absp_Util_LoadData @tmpTblNm, @tempPath, '|'
		if @retCode=0
		begin
			select top (1)  @cnt1 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @baseTableName and INDID<2 order by indid desc,rowcnt desc  
			select top (1)  @cnt2 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @tmpTblNm and INDID<2 order by indid desc,rowcnt desc  

			if @cnt1<>@cnt2
				set @retCode = 1
   		end
	end

	set @msgTxt = @me+'End'
	execute absp_MessageEx @msgTxt
	return @retCode
end

