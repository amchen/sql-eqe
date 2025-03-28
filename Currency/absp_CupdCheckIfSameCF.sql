if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdCheckIfSameCF') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdCheckIfSameCF
end
 go

create procedure absp_CupdCheckIfSameCF @sourceCFRefKey int, @targetCFRefKey int, @targetDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks if the source and the target currency schemas are same.


Returns:        1 if the schemas are different , 0 if schemas are same.


====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceCFRefKey ^^  The source cfrefKey for which the currency schemas are to be compared
##PD  @targetCFRefKey ^^  The target cfrefKey for which the currency schemas are to be compared
##PD  @targetDB ^^  The target CF database. 

*/
as

begin

   declare @sql nvarchar(max)
   declare @mismatch int
   declare @sourceCurrSkKey int
   declare @targetCurrSkKey int
   
   set @mismatch=0
  
   if @targetDB=''
      set @targetDB = DB_NAME()
      
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   --Get source currencySchemaKey
   select @sourceCurrSkKey = CURRSK_KEY	from CFLDRINFO where CF_REF_KEY=@sourceCFRefKey 
   
   --Get target currencySchemaKey
   set @sql='select @targetCurrSkKey = CURRSK_KEY from ' + dbo.trim(@targetDB) + '..CFLDRINFO where CF_REF_KEY=' + str(@targetCFRefKey)
   execute sp_executesql @sql,N'@targetCurrSkKey int output',@targetCurrSkKey output

   --Check if same
   set @sql = 'select @mismatch = count (*)  from EXCHRATE A inner join ' + dbo.trim(@targetDB) + '..EXCHRATE B 
   on cast(A.EXCHGRATE as char) <> cast(B.EXCHGRATE as char) and A.CURRSK_KEY = ' + str(@sourceCurrSkKey) + ' and
   B.CURRSK_KEY = ' + str(@targetCurrSkKey) + ' and  A.CODE = B.CODE  and A.ACTIVE = ''Y'' and A.IN_LIST = ''Y'''
   
   execute absp_MessageEx @sql
   execute sp_executesql @sql,N'@mismatch int output',@mismatch output

   return @mismatch
   
end