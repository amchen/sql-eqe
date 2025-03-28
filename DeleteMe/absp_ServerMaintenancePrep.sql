if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ServerMaintenancePrep') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerMaintenancePrep
end

go

create procedure absp_ServerMaintenancePrep @maintenaceTypeCode int ,@calledByFunctionName char(125) ,@logFileName char(255) ,@MaintKeyForCompletion int = 0
as
/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL
Purpose: 

This procedure is invoked for the setup of a system maintenance by creating the maintenance 
tables if required, inserting/updating the tables and returning the maintenance Key.

Returns:       The key of the maintenance record.
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @maintenaceTypeCode ^^ The Maintenace Type Code .
##PD  @calledByFunctionName  ^^ Function Name
##PD  @logFileName ^^ Log File Name.
##PD  @MaintKeyForCompletion ^^ The maintenance key

##RD @maintKey ^^ The key of the maintenance record.

*/
 --=================================================
begin

   set nocount on
   
  /*
  this will set up for a system maintenance function
  1) create maintenance tables if needed
  2) add entry to maintenance table and return key
  */
   declare @maintKey int
   declare @createDt char(20)
   print convert(varchar,GetDate(),100)+' inside absp_ServerMaintenancePrep '
  --=================================================
  -- make tables if needed.  TEST ONLY.  These would really be in DICTTBL and be created by EDM
   if(select count(*) from SYSOBJECTS where name = 'SVRMAINT' and type = 'U') = 0
   begin
      create table SVRMAINT
      (
         MAINT_KEY int identity not null,
         START_DTTM char(14)   null,
         MAINT_TYPE int   null,
         CALLED_BY char(125)   null,
         LOG_FILE char(255)   null,
         COMP_DTTM char(14)   null,
         primary key(MAINT_KEY)
      )
   end
   if(select count(*) from SYSOBJECTS where name = 'SVRMTLOG' and type = 'U') = 0
   begin
      create table SVRMTLOG
      (
         MAINT_KEY int   null,
         ACTION char(125)   null,
         LEVEL char(1)   null,
         TABLENAME char(14)   null,
         KEYNAME char(14)   null,
         KEYVALUE int   null,
         MASTER_CNT int   null,
         RESULT_CNT int   null
      )
   end
  --=================================================
   if(select count(*) from SYSOBJECTS where name = 'SVRMTCTL' and type = 'U') = 1
   begin
      drop table SVRMTCTL
   end
  --=================================================
  -- OK, here we go
  --message '=========================';
  -- is this a start or end message"?"
   exec absp_Util_GetDateString @createDt output,'yyyymmdd'
   if @MaintKeyForCompletion = 0
   begin
    -- log start message      
      insert into SVRMAINT (START_DTTM ,MAINT_TYPE ,CALLED_BY ,LOG_FILE ,COMP_DTTM ) values(@createDt,@maintenaceTypeCode,@calledByFunctionName,@logFileName,'')
      set @maintKey = @@identity
      print replace(replace(convert(varchar, getdate(), 120),'-',''),':','')+'  absp_ServerMaintenancePrep @maintKey = '
      print @maintKey
      return @maintKey   
   end
   else
   begin      
      update SVRMAINT set COMP_DTTM = @createDt  where MAINT_KEY = @MaintKeyForCompletion
      set @maintKey = 0
      return  @maintKey
   end
end


