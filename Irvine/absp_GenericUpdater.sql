if exists(select * FROM SYSOBJECTS WHERE id = object_id(N'absp_GenericUpdater') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_GenericUpdater
end
go

create procedure absp_GenericUpdater
	@tableName char(120),
	@fieldName char(120),
	@keyPositive int,
	@sqlQuery varchar(max)

/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure finds the current minimum value of the provided field in a table and calculates the 
local @keyNegative based on this current minimum value. 

1) If the current minimum value of the provided field is positive, @keyNegative will be set to
the negative value of provided keyPositive parameter.
2) If the current minimum value of the provided field is negative, @keyNegative will be set to
the current minimum value, substracting one;

The procedure then updates the provided field in the table by setting its field value to the calculated
@keyNegative if the supplied query is an update query. 

This stored procedure is specifically called by the java planner to clean up intermediate results by 
setting the key to negative Key. The query is always an update statement and a typical update statement would
be like:

UPDATE RTROINTRD SET PPORT_KEY = $ WHERE PPORT_KEY= 15 and ANLCFG_KEY=1;

The purpose of setting @query = replace ( sqlQuery, '$', trim ( string ( @keyNegative ) ) );  
is to replace '$' with a negative key. 

IMPORTANT NOTE: The specified table must not have the primary key or unique index on the provided
field. Otherwise, an index violation will occur when the current minimum value of the provided field 
is negative. In this case, a record with @keyNegative will be inserted to preserve a record with 
@keyNegative in the table before doing an update. The update will fail because duplicate records
are not allowed 

Returns: No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @tableName 	^^ Name of a table from which minimum value has to be sought.
##PD   @fieldName	^^ Field name of the table from which minimum value has to be sought.
##PD   @keyPositive 	^^ Value that is used to set the minimum value sought, in case the minimum value is greater than 0.
##PD   @sqlQuery 	^^ Dynamic query that has to be executed.

*/
as
begin

	set nocount on

	declare @sql nvarchar(4000)
	declare @alreadyExists int
	declare @keyNegative int
	declare @query varchar(max)

	begin try

		-- get the min key
		set @sql = 'select @keyNegative = min ( ' + rtrim(ltrim(@fieldName)) + ' ) from ' + @tableName
		exec sp_executesql @sql, N'@keyNegative int output', @keyNegative output

		select @keyNegative = isnull(@keyNegative, 0);

		-- if null (0), nothing to do, else, see if positive or negative
		if @keyNegative <> 0
		begin
			if @keyNegative > 0
			begin
				-- just negate yourself
				set @keyNegative = -@keyPositive
			end
			else
			begin
                set @alreadyExists = 1
                while(@alreadyExists <> 0)
                begin
					-- 1 less than current min
					set @keyNegative = @keyNegative - 1
					set @sql = 'insert into ' + @tableName +
					           ' ( ' + rtrim(ltrim(@fieldName)) + ' ) values (' + str(@keyNegative) + ')'
					exec @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end

		--now we replace the $ with the key
		set @query = replace(@sqlQuery, '$', rtrim(ltrim(STR(@keyNegative, LEN(@keyNegative), LEN(@keyNegative)))))
		execute(@query)

	end try
	
	begin catch
        -- Table Does Not Exists Or any other error --
        Print Error_Message()
	end catch
end
