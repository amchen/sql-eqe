if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BuildUse_SanityCheckDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BuildUse_SanityCheckDB
end
go

create procedure absp_BuildUse_SanityCheckDB
    @logfile varchar(255) = ''
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL
Purpose:

This procedure will perform a Sanity Check on the database.
The @logfile parameter is optional.

Returns:

@rc = 0 if there are no errors.
@rc = non-zero, if there are error(s).
====================================================================================================
</pre>
</font>
##BD_END

##RD  @rc ^^ 0 if there are no errors.
*/

begin

    set nocount on

    declare @filepath varchar(255)
	declare @me varchar(255)
    declare @rc int

	set @me = 'absp_BuildUse_SanityCheckDB'
    set @rc = 0      -- Assume no errors
	set @filepath = ''
	if (@logfile <> '') exec absp_Util_Replace_Slash @filepath output, @logfile

    -- Primary database
    if exists(select 1 from RQEVersion where DbType = 'EDB')
    begin
		-- WCCCODES
		if exists (select 1 from SYS.TABLES where NAME = 'WCCCODES')
		begin
			if exists (select 1 from WCCCODES where MAPI_STAT not in (-8,2,6,7,8,10,11))
			begin
				set @rc = @rc + 1
				if (@filepath <> '') exec absp_Util_Log_Info 'WCCCODES where MAPI_STAT not in (-8,2,6,7,8,10,11)', @me, @filepath
			end
/*
			if exists (select 1 from WCCCODES where DIST_COAST < 0.0 or DIST_COAST > 300.0)
			begin
				set @rc = @rc + 1
				if (@filepath <> '') exec absp_Util_Log_Info 'WCCCODES where DIST_COAST < 0.0 or DIST_COAST > 300.0', @me, @filepath
			end
			if exists (select 1 from WCCCODES where GRND_ELEV < 0.0)
			begin
				set @rc = @rc + 1
				if (@filepath <> '') exec absp_Util_Log_Info 'WCCCODES where GRND_ELEV < 0.0', @me, @filepath
			end
			if exists (select 1 from WCCCODES where (TERR_FEAT1 < 0.5 or TERR_FEAT1 > 1.0) and COUNTRY_ID <> '02')
			begin
				set @rc = @rc + 1
				if (@filepath <> '') exec absp_Util_Log_Info 'WCCCODES where (TERR_FEAT1 < 0.5 or TERR_FEAT1 > 1.0)', @me, @filepath
			end
			if exists (select 1 from WCCCODES where (TERR_FEAT2 < 0.5 or TERR_FEAT2 > 1.0) and COUNTRY_ID <> '02')
			begin
				set @rc = @rc + 1
				if (@filepath <> '') exec absp_Util_Log_Info 'WCCCODES where (TERR_FEAT2 < 0.5 or TERR_FEAT2 > 1.0)', @me, @filepath
			end
*/
		end
    end
    else
    -- IR database
    begin
		if not exists (select 1 from RQEVersion)
		begin
			set @rc = @rc + 1
			if (@filepath <> '') exec absp_Util_Log_Info 'RQEVersion table is empty', @me, @filepath
		end
    end

    return @rc

end
