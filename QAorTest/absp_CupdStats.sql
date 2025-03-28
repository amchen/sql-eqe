if exists(select * from SYSOBJECTS where id = object_id(N'absp_CupdStats') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CupdStats
end

go
-- this shows you what the CUPDCTRL stats are
create procedure absp_CupdStats 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:        This procedure get all recount for nodes aport, pport, rport, program and policy information
    		from CUPDCTRL by status for max(CUPD_KEY) of CUPDINFO and insert those records in CUPDSTAT.
    		And returns resultset which contains status of CUPDCTRL from CUPDSTAT.

Returns:        A single resultset . 

====================================================================================================

</pre>
</font>

##BD_END 


*/
as
begin
   declare @cupdKey int
   declare @cntAport int
   declare @cntRport int
   declare @cntPport int
   declare @cntProg int

   declare @cntGPI int
   declare @cntPC int
   declare @cntSAGPS int
   declare @cntSLIC int
   declare @cntPFASR int
   declare @cntSFSAR int
   declare @cntCHAS int

   declare @stat1 char(1)
   declare @stat2 char(1)
   declare @stateText varchar(max)
   declare @totalCnt int
   if not exists(select 1 from sysobjects where name = 'CUPDSTAT' and type = 'U')
   begin
	create table CUPDSTAT
	(
	   CUPDSTATS_KEY  int identity not null,
	   CUPD_KEY       int,
	   APORT_NODES    int default 0, 
	   RPORT_NODES    int default 0, 
	   PPORT_NODES    int default 0, 
	   PROG_NODES     int default 0, 
	   GPI_RECORDS    int default 0, 
	   PC_RECORDS     int default 0, 
	   SAGPS_RECORDS  int default 0, 
	   SLIC_RECORDS   int default 0, 
	   PFASR_RECORDS  int default 0, 
	   SFSAR_RECORDS  int default 0, 
	   CHASDATA_RECORDS  int default 0, 
	   RECORDS        int default 0, 
	   DATE_TIME      TIMESTAMP,
	   TEXT_MSG       char (50)
	) 
   end
   select   @cupdKey = max(CUPD_KEY)  from CUPDINFO
   select   @cntAport = count(*)  from CUPDSTAT where CUPD_KEY = @cupdKey
   
   -- if first time, get both Ys and Ns
   if @cntAport = 0
   begin
      set @stat1 = 'Y'
      set @stat2 = 'N'
      set @stateText = 'Total records'
   end
   else
   begin
      set @stat1 = 'N'
      set @stat2 = 'N'
      set @stateText = 'Remaining records'
   end
   select   @cntAport = count(*)  from CUPDCTRL where
   CUPD_KEY = @cupdKey and APORT_KEY > 0 and RPORT_KEY = 0 and PPORT_KEY = 0 and LPORT_KEY = 0 and(STATUS = @stat1 or STATUS = @stat2)
   select   @cntRport = count(*)  from CUPDCTRL where
   CUPD_KEY = @cupdKey and RPORT_KEY > 0 and PROG_KEY = 0 and PPORT_KEY = 0 and LPORT_KEY = 0 and(STATUS = @stat1 or STATUS = @stat2)
   select   @cntPport = count(*)  from CUPDCTRL where
   CUPD_KEY = @cupdKey and PPORT_KEY > 0 and RPORT_KEY = 0 and PROG_KEY = 0 and LPORT_KEY = 0 and(STATUS = @stat1 or STATUS = @stat2)
   select   @cntProg = count(*)  from CUPDCTRL where
   CUPD_KEY = @cupdKey and PROG_KEY > 0 and PPORT_KEY = 0 and LPORT_KEY = 0 and(STATUS = @stat1 or STATUS = @stat2)
   
   set @totalCnt = 0
   if @totalCnt = 0
   begin
      set @stateText = 'All done'
   end
   insert into CUPDSTAT(TEXT_MSG,DATE_TIME,RECORDS,APORT_NODES,RPORT_NODES,PPORT_NODES,PROG_NODES,GPI_RECORDS,PC_RECORDS,SAGPS_RECORDS,SLIC_RECORDS,PFASR_RECORDS,SFSAR_RECORDS,CHASDATA_RECORDS,CUPD_KEY)(select @stateText,GetDate(),@totalCnt,
      @cntAport, @cntRport, @cntPport, @cntProg, 0, 0, 0, 0, 0, 0, 0, @cupdKey)

   select   CUPDSTATS_KEY,TEXT_MSG,DATE_TIME,RECORDS,APORT_NODES,RPORT_NODES,PPORT_NODES,PROG_NODES,
			GPI_RECORDS,PC_RECORDS,SAGPS_RECORDS,SLIC_RECORDS,PFASR_RECORDS,SFSAR_RECORDS,CHASDATA_RECORDS,CUPD_KEY 
   from CUPDSTAT where CUPD_KEY = @cupdKey order by 1 desc
end


