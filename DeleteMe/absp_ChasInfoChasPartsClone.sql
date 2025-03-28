if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ChasInfoChasPartsClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ChasInfoChasPartsClone
end
go

create procedure absp_ChasInfoChasPartsClone @chasKey int,@targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will clone the CHASINFO, CHASPARM, and CHASPTF tables of a given Chas Key and return 
the new Chas Key.

Returns:       The new Chas Key
====================================================================================================
</pre>
</font>
##BD_END

##PD  chasKey ^^  The chas key whose parts are to be cloned. 

*/
as
begin

   set nocount on
   
   -- this procedure will clone the CHASINFO, CHASPARM, and CHASPTF tables
   declare @lastKey int
   declare @whereClause varchar(max)
   declare @progkeyTrio varchar(max)
   declare @tabSep char(2)
   declare @currSkKey int
   declare @sql varchar(max)
   
   if @targetDB=''
   	set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   execute absp_GenericTableCloneSeparator @tabSep out
   -- copy into a new one with the new unique name
   set @whereClause = 'CHAS_KEY = '+cast(@chasKey as CHAR)
   set @progkeyTrio = 'INT'+@tabSep+'CHAS_KEY '+@tabSep+cast(@chasKey as CHAR)
   execute @lastKey = absp_GenericTableCloneRecords 'CHASINFO',1,@whereClause,@progkeyTrio,0,@targetDB 
   
   --Update CURRSK_KEY of targetDB
   select @currSkKey = CURRSK_KEY from CFLDRINFO where DB_NAME = substring(@targetDB,2,len(@targetdb)-2)
   set @sql = 'update ' + dbo.trim(@targetDB) + '..CHASINFO 
                     set CHASINFO.CURRSK_KEY = ' + str(@currSkKey) +
                     ' where CHAS_KEY = '+str(@lastKey)
   
   execute(@sql)
	
   -- update the parts CHASPARM and CHASPTF that depend on chas key
   execute absp_TreeviewChasPartsClone @chasKey,@lastKey,@targetDB
   return @lastKey
end



