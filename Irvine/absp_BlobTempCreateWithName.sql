if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BlobTempCreateWithName') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BlobTempCreateWithName
end
go


create procedure absp_BlobTempCreateWithName ( 
	@baseTableName varchar ( 120 ), 
	@tmpTableName varchar ( 120 ),
    @dbSpaceName  varchar ( 40 ) = '',
    @makeIndex bit = 0,
    @addDfltVal integer = 0
	)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

      This procedure creates a temporary table with the same structure as 
      the given existing base table.
    	
Returns:       Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  baseTableName     ^^ A string containing the base table name.
##PD  tmpTableName     	^^ A string containing the table name to be created.
*/

as
begin
set nocount on

declare @sSql                    varchar(max)
declare @i                       int
declare @retCode                 int
declare @tmpTablename2			 varchar(max)

set @sSql = ''
set @i = 0

-- just in case he tries to create his own table, do not let him
if ltrim (rtrim( @tmpTablename )) = ltrim(rtrim( @baseTableName ))
begin 
    set @tmpTablename = @tmpTablename + '_TMP'
end

if exists ( select 1 from sysobjects where name = @tmpTableName and type = 'U' )
begin
    execute('drop table '+ @tmpTableName)
end

retryLoop: while 1 = 1
begin
    -- begin create SQL statement
    execute absp_Util_CreateTableScript @sSql out, @baseTableName, @tmpTableName, @dbSpaceName, @makeIndex, @addDfltVal

    -- execute create SQL statement and check for return value
    execute @retCode = absp_Util_SafeExecSQL @sSql , 1 

    if (@retCode = 0)
	begin
        -- success
        break
	end
    else
	begin
        -- failure, create a random appendage
        set @tmpTablename2 = rtrim(ltrim(@tmpTablename)) + rtrim (ltrim( str ( 7559 * rand ( )  ) )) -- 7559 is a prime
        set @i = @i + 1
        if @i > 200 
		begin
            return
        end
    end
end

end

