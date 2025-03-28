if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateResultsCurrencyUpdate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateResultsCurrencyUpdate
end
 go
create procedure absp_InvalidateResultsCurrencyUpdate @cupdKey int, @optionFlag int = 0, @skipPasteLinkCheck int = 1, @forceInvalidation int = 0, @cleanup int = 1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       The procedure invalidates the analysis results of a user database caused by a currency update. 

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  Currency update key
##PD  @optionFlag ^^  A flag to indicate if final results are to be deleted.
##PD  @skipPasteLinkCheck^^  A flag to indicate skipping the invalidation of pasteLink nodes
##PD  @forceInvalidation^^  A flag to indicate a forced topdown invalidation 
*/
as
BEGIN TRY
declare @invalidateIR int 
declare @invalidateExposureReport int
declare @exposurekey int

   set nocount on
  --message 'absp_InvalidateResultsCurrencyUpdate: called with currency update key = ',cupdKey;

  declare @curs_aport_Key int
  declare cursAport cursor dynamic for select distinct APORT_KEY from CUPDCTRL where CUPD_KEY = @cupdKey and APORT_KEY > 0
  declare @curs_pport_Key int
  declare cursPport cursor dynamic for select distinct PPORT_KEY from CUPDCTRL where CUPD_KEY = @cupdkey and APORT_KEY = 0 and PPORT_KEY > 0
  declare @curs_rport_Key int
  declare cursRport cursor dynamic for select distinct RPORT_KEY from CUPDCTRL where CUPD_KEY = @cupdkey and APORT_KEY = 0 and RPORT_KEY > 0
  declare @curs_progKey int 
  declare cursPportProg cursor dynamic for select distinct C.PPORT_KEY,0 PROG_KEY  from CUPDCTRL C inner join PPRTINFO T1 on C.PPORT_KEY = T1.PPORT_KEY where C.CUPD_KEY = @cupdKey and T1.STATUS ='ACTIVE' union  select distinct 0 PPORT_KEY , C.PROG_KEY  from CUPDCTRL C inner join PROGINFO T2 on C.PROG_KEY = T2.PROG_KEY and T2.LPORT_KEY > 0 where C.CUPD_KEY = @cupdKey
  
    --Get the list of all APORT_KEY that needs to be invalidated
   -- delete results of all accumulation portfolios
   open cursAport
   fetch next from cursAport into @curs_aport_Key
   while @@fetch_status = 0
   begin
      execute absp_InvalidateResultsUpDownAndSelf @curs_aport_Key,1
      fetch next from cursAport into @curs_aport_Key
   end
   close cursAport
   deallocate cursAport
   
    --Get the list of all PPORT_KEY that needs to be invalidated
   -- delete results of all primary portfolios
   open cursPport
   fetch next from cursPport into @curs_pport_Key
   while @@fetch_status = 0
   begin
      execute absp_InvalidateResultsUpDownAndSelf @curs_pport_Key, 2
      fetch next from cursPport into @curs_pport_Key
   end
   close cursPport
   deallocate cursPport
   
   --Get the list of all RPORT_KEY that needs to be invalidated
   -- delete results of all reinsurance portfolios
   open cursRport
   fetch next from cursRport into @curs_rport_Key
   while @@fetch_status = 0
   begin
      execute absp_InvalidateResultsUpDownAndSelf @curs_rport_Key, 23
      fetch next from cursRport into @curs_rport_Key
   end
   close cursRport
   deallocate cursRport
   

   if @cleanup > 0 
      execute absp_CupdCleanup @cupdKey
      
END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH

