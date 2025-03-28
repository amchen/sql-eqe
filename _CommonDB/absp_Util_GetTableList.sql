if exists (select * from sys.objects where object_id = object_id(N'dbo.absp_Util_GetTableList') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
    drop function dbo.absp_Util_GetTableList
end
go

create function dbo.absp_Util_GetTableList
(
    @listKey varchar(200)
)
returns @TableList table
(
    TableName varchar(100)
)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MSSQL
Purpose:    This function returns the tablenames associated with the requested list.
Returns:    Returns names in a table variable. More than one list can be requested.
            Separate table lists with the plus (+) sign.
Example:    select * from absp_Util_GetTableList('Aport.Report+Aport.Blob')
====================================================================================================
</pre>
</font>
##BD_END

##PD  @listKey  ^^  The table list(s) to return.
*/

begin

    declare @index      int
    declare @delimiter  char(1)
    declare @key        varchar(100)
    declare @keyList    varchar(200)

    set @index = -1
    set @delimiter = '+'
    set @keyList = replace(@listKey, ' ', '')	-- strip any blanks in the list

    while (len(@keyList) > 0)
    begin

        -- search for delimiter
        set @index = charindex(@delimiter, @keyList)

        -- if not found, this is the last key
        if (@index = 0) and (len(@keyList) > 0)
        begin
            set @key = dbo.trim(@keyList)

            -- Populate return TableList
            insert into @TableList
                select rtrim(TableName) from dbo.TableList
                    where TableListName = @key
                    order by TableOrder
            break
        end

        -- if found, extract the key
        if (@index > 1)
        begin
            set @key = left(@keyList, @index - 1)
            set @keyList = right(@keyList, (len(@keyList) - @index))

            -- Populate return TableList
            insert into @TableList
                select TableName from dbo.TableList
                    where TableListName = @key
                    order by TableOrder
        end
        else
            set @keyList = right(@keyList, (len(@keyList) - @index))
    end
    return
end
