if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ReloadTableEx') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_ReloadTableEx
end
go

create procedure absp_Migr_ReloadTableEx
    @tableName    varchar(100),
    @tempPath     varchar(248) = '',
    @newTableName varchar(100) = '',
	@userName varchar(100) = '',
	@password varchar(100) = ''
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

      This procedure modifies the structure of the given table (newTableName), migrates data into the
      new columns with the default values and returns 0 on success, non-zero on failure.

Returns:       0 on success, non-zero on failure.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^ The table whose structure is to be copied to newTable
##PD  @tempPath ^^  The path of the temporary file used for migration
##PD  @newTableName ^^ The table for which migration will take place
##PD  @userName ^^ The userName - required in case of SQL authentication
##PD  @password ^^ The password - required in case of SQL authentication

*/

begin

set nocount on

/*
    This function will create a temp table from a base table in DICTCOL,
    unload the base table with new columns, then reload the data back into the temp table.
    Also creates indexes, delete temp files, and output debug messages.

    Returns 0 on success, non-zero on failure.
*/

    declare @retCode  integer;
    declare @colNames varchar(max);
    declare @tmpPath  varchar(512);
    declare @cnt1 bigint
    declare @cnt2 bigint
    declare @postfix varchar(10)
    declare @sql varchar(1000)
    declare @bckupTblName varchar(130)

    set @retCode = 99;

    if not exists ( select 1 from Sys.Tables where NAME = @tableName )
    begin
        exec  @retCode = absp_Migr_CreateTable @tableName, @newTableName ;
    end
    else
    begin
        --Fixed defect SDG__00025958--
        --Get record count--
       	select top (1)  @cnt1 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @tableName and INDID<2 order by indid desc,rowcnt desc  

        if(@newTableName = '')
            set @bckupTblName = dbo.trim(@tableName)
        else
            set @bckupTblName = dbo.trim(@newTableName)

        exec absp_Util_GetDBVersionCol  @postfix output,'WCEVERSION'
        set @postfix = '_' + replace(@postfix,'.','_')

        exec @retCode = absp_Migr_CheckTableSchemaFunc @tableName, @newTableName ;
        --Returns 0   Success, exact match
        --        1   Table schema mismatch
        --        2   Index schema mismatch
        --        3   Table and Index schema mismatch
        --        4   Table does not exist in the database
        if (@retCode = 1 or @retCode = 3)
	    begin
            --Create Backup--
            execute @retCode = absp_Migr_CreateTableBackup @postfix, @bckupTblName, @tempPath, 1, @userName, @password
            if @retCode<>0
            begin
                exec absp_Migr_RaiseError 1, 'Table backup has not been created successfully!'
                return @retCode
            end
            -----------------

            exec absp_Migr_GenReloadTableList @colNames out, @tableName, 1, @newTableName ;

            if (@tempPath = '')
			begin
                exec absp_Util_GetWceDBDir @tmpPath output ;
			end
            else
			begin
                set @tmpPath = @tempPath;
			end;

            exec @retCode = absp_Migr_ReloadTable @tableName, @colNames, '', @tmpPath, 1, 1, 1, @newTableName, @userName, @password;
        end

        -- Check if this is a snapshot table
        -- absp_Migr_SnapshotTable will recursively
        -- call absp_Migr_ReloadTableEx with newTableName filled in
        if (@newTableName = '')
	    begin
            exec absp_Migr_SnapshotTable @tableName, @tempPath, 1, @userName, @password;
        end

        --Fixed defect SDG__00025958--
        --Check Record count
        select top (1)  @cnt2 =  ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @tableName and INDID<2 order by indid desc,rowcnt desc  
			
        if @cnt1<>@cnt2
        begin
		    exec absp_Migr_RaiseError 1, 'Table record counts before and after migration does not match!'
		    return 1
        end
        else if @retCode=0
        begin
   		    --If successful, drop backup--
   		    set @sql = 'if exists (select 1 from SYS.TABLES where NAME = ''' +
                       dbo.trim(@bckupTblName) + dbo.trim(@postfix) + ''') drop table ' +
                       dbo.trim(@bckupTblName) + dbo.trim(@postfix)
            exec absp_messageEx @sql
   		    execute(@sql)
        end
   end

   return @retCode;

end;
