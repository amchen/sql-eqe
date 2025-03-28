if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CheckTableSchema') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CheckTableSchema
end

go

create procedure absp_Migr_CheckTableSchema @tblName char(120)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure compares the actual table schemas for the given table with the data
     dictionary (DICTTBL,DICTCOL) and returns 0 if correct, else a return code
  	    
Returns:  A single resultset containing the return code:-
	      0 if actual schema matches with the data dictionary of the application.
	      1 if actual schema does not match with the data dictionary schema.
	      2 if there is a mismatch in the index schemas
	      3 if there is a table and index schema mismatch
	      4 if the table does not exist in the database
                   
====================================================================================================
</pre>
</font>
##BD_END

##PD @tblName ^^  The table name for which the actual schema is to be compared to the data dictionary schema

##RS @retCode ^^  A single resultset containing the return code:-
	      0 if actual schema matches with the data dictionary of the application.
	      1 if actual schema does not match with the data dictionary schema.
	      2 if there is a mismatch in the index scemas
	      3 if there is a table and index schema mismatch
	      4 if the table does not exist in the database
*/

begin
   set nocount on
/*
    This proc checks actual table schema against the data dictionary (DICTTBL, DICTCOL).

    Returns 0   Success, exact match
            1   Table schema mismatch
            2   Index schema mismatch
            3   Table and Index schema mismatch
            4   Table does not exist in the database
*/

    declare @retCode     integer;
    declare @sText  varchar(max);
    declare @sDict  varchar(max);
    declare @sSys   varchar(max);
    declare @tname  char(120);
    declare @sMsg varchar(512);
    
    set @retCode = 0;
    set @sText = '';
    exec absp_MessageEx 'absp_Migr_CheckTableSchema - Started';

    -- Check the table schema
    set @tname = @tblName;

    if exists ( select 1 from SYS.TABLES where NAME = @tname ) 
	begin
        -- Get the datadict schema
        exec absp_Util_CreateTableScript  @sDict out, @tname;

        -- Get the system schema
        exec absp_Util_CreateSysTableScript @sSys out , @tname ;

        if (@sDict <> @sSys) 
	begin
            set @sMsg = '**** Table ' + @tname + ' schema does not match! ****';
	    exec absp_MessageEx @sMsg;
            
            set @retCode = @retCode + 1;
            set @sText = @sText + 'DICT: ' + @sDict ;
            set @sText = @sText + 'SYST: ' + @sSys  ;
        end ;

        -- Get the datadict schema
        exec absp_Util_CreateTableScript @sDict out ,@tname, '','',2;

        -- Get the system schema
        exec absp_Util_CreateSysTableScript @sSys out,@tname, '','',2 ;

        -- Check the index schema
        if (@sDict <> @sSys) 
	begin
            set @retCode = @retCode + 2;
            set @sMsg = '**** Index for table ' + @tname + ' does not match! ****';
            exec absp_MessageEx @sMsg;

            set @sText = @sText + 'DICT: ' + @sDict ;
            set @sText = @sText + 'SYST: ' + @sSys ;
        end;

        if len(@sText) > 10
	begin
            exec absp_MessageEx 'absp_Migr_CheckTableSchema - Errors!';
            exec absp_MessageEx @sText;
	end
        else
	begin
            exec absp_MessageEx 'absp_Migr_CheckTableSchema - Success!';
            
        end;
    end
    else
    begin
        set @retCode = 4;

    end;

    select @retCode RETCODE;

end;