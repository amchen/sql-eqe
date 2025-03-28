if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdCleanup') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdCleanup
end
 go

create procedure absp_CupdCleanup @cupdKey int,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure performs cleanup operations by deleting records that has 
completed currency updates from the Currency update tables.

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
   
 /*
  This will cleanup the CUPDxxxx tables
  cupdKey = -999 means clean all completed cupdKeys
  */
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @sql varchar(255)
   declare @cupKey int
   declare @msgTxt01 varchar(255)
   set @me = 'absp_CupdCleanup: ' -- set to my name (name_of_proc plus ': '
   set @debug = @debugFlag -- initialize
   if @debug > 0
   begin
      set @msgTxt01 = @me+'starting'
      execute absp_messageEx @msgTxt01
   end
   if(@cupdKey = -999)
   begin
      set @sql = 'select CUPD_KEY from CUPDINFO where STATUS = ''Complete'''
   end
   else
   begin
      set @sql = 'select CUPD_KEY from CUPDINFO where CUPD_KEY = '+rtrim(ltrim(str(@cupdKey)))+' and STATUS = ''Complete'''
   end
   if @debug > 0
   begin
      set @msgTxt01 = @me+@sql
      execute absp_messageEx @msgTxt01
   end
   begin
      execute('declare eachInfo cursor fast_forward global for '+@sql)
      open eachInfo 
      fetch next from eachInfo into @cupKey
      while @@fetch_status = 0
	  begin
			 if @debug > 0
			 begin
				set @msgTxt01 = @me+'CUPD_KEY = '+rtrim(ltrim(str(@cupKey)))
				execute absp_messageEx @msgTxt01
			 end
			 if @debug > 0
			 begin
				set @msgTxt01 = @me+'delete CUPDSTAT'
				execute absp_messageEx @msgTxt01
			 end
			 delete from CUPDSTAT where CUPD_KEY = @cupKey
			 if @debug > 0
			 begin
				set @msgTxt01 = @me+'delete CUPDLOGS'
				execute absp_messageEx @msgTxt01
			 end
			 delete from CUPDLOGS where CUPD_KEY = @cupKey
			 if @debug > 0
			 begin
				set @msgTxt01 = @me+'delete CUPDCTRL'
				execute absp_messageEx @msgTxt01
			 end
			 delete from CUPDCTRL where CUPD_KEY = @cupKey
			 if @debug > 0
			 begin
				set @msgTxt01 = @me+'delete CUPDINFO'
				execute absp_messageEx @msgTxt01
			 end
			 delete from CUPDINFO where CUPD_KEY = @cupKey
			 fetch next from eachInfo into @cupKey
	  end
	close eachInfo
        deallocate eachInfo
   end
   if @debug > 0
   begin
      set @msgTxt01 = @me+'done'
      execute absp_messageEx @msgTxt01
   end
end
