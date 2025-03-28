if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DeleteBlobsMaster') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_DeleteBlobsMaster;
end
go

create procedure absp_DeleteBlobsMaster as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes  records from all the BLOB tables having negative value
in the KEYNAME column of the respective tables.

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

*/
BEGIN TRY

    set nocount on;
    declare @theKey int;
    declare @startTime DATETIME;
    declare @endMsg varchar(100);
    declare @sql varchar(1000)
    declare @debug int;
    declare @msg varchar(max);
    declare @me varchar(100);
    declare @TN varchar(100);
    declare @KN varchar(100);
    declare @XW varchar(254);
    declare @delTtype char(1);
    declare @delRows int;
    declare @curs1 cursor;

    set @debug = 0;
    set @theKey = 0

    set @me = 'absp_DeleteBlobsMaster';

    set @msg = @me + ' Starting...';
    execute absp_Util_Log_HighLevel @msg,@me;
    --print @msg;

    -- First try to delete any BLOB records that has negative Key
    /* GROUP_ID 5 is for PORT_ID and SP_FILES has entries with KEY_FIELD = PORT_ID but this is an unusual case*/
    set @curs1 = cursor fast_forward for
    select distinct rtrim(ltrim(TABLENAME)), rtrim(ltrim(KEYNAME)), rtrim(ltrim(EXTRAWHERE)), DEL_TYPE, DEL_ROWS
        from DELCTRL
        where((BLOB_DB = 'R' and BLOB_REF = 'M') or(BLOB_DB = 'M' and BLOB_REF = 'N'))
        and  TABLE_TYPE = 'B'
    --Fixed  SDG__00023319
    --and GROUP_ID <> 5

   open @curs1
   fetch next from @curs1 into @TN,@KN,@XW,@delTtype,@delRows
   while @@fetch_status = 0
   begin
        if @XW is null set @XW = ''

        exec @theKey = absp_GetDeleteBlobQuery @sql output, @TN, @KN, @delRows, @delTtype
        --print '@theKey (1) = ' + str(@theKey)
        --print '@sql (1) = ' + @sql

        -- SDG__00023142 & SDG__00023146 - absev_Delete fails to remove negative records from PROGS_A , PROGS_P & TRTYREC if jobs cancelled, failed or cleaned up during server restart
        -- if no CASE_KEY <0 found for PROGRS_A or PROGRS_P, try to find PROG_KEY <0
        if (@TN = 'PROGRS_A' or @TN = 'PROGRS_P') and @theKey = 0
        begin
           set @KN = 'PROG_KEY';
           exec @theKey = absp_GetDeleteBlobQuery  @sql output, @TN, @KN, @delRows, @delTtype
           --print '@theKey (2) = ' + str(@theKey)
           --print '@sql (2) = ' + @sql
        end
        -- if no PROG_KEY < 0 found for TRTYREC, try to find CASE_KEY <0
        else if @TN = 'TRTYREC' and @theKey = 0
        begin
          set @KN = 'CASE_KEY';
          exec @theKey = absp_GetDeleteBlobQuery @sql output, @TN, @KN, @delRows, @delTtype
          --print '@theKey (3) = ' + str(@theKey)
          --print '@sql (3) = ' + @sql
        end

	set @msg = 'Table Name, Key Name, @theKey = ' + @TN + ' , ' + @KN + ' , ' + ltrim(rtrim(str(@theKey)));
    --print @msg;
	execute absp_Util_Log_HighLevel @msg,@me

	if (@theKey < 0)
        begin
	   execute absp_Util_Log_HighLevel @sql,@me
	   execute absp_Util_ElapsedTime @endMsg output, @startTime output
        --print @sql;
        begin transaction
		execute(@sql)
        commit transaction
        -- Sleep for 500 ms only if the number of records is > 0
        -- Earlier we use to sleep for 1 sec and we never checked
        -- whether any records are deleted or not. So even if
        -- there is nothing to delete this procedure used to take 25 secs
        -- to run (since we have 25 blob tables).
        if (@@rowcount > 0)
	       execute absp_Util_Sleep 500

        set @msg = 'Completed in '+@endMsg
        execute absp_Util_Log_HighLevel @msg,@me
        --print @msg;
        return
      end; -- if (@theKey < 0)

      fetch next from @curs1 into @TN,@KN,@XW,@delTtype,@delRows

   end -- while

   close @curs1
   deallocate @curs1

   set @msg = 'Completed'
   execute absp_Util_Log_HighLevel @msg,@me
   --print @msg;

END TRY

BEGIN CATCH;
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH;