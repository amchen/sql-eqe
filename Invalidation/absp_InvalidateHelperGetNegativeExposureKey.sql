if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativeExposureKey') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativeExposureKey
end
go

create  procedure absp_InvalidateHelperGetNegativeExposureKey
	@tableName varchar(120),
	@exposureKey int

/*
##BD_BEGIN absp_InvalidateHelperGetNegativeExposureKey ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure returns a negative ExposureKey that is inserted in the specified table.
Returns:	Returns the negative ExposureKey
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @exposureKey ^^  The exposureKey for which we want to get a negative exposureKey.
##RD  @ret_minExpoKey ^^  Returns the negative Program key.
*/
AS
begin

	set nocount on;

	declare @ret_minExpoKey int;
	declare @alreadyExists int;
	declare @sql varchar(max);
	declare @sqln nvarchar(4000);

	Begin Try
		-- get the min key
		set @sqln = 'SELECT @ret_minExpoKey = min ( exposureKey ) FROM ' + @tableName;
		execute sp_executesql @sqln, N'@ret_minExpoKey int OUTPUT', @ret_minExpoKey OUTPUT;

		-- if null, set to -1
		set @ret_minExpoKey = coalesce (@ret_minExpoKey, -1);

		if @ret_minExpoKey <> 0
		begin
			if @ret_minExpoKey > 0
			begin
				-- just negate yourself
				set @ret_minExpoKey = -@exposureKey;
			end
			else
			begin
				set @alreadyExists = 1;
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minExpoKey = @ret_minExpoKey - 1;
					if @tableName in('Phazard','HazardDone')
						set @sql = 'INSERT INTO ' + @tableName +
					           ' (ExposureKey ) VALUES (' + rtrim(ltrim(str(@ret_minExpoKey))) + ')';
					else
						set @sql = 'INSERT INTO ' + @tableName +
					           ' (ExposureKey, AnlCfgKey) VALUES (' + rtrim(ltrim(str(@ret_minExpoKey))) + ', 0 )';
					execute @alreadyExists = absp_Util_SafeExecSQL @sql, 1;
				end
			end
		end
		return @ret_minExpoKey;
	End Try

	Begin Catch
		-- Table Does Not Exists Or any other error --
		Print Error_Message();
		return 0;		-- Only when for non existing @tableName
	End Catch

end
