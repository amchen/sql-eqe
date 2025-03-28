if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativeAPortKey') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativeAPortKey
end
go

create procedure absp_InvalidateHelperGetNegativeAPortKey
	@tableName varchar(120),
	@aPortKey int

--returns integer
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a negative APORT_KEY that is inserted in the specified table when the table
(Aportfolio related table having Analysis Configuration Key)has no records or the minimum
value of APORT_KEY in the table is <= 0 (in and out parameter).

This procedure returns negative APORT_KEY for a given APORT_KEY from a given table when the table
has all positive APORT_KEY.

Returns:       The negative aport key.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @aPortKey ^^  The APORT_KEY for which we want to get a negative APORT_KEY.

##RD  @ret_minAPortKey ^^  The negative aport key.

*/
as
begin

	set nocount on

	declare @ret_minAPortKey int
	declare @alreadyExists int
	declare @sql varchar(max)
	declare @sqln nvarchar(4000)

	begin try
		-- get the min key
		set @sqln = 'select @ret_minAPortKey = min ( APORT_KEY )  from ' + @tableName
		exec sp_executesql @sqln, N'@ret_minAPortKey int output', @ret_minAPortKey output

		-- if null, set to -1
		set @ret_minAPortKey = coalesce (@ret_minAPortKey, -1)

		if @ret_minAPortKey <> 0
		begin
			if @ret_minAPortKey > 0
			begin
				-- just negate yourself
				set @ret_minAPortKey = -@aPortKey
			end
			else
			begin
				set @alreadyExists = 1
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minAPortKey = @ret_minAPortKey - 1
					set @sql = 'insert into ' + @tableName +
							   ' (APORT_KEY, ANLCFG_KEY) values (' + rtrim(ltrim(str(@ret_minAPortKey))) + ', 0 )'
					exec @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end
		return ( @ret_minAPortKey );
	end try

	begin catch
		-- Table Does Not Exists Or any other error --
		print Error_Message()
		return 0		-- Only when for non existing @tableName
	end catch

end