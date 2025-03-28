if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DeleteBlobDropResults') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_DeleteBlobDropResults;
end
go

create  procedure absp_DeleteBlobDropResults
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	The procedure finds out the first tablename from BLOBDROP where DISCARD='Y' and drops it.
Returns:	Nothing
====================================================================================================
</pre>
</font>
##BD_END

*/
begin

   set nocount on;

   declare @startTime datetime;
   declare @endMsg varchar(120);
   declare @tbldrop varchar(120);

   if exists(select 1 from BLOBDROP where DISCARD = 'Y')
   begin
      select  top 1 @tbldrop = rtrim(ltrim(isnull(TABLENAME,''))) from BLOBDROP where DISCARD = 'Y';
      if exists(select 1 from SYSOBJECTS where NAME = @tbldrop)
      begin
			execute absp_Util_ElapsedTime @endMsg output, @startTime output;
			print '  Drop temporary table '+@tbldrop;
			execute('drop table '+@tbldrop);
			delete from BLOBDROP where DISCARD = 'Y' and TABLENAME = @tbldrop;
			execute absp_Util_ElapsedTime @endMsg output, @startTime output;
			print '  absp_DeleteBlobDropResults completed in '+@endMsg;
      end
      else
      begin
		 if(@tbldrop <> '')
		 begin
			PRINT '  Delete BLOBDROP entry for '+@tbldrop;
			delete from BLOBDROP where DISCARD = 'Y' and TABLENAME = @tbldrop;
		 end
      end
   end
end
