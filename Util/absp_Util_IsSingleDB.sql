if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsSingleDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsSingleDB
end

go

create procedure absp_Util_IsSingleDB 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure checks if the application is running in singleDB mode or multiple DB mode.

Returns:       1 if singleDB else 0.

====================================================================================================
</pre>
</font>
##BD_END


*/
begin

   set nocount on
   declare @isSingleDB int
   set @IsSingleDB = 0

    --DICTTBL will exist as a view if SingleDB-- 
   select @IsSingleDB = 1  from SYS.TABLES where NAME='DICTTBL'
    return @IsSingleDB
end
