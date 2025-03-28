if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateTableScriptPK') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CreateTableScriptPK
end
go

create procedure absp_Util_CreateTableScriptPK
	@ret_sqlScript  varchar(max) output,
	@baseTableName  varchar(120) ,
	@newTableName   varchar(120) = '' ,
	@isAlterTable   int = 0
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure returns a SQL script in an OUTPUT parameter to create the PK on
         the base tablename.
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_sqlScript ^^ The SQL script to create a table optionally in a given dbSpace
##PD  @baseTableName ^^ Base Table Name as Input Parameter
##PD  @newTableName  ^^ New Table Name as Input Parameter
##PD  @bAlterTable   ^^ dbSpaceName as Input Parameter
*/
begin

	set nocount on
	set ANSI_PADDING on

	declare @sSql              varchar(max)
	declare @targetTableName   varchar(120)
	declare @isClustered	   varchar(30)
	declare @columnlist        varchar(8000)
	declare @cnstname          varchar(100)

	set @baseTableName = rtrim(@baseTableName)

	-- handle case we do not need a separate target table
	set @targetTableName = @newTableName
	if len(@targetTableName) = 0
	begin
		set @targetTableName = @baseTableName
	end

	set @sSql = '';

	-- check if there is a primary key defined for this table
	if exists (select 1 from DICTIDX where TABLENAME = @baseTableName and IsPrimary = 'Y')
	begin
		-- get PK name
		select top 1 @cnstname = IndexName from DICTIDX where TABLENAME = @baseTableName and IsPrimary = 'Y'

		-- start the SQL statement
		if (@isAlterTable <> 0) set @sSql = 'ALTER TABLE [@tname] ';

		set @sSql = @sSql + 'CONSTRAINT [@cnstname] PRIMARY KEY @isClustered ( @columnlist )';

		-- check if key is clustered or not
		if exists (select 1 from DICTIDX where TABLENAME = @baseTableName and IsPrimary = 'Y' and IsCluster = 'Y')
			set @isClustered = 'CLUSTERED';
		else
			set @isClustered = 'NONCLUSTERED';

		-- create comma separated list
		set @columnlist = NULL;
		select @columnlist = COALESCE(@columnlist + ',', '') + '[' + t.FieldName + ']'
		  from DictIdx t
		  where TableName = @baseTableName
		    and IsPrimary = 'Y'
		  order by FieldOrder

		-- replace @values
		set @cnstname = replace(@cnstname, @baseTableName, @targetTableName);
		set @sSql = replace(@sSql, '@tname', @targetTableName);
		set @sSql = replace(@sSql, '@cnstname', @cnstname);
		set @sSql = replace(@sSql, '@isClustered', @isClustered);
		set @sSql = replace(@sSql, '@columnlist', @columnlist);

	end

	-- return the resulting script
	set @ret_sqlScript = rtrim(@sSql);
	set ANSI_PADDING off;
end
