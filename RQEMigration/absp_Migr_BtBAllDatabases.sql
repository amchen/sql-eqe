if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_BtBAllDatabases') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_BtBAllDatabases
end

go

create procedure absp_Migr_BtBAllDatabases
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

		This procedure marks all EDB/RDB depending on given DB type for build to build migration if required. 

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END
*/
begin
  set nocount on
  
   declare @dbType varchar(3)
   
   print GetDate()
   print ': absp_Migr_BtBAllDatabases - Begin'
   
   exec commondb.dbo.absp_Migr_BtBAllDatabasesByDBType 'EDB'
   exec commondb.dbo.absp_Migr_BtBAllDatabasesByDBType 'RDB'
   
  -- end of the views cursor
   print GetDate()
   print ': absp_Migr_BtBAllDatabases - End'
end


