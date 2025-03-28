if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateIndexIncludeScript') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CreateIndexIncludeScript
end
go

create procedure absp_Util_CreateIndexIncludeScript
	@ret_sqlScript  varchar(max) output,
	@idxName        varchar(100)
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:

This procedure returns a SQL script in an OUTPUT parameter for the INCLUDE columns of an index.

Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_sqlScript ^^ The SQL script of the INCLUDE columns of an index
##PD  @idxName ^^ The name of the index
*/
begin

	set nocount on
	set ANSI_PADDING on

	declare @sSql       varchar(max)
	declare @columnlist	varchar(8000)

	set @sSql = '';

	-- check if there are INCLUDE columns defined for this index
	if exists (select 1 from DICTIDX where IndexName = @idxName and IsInclude = 'Y')
	begin
		-- start the SQL statement
		set @sSql = ' INCLUDE ( @columnlist )';

		-- create comma separated list
		set @columnlist = NULL;
		select @columnlist = COALESCE(@columnlist + ',', '') + t.FieldName
		  from DictIdx t
		  where IndexName = @idxName
		    and IsInclude = 'Y'
		  order by FieldOrder

		-- replace @values
		set @sSql = replace(@sSql, '@columnlist', @columnlist);
	end

	-- return the resulting script
	set @ret_sqlScript = rtrim(@sSql);
	set ANSI_PADDING off;
end
