if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetColumnList') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetColumnList;
end
go

create procedure absp_Util_GetColumnList
	@list       varchar(max) output,
	@tname      varchar(120),
	@delimiter  char(1) = ','
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:	MSSQL
Purpose:    This procedure returns a delimited list of column names for the table of interest.
            The default delimiter is comma.
Output:		Delimited list of column names.
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin

	set nocount on;

	-- create comma separated list
	set @list = NULL;
	select @list = COALESCE(@list + @delimiter, '') + t.FieldName
	  from systemdb.dbo.DictCol t
	  where TableName = @tname
	  order by FieldNum;

end
