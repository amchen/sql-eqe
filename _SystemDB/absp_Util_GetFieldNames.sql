if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetFieldNames') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetFieldNames
end

go

create procedure absp_Util_GetFieldNames
    @ret_list varchar(max) output,
    @tableName varchar(120),
    @eqeId varchar(20),
    @qryType varchar(10) = 'Insert'

/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console;
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure returns a comma-delimited list of fieldnames of a given table for queryType = 'insert' or 'update'

Returns	None

====================================================================================================
pre
font
##BD_END
*/

AS
begin
declare @list1 varchar(1000)
declare @sql nvarchar(2000)
declare @fieldName varchar(120)

set @list1 = ''
set @sql='declare curs1 cursor fast_forward global for '+
		' select rtrim(fieldname) from systemdb.dbo.dictCOL where TABLENAME = ''' + @tableName  + ''''

	exec(@sql)
	open curs1
	fetch next from curs1 into @fieldName
	while @@fetch_status = 0
	begin
	    --print @fieldName
	    if @qryType = 'update'
			set @list1 = @list1 + '[' + @fieldName + '] = i.[' + @fieldName + '],'
	    else
			set @list1 = @list1 + '[' + @fieldName + '],'

	    fetch next from curs1 into @fieldName
	end
	close curs1
	deallocate curs1
	set @list1 = substring(@list1, 0, len(@list1))
	set @ret_list = @list1
end
