
if EXISTS(select * FROM sysobjects WHERE id = object_id(N'absp_AddProgramStatus') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_AddProgramStatus
end
 GO
create procedure absp_AddProgramStatus @statusName CHAR(40) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts a given status in the program status lookup table RPRGSTAT.

Returns:	The new program status key.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @statusName ^^  The status that is to be inserted in the program status lookup table.
##RD  @t1 ^^  The new program status key.

*/
AS
begin
 
   set nocount on
   
  declare @pgStKey int
  -- SDG__00014427 -- Change RPRGSTAT.PGSTAT_ID to RPRGSTAT.PGSTAT_KEY,  RPRGSTAT.NAME to RPRGSTAT.PROGSTAT
   select  @pgStKey = PGSTAT_KEY  from RPRGSTAT where PROGSTAT = @statusName
   if ISNull(@pgStKey,0) = 0
   begin
      insert into RPRGSTAT(PROGSTAT) values(@statusName)
      set @pgStKey = @@IDENTITY
      --commit work
   end
   return @pgStKey
end


