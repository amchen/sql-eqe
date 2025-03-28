if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_CheckTableSchemaFunc') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CheckTableSchemaFunc
end
go

create Procedure absp_Migr_CheckTableSchemaFunc
    @tblName  varchar(120),
    @newTable varchar(120) = ''
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

     This procedure compares the actual table/index schemas for the given newTable with the data
     dictionary schema(DICTTBL,DICTCOL, DICTIDX) for the given tblName and returns 0 if correct else a return code.

Returns:      0 if actual schema matches with the data dictionary of the application.
	      1 if actual schema does not match with the data dictionary schema.
	      2 if there is a mismatch in the index scemas
	      3 if there is a table and index schema mismatch
	      4 if the table does not exist in the database.
=================================================================================
</pre>
</font>
##BD_END

##PD  @tblName ^^ The table name for which the actual schema is to be compared to the data dictionary schema
##PD  @newTable ^^ A table whose schema is to be compared with a given table schema.
*/

begin
/*
    This proc checks actual table schema against the data dictionary (DICTTBL, DICTCOL).

    Returns 0   Success, exact match
            1   Table schema mismatch
            2   Index schema mismatch
            3   Table and Index schema mismatch
            4   Table does not exist in the database
*/

    set nocount on

    declare @retCode  integer
    declare @sText    varchar(max)
    declare @sDict    varchar(max)
    declare @sSys     varchar(max)
    declare @baseName varchar(120)
    declare @newName  varchar(120)
	declare @sMsg     varchar(512)

    set @retCode = 0
    set @sText = ''
	set @sMsg =  'absp_Migr_CheckTableSchemaFunc - Begin - ' + @tblName
    exec absp_MessageEx @sMsg

    -- Check the table schema
    set @baseName = rtrim(@tblName)
    if  (@newTable = '')
	begin
        set @newName = rtrim(@tblName)
	end
    else
	begin
        set @newName = rtrim(@newTable)
    end

    if exists ( select 1 from SYS.TABLES where NAME = @newName )
	begin
        -- Get the datadict schema
        exec absp_Util_CreateTableScript @sDict out, @baseName, @newName

        -- Get the system schema
        exec absp_Util_CreateSysTableScript @sSys out, @newName, @newName

        if (@sDict <> @sSys)
		begin
			set @sMsg = '**** Table ' + @newName + ' schema does not match! ****'
            exec absp_MessageEx @sMsg
            -- Table schema mismatch
            set @retCode = @retCode + 1
            set @sText = @sText + 'DICT: ' + @sDict
            set @sText = @sText + 'SYST: ' + @sSys
        end

        -- Get the datadict schema
        exec absp_Util_CreateTableScript @sDict out, @baseName, @newName, '', 2

        -- Get the system schema
        exec absp_Util_CreateSysTableScript @sSys out, @newName, @newName, '', 2

        -- Check the index schema
        if (@sDict <> @sSys)
		begin
            -- Index schema mismatch or
            -- Table and Index schema mismatch if section above did not match
            set @retCode = @retCode + 2
			set @sMsg = '**** Index for table ' + @newName + ' does not match! ****'
            exec absp_MessageEx @sMsg
            set @sText = @sText + 'DICT: ' + @sDict
            set @sText = @sText + 'SYST: ' + @sSys
        end

        if len(@sText) > 10
		begin
			exec absp_MessageEx 'absp_Migr_CheckTableSchemaFunc - Errors!'
			exec absp_MessageEx @sText
		end
        else
		begin
            exec absp_MessageEx 'absp_Migr_CheckTableSchemaFunc - Success!'
        end
	end
    else
	begin
        -- Table does not exist in the database
        exec absp_MessageEx 'Table does not exist in the database'
        set @retCode = 4
    end

    exec absp_MessageEx 'absp_Migr_CheckTableSchemaFunc - End'

    return @retCode

end
