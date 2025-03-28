

if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetAllCurrencyNodeInfo') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetAllCurrencyNodeInfo
end
 go
create procedure absp_GetAllCurrencyNodeInfo  
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns all attached currency node info.

Returns:	ResultSet

====================================================================================================
</pre>
</font>
##BD_END


*/
as
begin
  
   set nocount on
   
   declare @sqlStr varchar(MAX)
   declare @dbName varchar(130)
   
   if OBJECT_ID('Test #ATTACHEDCURRENCIES','u') IS NOT NULL
	begin
		drop table #ATTACHEDCURRENCIES
	end
		create table #ATTACHEDCURRENCIES
		(
		   FOLDER_KEY int,
		   CURRSK_KEY int,
		   FLONGNAME varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS,
		   SLONGNAME varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS,
		   VALID_DAT varchar(8)
		 COLLATE SQL_Latin1_General_CP1_CI_AS)
   
   declare attachedCurr cursor fast_forward for select DB_NAME from CFLDRINFO
   
   open attachedCurr
   	fetch next from attachedCurr into @dbName
   	while @@fetch_status = 0
	begin
	
		set @sqlStr = 'insert into #ATTACHEDCURRENCIES select F.FOLDER_KEY, F.CURRSK_KEY, F.LONGNAME, C.LONGNAME, C.VALID_DAT  from [' + @dbName + ']..FLDRINFO F, [' + @dbName + ']..CURRINFO C  where F.CURR_NODE = ''Y'' and F.CURRSK_KEY = C.CURRSK_KEY'

		execute (@sqlStr)
		fetch next from attachedCurr into @dbName
	
	end
	close attachedCurr
	deallocate attachedCurr
	
	select * from #ATTACHEDCURRENCIES

   
end


