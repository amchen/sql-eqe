if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdDriverForMCF') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdDriverForMCF
end
 go

create procedure absp_CupdDriverForMCF  @nodeKey int ,@nodeType int ,@parentKey int ,@parentType int ,@policyKey int = 0 ,@siteKey int = 0 ,@sourceCFRefKey int ,@targetCFRefKey int ,@doItFlag int = 1 ,@debugFlag int = 0, @sourceDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure findes the actual currency Schema Keys from the given CFRefKeys and invokes absp_CupdDriver.


Returns:        The currency update Key


====================================================================================================
</pre>
</font>
##BD_END


##PD  @nodeKey ^^  The key of the node for which the currency conversion is to be done. 
##PD  @nodeType ^^  The type of node for which the currency conversion is to be done. 
##PD  @policyKey ^^  The policy key for which the currency conversion is to be done. 
##PD  @siteKey ^^  The site key for which the currency conversion is to be done.
##PD  @sourceCFRefKey ^^  The source cfrefKey for which the currency schemas are to be compared
##PD  @targetCFRefKey ^^  The target cfrefKey for which the currency schemas are to be compared
##PD  @doItFlag ^^  Unused parameter in the proc and the called procs.
##PD  @cleanupFlag ^^  A flag to indicate if cleanup is required after conversion.
##PD  @debugFlag ^^  The debug flag
##PD  @targetDB ^^  The target CF database. 

##RD  @cupdKey^^ The currency update key.

*/
as

begin

   declare @cupdKey int
   declare @sourceCurrSkKey int
   declare @targetCurrSkKey int
   
	if @sourceDB=''
		set @sourceDB=DB_NAME()
      
   --Enclose within square brackets--
   execute absp_getDBName @sourceDB out, @sourceDB	

   
   --Get source currencySchemaKey--
   select @sourceCurrSkKey = CURRSK_KEY	from CFLDRINFO where CF_REF_KEY=@sourceCFRefKey 

   --Get target currencySchemaKey--
   select @targetCurrSkKey = CURRSK_KEY	from CFLDRINFO where CF_REF_KEY=@targetCFRefKey 
   
   execute  @cupdKey = absp_CupdDriver @nodeKey,@nodeType,@parentKey,@parentType,@policyKey,@siteKey,@sourceCurrSkKey,@targetCurrSkKey,@doItFlag,@debugFlag, @sourceDB

   return @cupdKey
   
end