if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Print_GetRtroPartData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Print_GetRtroPartData
end
go

create procedure /*

This procedure will generate a result set containing all Retrocession Participation Information 
in a format that is used for Printing.

*/
absp_Print_GetRtroPartData @node_key int ,@debugFlag int = 0 
AS
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure returns a single result set containing retro participation information 
for all the layers under the retro treaties belonging to a specified accumulation 
portfolio. 

Returns:	Single result set containing the following fields:-
1) Retro treaty key
2) Retro layer key
3) Retro treaty name
4) Reinsurer name
5) Reinsurer domain name
6) PCT Assume

====================================================================================================

</pre>
</font>
##BD_END

##PD   	node_key 	^^ Key of the acumulation portfolio for which the retor participation information is to be seen.
##PD   	debugFlag	^^ Debug flag (debugged if value > 0)

##RS 	RTRO_KEY	^^ Retro treaty key
##RS 	RTLAYR_KEY	^^ Retro layer key
##RS 	TREATY_NAME	^^ Retro treaty name
##RS 	REINSR_NAM	^^ Reinsurer name
##RS 	REINSR_DOM	^^ Reinsurer domain name
##RS 	PCT_ASSUME	^^ PCT Assume

*/
begin
 
   set nocount on
   
 -- standard declares
   -- Procedure Name
   -- for messaging
   declare @me varchar(max)
   declare @debug int -- to handle sql type work
   declare @msg varchar(max)
   declare @sql varchar(max)
   declare @trtyKeyList varchar(max)
   declare @sqlQry varchar(255)
  -- declare all temporary tables here
  -- initialize standard items
   set @me = 'absp_Print_GetRtroPartData: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   if @debug > 0
   begin
      execute absp_messageEx @msg
   end
   set @sqlQry = 'select RTRO_KEY from RTROINFO where parent_key = '+str(@node_key)
   execute absp_Util_GenInList @trtyKeyList out, @sqlQry
   set @sql = ' select distinct rtroinfo.rtro_key, rtlayr_key, ltrim(rtrim(longname)) TREATY_NAME, 
	ltrim(rtrim(REINSR_NAM)) REINSR_NAM, (case when ltrim(rtrim(REINSR_DOM)) ='''' then ''N.A'' else 
	ltrim(rtrim(REINSR_DOM)) end  ) as REINSR_DOM, PCT_ASSUME into #PRINT_RTRO_DATA from rtropart inner 
	join rtroinfo on rtroinfo.rtro_key = rtropart.rtro_key inner join ril on rtropart.REINSR_ID = ril.REINSR_ID 
	where rtropart.REINSR_ID>0 and rtroinfo.rtro_key '+@trtyKeyList + ' select * from #PRINT_RTRO_DATA '
   if @debug > 0
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   
   --select * from #PRINT_RTRO_DATA
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end



