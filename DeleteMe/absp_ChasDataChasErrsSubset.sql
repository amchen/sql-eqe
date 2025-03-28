if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ChasDataChasErrsSubset') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ChasDataChasErrsSubset
end
go


create procedure absp_ChasDataChasErrsSubset @chasKey int ,@newChasKey int ,@siteNumWhereClause char(100) = '',@targetDB varchar(130)='' 
/*

##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This Procedore inserts a records of new cloned chas_key based on existing chas_key which is passed
as parameter.  



Returns:     Nothing.               
====================================================================================================
</pre>
</font>
##BD_END

##PD  chasKey ^^  The Chas_key of which clone will be done.
##PD  newChasKey ^^ The new chas_key which will be inserted into tables.
##PD   siteNumWhereClause ^^ Record cloning criteria..


*/
as
begin

   set nocount on
   
  -- this procedure will subset the CHAS tables CHASDATA and CHASERRS
   declare @whereClause varchar(max)
   declare @progkeyTrio varchar(max)
   declare @tabSep char(2)
   
   if @targetDB=''
     set @targetDB=DB_NAME()
     
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
     
   execute absp_GenericTableCloneSeparator @tabSep out
	print 'absp_GenericTableCloneSeparator'
  -- copy into a new one with the new unique name
   set @whereClause = 'CHAS_KEY = '+cast(@chasKey as CHAR)+@siteNumWhereClause
  -- data and errs
   set @progkeyTrio = 'INT'+@tabSep+'CHAS_KEY '+@tabSep+cast(@newChasKey as CHAR)
   print 'absp_GenericTableCloneRecords start' 
   execute absp_GenericTableCloneRecords 'CHASDATA',0,@whereClause,@progkeyTrio,0,@targetDB
   execute absp_GenericTableCloneRecords 'CHASERRS',0,@whereClause,@progkeyTrio,0,@targetDB
   print 'absp_GenericTableCloneRecords end'
end



