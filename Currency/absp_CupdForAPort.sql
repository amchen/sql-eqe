if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdForAPort') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdForAPort
end
go

create procedure absp_CupdForAPort @cupdKey int,@debugFlag int = 1 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure gets all the aport keys for the given currency update key from the cupdctrl table and
updates all the currency values of the retro treaties related to the aports.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @debugFlag ^^  The debug flag.

*/
as

begin

   set nocount on
   
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @msg varchar(255)
   declare @sql varchar(255)
   declare @APK1 int
   declare @createDt char(20)
   declare curs_aport_key  cursor fast_forward for select distinct APORT_KEY as APK from CUPDCTRL where
   CUPD_KEY = @cupdKey and APORT_KEY > 0 and LPORT_KEY = 0 and
   RPORT_KEY = 0 and PPORT_KEY = 0 and STATUS = 'N'
   declare @msgTxt01 int
   declare @rtroKey2 int
  -- initialize standard items
   set @me = 'absp_CupdForAPort: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   if @debug > 0
   begin
	  execute absp_messageEx @msg
	  execute absp_CupdLogMessage @cupdKey,'M',@msg
   end
  -- Get the list of all distinct APORT_KEYs from CUPDCTRL table
  -- where the RPORT_KEY, PPORT_KEY, and LPORT_KEY is 0 which means this row is for the APORT itself
   open curs_aport_key
   fetch next from curs_aport_key into @APK1
   while @@fetch_status = 0
   begin
	  if(@debug = 2)
	  begin
		 set @msgTxt01 = 'Calling absp_CupdRtroTables for APORT_KEY = '+rtrim(ltrim(str(@APK1)))
		 execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	  end
	-- Now update all the rtro tables
	  declare curs_rtro_key  cursor fast_forward for select  RTRO_KEY from RTROINFO where PARENT_KEY = @APK1 -- to handle sql type work
	  open curs_rtro_key
	  fetch next from curs_rtro_key into @rtroKey2
	  while @@fetch_status = 0
	  begin
		 execute absp_CupdTreatyTables 'RTRO_KEY',@rtroKey2,@cupdKey,@debugFlag
		 fetch next from curs_rtro_key into @rtroKey2
	  end
	  close curs_rtro_key
	  deallocate curs_rtro_key
	  
	-- only set to Y the controlling record that you started your select with
	  exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
	  update CUPDCTRL set STATUS = 'Y',DATE_TIME = @createDt  where
	  CUPD_KEY = @cupdKey and APORT_KEY = @APK1 and LPORT_KEY = 0 and
	  RPORT_KEY = 0 and PPORT_KEY = 0 and PROG_KEY = 0 and STATUS = 'N'
	  if(@debug = 3)
	  begin
		 set @msgTxt01 = 'Updated all RTRO tables for '+rtrim(ltrim(str(@APK1)))
		 execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
		 set @msgTxt01 = 'About to commit all changes for APORT_KEY = '+rtrim(ltrim(str(@APK1)))
		 execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	  end
	  if(@debug = 2)
	  begin
		 set @msgTxt01 = 'Committed changes for APORT_KEY = '+rtrim(ltrim(str(@APK1)))
		 execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	  end
	  fetch next from curs_aport_key into @APK1
   end
   close curs_aport_key
   deallocate curs_aport_key
  -------------- end --------------------
   if @debug > 0
   begin
	  set @msg = @me+'complete'
	  execute absp_messageEx @msg
   end
end




