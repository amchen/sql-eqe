if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdForProgram') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdForProgram
end
 go

create procedure absp_CupdForProgram @cupdKey int,@progKey int,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure updates the currency rates for all the tables related to the given program.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @progKey ^^  The key of the program for which the currency conversion is to be done.
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
	   declare @PK int
	   declare @msgTxt01 varchar(1000)
	   declare @inurKey int
	   declare @caseKey int
	   declare @msgTxt02 varchar(255)

	  -- initialize standard items
	   set @me = 'absp_CupdForProgram: ' -- set to my name Procedure Name
	   set @debug = @debugFlag -- initialize
	   set @msg = @me+'starting - progKey = '+rtrim(ltrim(str(@progKey)))
	   set @sql = ''
	   set @PK = @progKey
	   
	   if @debug > 0
	   begin
		  execute absp_CupdLogMessage @cupdKey,'M',@msg
	   end
	   if(@debug = 2)
	   begin
		  set @msgTxt01 = 'Calling absp_CupdTreatyTables to update Inuring treaties for PROG_KEY = '+rtrim(ltrim(str(@PK)))
		  execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	   end
	   
	   -- Now update all the inur tables	  
	   declare curs_inur_key  cursor fast_forward  for select  INUR_KEY as inurKey from INURINFO where PROG_KEY = @PK
	   open curs_inur_key
	   fetch next from curs_inur_key into @inurKey
	   while @@fetch_status = 0
	   begin
		  execute absp_CupdTreatyTables 'INUR_KEY',@inurKey,@cupdKey,@debugFlag
		  fetch next from curs_inur_key into @inurKey
	   end
	   close curs_inur_key
	   deallocate curs_inur_key
	   
	   if(@debug = 3)
	   begin
		  set @msgTxt01 = 'Updated all INUR tables for '+rtrim(ltrim(str(@PK)))
		  execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
		  set @msgTxt01 = 'Calling absp_CupdTreatyTables to update Case treaties for PROG_KEY = '+rtrim(ltrim(str(@PK)))
		  execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	   end
	   
	   -- Now update all the case tables
	   declare curs_case_key  cursor fast_forward for select  CASE_KEY as caseKey from CASEINFO where PROG_KEY = @PK
	   open curs_case_key
	   fetch next from curs_case_key into @caseKey
	   while @@fetch_status = 0
	   begin
		  execute absp_CupdTreatyTables 'CASE_KEY',@caseKey,@cupdKey,@debugFlag
		  fetch next from curs_case_key into @caseKey
	   end
	   close curs_case_key
	   deallocate curs_case_key
	   
	   if(@debug = 3)
	   begin
		  set @msgTxt02 = 'Updated all CASE tables for '+rtrim(ltrim(str(@PK)))
		  execute absp_MessageEx @msgTxt02
		  set @msgTxt02 = 'About to commit all changes for PROG_KEY = '+rtrim(ltrim(str(@PK)))
		  execute absp_MessageEx @msgTxt02
	   end
	   if(@debug = 2)
	   begin
		  set @msgTxt01 = 'Committed changes for PROG_KEY = '+rtrim(ltrim(str(@PK)))
		  execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
	   end
	  -------------- end --------------------
	   if @debug > 0
	   begin
		  set @msg = @me+'complete'
		  execute absp_CupdLogMessage @cupdKey,'M',@msg
	   end
end