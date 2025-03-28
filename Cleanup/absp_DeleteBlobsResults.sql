if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DeleteBlobsResults') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_DeleteBlobsResults;
end
go

create procedure absp_DeleteBlobsResults as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes records from all the BLOB tables in result database,
having negative value in the KEYNAME column of the respective tables.

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

*/
begin

set nocount on

   declare @theKey int;
   declare @startTime datetime;
   declare @endMsg varchar(100);
   declare @sql varchar(1000);
   declare @sql1 nvarchar(200);
   declare @debug int;
   declare @msg varchar(max);
   declare @me varchar(100);
   declare @TN varchar(100);
   declare @KN varchar(100);
   declare @XW varchar(254);
   declare @delTType char(1);
   declare @delRows int;
   declare @curs1 cursor;

   set @debug = 0
   set @me = 'absp_DeleteBlobsResults'
   set @msg = @me+' Starting...'
   execute absp_Util_Log_HighLevel @msg,@me

   set @curs1 = cursor fast_forward for
      select distinct rtrim(ltrim(TABLENAME)) ,rtrim(ltrim(KEYNAME)), rtrim(ltrim(EXTRAWHERE)),DEL_TYPE ,DEL_ROWS
      from DELCTRL
      where BLOB_DB = 'r' and TABLE_TYPE = 'b'
   open @curs1
   fetch next from @curs1 into @TN,@KN,@XW,@DelTType,@DelRows
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
           exec @theKey = absp_GetDeleteBlobQuery @sql output, @TN, @KN, @delRows, @delTtype
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

      if(@thekey < 0)
      begin
         execute absp_Util_ElapsedTime @endmsg output, @starttime output
         --print @sql;
         begin transaction
		 execute(@sql)
         commit transaction
         execute absp_util_ElapsedTime @endmsg output, @starttime output
         set @msg = 'completed in '+@endmsg
         execute absp_Util_Log_Highlevel @msg,@me
         return
      end
      fetch next from @curs1 into @TN,@KN,@XW,@DelTType,@DelRows
   end
   close @curs1
   deallocate @curs1
end
