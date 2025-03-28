if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Print_GetTrigTreatyData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Print_GetTrigTreatyData
end 
go

create procedure /*

This procedure will genarate a result set containing all Exclusion Information in a format that
is used for Printing.
*/
absp_Print_GetTrigTreatyData @tableName char(20) ,@node_key int ,@debugFlag int = 0 
AS
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	ASA
Purpose:	This procedure returns a single result set containing a list of retro, inuring cover 
or case treaties for industry loss triggers under a given aport or program or case respectively

Returns:	Single result set containing the following fields:-
1) Treaty key
2) Layer Key
3) Trigger number
4) Trigger Limit Value
5) Trigger Limit Value currency
6) Perils
7) Line of Business
8) Countries
9) Regions

====================================================================================================

</pre>
</font>
##BD_END

##PD   tableName 	^^ Respective industry loss trigger table name for retro treaty Or inuring cover treaty or case treaty
##PD   node_key 	^^ Key of aport or program or case
##PD   debugFlag	^^ Debug flag (debugged if value > 0)

##RS 	TRTY_KEY	^^ Treaty key
##RS 	LAYER_KEY	^^ Layer key
##RS 	TRIG_NUM	^^ Trigger number
##RS 	THRESHHOLD_VAL	^^ Trigger Limit Value
##RS 	THRESHHOLD_CC	^^ Trigger Limit Value currency
##RS 	PERIL		^^ Perils
##RS 	LOB		^^ Line of Business
##RS 	COUNTRY		^^ Countries
##RS 	REGION		^^ Regions
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
   declare @sql1 char(70) -- either CASEEX_KEY, INUREX_KEY or RTROEX_KEY based on tableName
   declare @tableName2 char(20) -- either CASE_KEY, INUR_KEY or RTRO_KEY based on tableName
   declare @keyFieldName char(20) -- either CSLAYR_KEY, INLAYR_KEY or RTLAYR_KEY based on tableName
   declare @treatyKey char(20) -- either CTTRIG_VAL ,ITLIM_VAL	or RTTRIG_CC based on tableName
   declare @layerKey char(20) -- either CTTRIG_CC ,ITLIM_CC	or RTTRIG_CC based on tableName								
   declare @thresholdVal char(20)
   declare @thresholdCC char(20)
   declare @count1 int
   declare @count2 int
   declare @regionList varchar(max)
   declare @count_lobl_1 int
  -- declare all temporary tables here
   declare @count_lobl_2 int
   declare @trtyKeyList varchar(max)
   declare @tempVal varchar(max)
   declare @listcurr cursor 
   create table #TMP_RRGN_CNT
   (
      LAYER_KEY int   null,
      TRIG_NUM int   null,
      RRGNGRP_id int   null,
      CNT int   null
   )
   create table #TMP_RLOBL_DATA
   (
      RRGNGRP_id int   null,
      R_LOB_NO int   null,
      LOB_NAME char(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   create table #TMPRREGIONS_CNT
   (
      RRGNGRP_ID int   null,
      CNT int   null
   )
   create table #PRINTTMP
   (
      TRTY_KEY int   null,
      LAYER_KEY int   null,
      TRIG_NUM int   null,
      THRESHOLD_VAL float(53)   null,
      THRESHOLD_CC char(5)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      PERIL char(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      LOB char(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      COUNTRY char(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      REGION varchar(255)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   declare @qry varchar(255)
   declare @SWV_curs2_layer_key int
   declare @SWV_curs2_trigNo int
   declare @SWV_curs2_cntry_id int
   declare @SWV_curs2_Count2 int
   declare @curs2 cursor
  -- initialize standard items
   set @me = 'absp_Print_GetTrigTreatyData: ' -- set to my name Procedure Name
   set @debug = 1 -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   if @debug > 0
   begin
      execute absp_messageEx @msg
   end
  -- set the fieldNames based on tableName
   select   @tableName2 = lower(rtrim(ltrim(@tableName))) 
/*   if(@tableName2 = 'casetrig')
   begin
      set @keyFieldName = 'CASEEX_KEY'
      set @treatyKey = 'CASE_KEY'
      set @layerKey = 'CSLAYR_KEY'
      set @thresholdVal = 'CTTRIG_VAL'
      set @thresholdCC = 'CTTRIG_CC'
      set @trtyKeyList = ' in ( '+str(@node_key)+')'
   end
   else
   begin
      if(@tableName2 = 'inurtrig')
      begin
         print 'table name = '+@tableName2
         set @keyFieldName = 'INUREX_KEY'
         set @treatyKey = 'INUR_KEY'
         set @layerKey = 'INLAYR_KEY'
         set @thresholdVal = 'ITLIM_VAL '
         set @thresholdCC = 'ITLIM_CC'
         set @qry = 'select INUR_KEY from INURINFO where prog_key = '+str(@node_key)
         execute absp_Util_GenInList @trtyKeyList out, @qry
      end
      else
      begin
         if(@tableName2 = 'rtrotrig')
         begin
            set @keyFieldName = 'RTROEX_KEY'
            set @treatyKey = 'RTRO_KEY'
            set @layerKey = 'RTLAYR_KEY'
            set @thresholdVal = 'RTTRIG_VAL'
            set @thresholdCC = 'RTTRIG_CC'
            set @qry = 'select RTRO_KEY from RTROINFO where parent_key = '+str(@node_key)
            execute absp_Util_GenInList @trtyKeyList out, @qry
         end
      end
   end */
  -- Create tables instead of memory tables to improve performance.
  -- We will delete the tables at the end of the project
   if exists(select 1 from sysobjects where name = 'TMP_PTL_JOIN_TABLE')
   begin
      drop table TMP_PTL_JOIN_TABLE
   end
   create table TMP_PTL_JOIN_TABLE
   (
      TRTY_KEY int   null,
      LAYR_KEY int   null,
      TRIG_NUM int   null,
      THRESHOLD_VAL float(53)   null,
      THRESHOLD_CC char(5)   null,
      RRGNGRP_ID int   null,
      PERIL_NAME char(256)   null
   )
   create index index_1 on TMP_PTL_JOIN_TABLE
   (rrgngrp_id asc)
   if exists(select 1 from sysobjects where name = 'TMP_RLOBL_JOIN_TABLE')
   begin
      drop table TMP_RLOBL_JOIN_TABLE
   end
   create table TMP_RLOBL_JOIN_TABLE
   (
      TRTY_KEY int   null,
      LAYR_KEY int   null,
      TRIG_NUM int   null,
      THRESHOLD_VAL float(53)   null,
      THRESHOLD_CC char(5)   null,
      RRGNGRP_ID int   null,
      LOB_NAME char(256)   null
   )
   create index index_1 on TMP_RLOBL_JOIN_TABLE
   (rrgngrp_id asc)
   if exists(select 1 from sysobjects where name = 'TMP_RREGIONS_JOIN_TABLE')
   begin
      drop table TMP_RREGIONS_JOIN_TABLE
   end
   create table TMP_RREGIONS_JOIN_TABLE
   (
      TRTY_KEY int   null,
      LAYR_KEY int   null,
      TRIG_NUM int   null,
      THRESHOLD_VAL float(53)   null,
      THRESHOLD_CC char(5)   null,
      RRGNGRP_ID INT   null,
      COUNTRY char(256)   null,
      REGION char(256)   null
   )
   create index index_1 on TMP_RREGIONS_JOIN_TABLE
   (rrgngrp_id asc)
  -- Populate the tables
   insert into #TMP_RLOBL_DATA
   select distinct RRGNGRP_ID,R_LOB_NO,LOB_NAME from RLOBL join
   RRGNLIST on RRGNLIST.country_id = RLOBL.country_id join
   RREGIONS on RRGNLIST.rrgn_key = RREGIONS.rrgn_key where
   FILETYP_ID = 2
   set @sql = 'insert into TMP_PTL_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', trig_num, '+@thresholdVal+', '+@thresholdCC+', '+@tableName2+'.rrgngrp_id, peril_name     from ptl  inner join '+@tableName2+' on trig_value = peril_id where ptl.trans_id in (10000, 57, 59) and trig_type = 1 and peril_id <> 6 and peril_id <> 7 and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   set @sql = 'insert into TMP_RLOBL_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', trig_num, '+@thresholdVal+', '+@thresholdCC+', '+'#TMP_RLOBL_DATA.rrgngrp_id, lob_name     from #TMP_RLOBL_DATA, '+@tableName2+' where trig_value = r_lob_no and trig_type = 2'+' and #TMP_RLOBL_DATA.rrgngrp_id = '+@tableName2+'.rrgngrp_id '+' and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   set @sql = 'insert into TMP_RREGIONS_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', trig_num, '+@thresholdVal+', '+@thresholdCC+', '+@tableName2+'.rrgngrp_id, case when charindex (''-'', rrgngrps.name ) = 0 then '''' else left(rrgngrps.name, charindex (''-'', rrgngrps.name )-1) end as country, rregions.name as region      from '+@tableName2+' inner join rregions on rrgn_key = trig_value and trig_type = 3                  inner join rrgngrps on rrgngrps.rrgngrp_id = '+@tableName2+'.rrgngrp_id'+' and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   insert into #TMPRREGIONS_CNT
   select distinct rrgngrp_id,count(name) from RREGIONS group by rrgngrp_id
   set @sql = 'insert into #TMP_RRGN_CNT '+' select distinct '+@layerKey+', trig_num, rrgngrp_id ,count(trig_value) from '+@tableName2+' where trig_type = 3 and  '+@treatyKey+@trtyKeyList+' group by '+@layerKey+'  , trig_num,rrgngrp_id '
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   create table #TMP_LOBL_CNT(layr_key int, trig_num int, rrgngrp_id int, cnt int)
	set @sql = 'Insert into  #TMP_LOBL_CNT select distinct '+@layerKey+' as layr_key , trig_num, rrgngrp_id ,count(trig_value) as cnt  from '+@tableName2+' where trig_type = 2  and '+@treatyKey+@trtyKeyList+' group by '+@layerKey+', trig_num, rrgngrp_id'
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   select rrgngrp_id,Count(distinct r_lob_no) as cnt into #TMPRLOBL_CNT from RLOBL,RREGIONS,RRGNLIST where
   RLOBL.country_id = RRGNLIST.country_id and RRGNLIST.rrgn_key = RREGIONS.rrgn_key and
   TRANS_ID in(10000,0,57, 59) and FILETYP_ID in(2,999)
   group by rrgngrp_id order by rrgngrp_id asc
   
  /*
  *	For Debug only 
  *
  select * from TMP_PTL_JOIN_TABLE;
  select * from TMP_RREGIONS_JOIN_TABLE;
  select * from #TMP_LOBL_CNT;
  select * from #TMPRLOBL_CNT;

  */
  -- Now loop thru each country and get the print data
  
    --select cnt into @count2 from TMP_RRGN_CNT where rrgngrp_id = cntry_id ;
   set @curs2 = cursor dynamic for select distinct LAYER_KEY,TRIG_NUM as TRIGNO,RRGNGRP_ID as CNTRY_ID,CNT as COUNT2 from #TMP_RRGN_CNT
   open @curs2
   fetch next from @curs2 into @SWV_curs2_layer_key,@SWV_curs2_trigNo,@SWV_curs2_cntry_id,@SWV_curs2_Count2
   while @@fetch_status = 0
   begin
      select   @count1 = cnt  from #TMPRREGIONS_CNT where rrgngrp_id = @SWV_curs2_cntry_id
      if(@count1 = @SWV_curs2_Count2)
      begin
         set @regionList = 'All Regions'
      end
      else
      begin
        	
		set @regionList = ''
		set  @listcurr = cursor for select distinct rtrim(ltrim(region))  from TMP_RREGIONS_JOIN_TABLE where
                rrgngrp_id = @SWV_curs2_cntry_id and layr_key = @SWV_curs2_layer_key and trig_num = @SWV_curs2_trigNo
		open @listcurr
		fetch next from @listcurr into @tempVal
		while @@FETCH_STATUS = 0
		begin
			if @regionList = ''
				begin
					set @regionList = @tempVal
				end
			else
				begin
					set @regionList = @regionList + ', ' +@tempVal
				end
			fetch next from @listcurr into @tempVal
		end
		close @listcurr
		deallocate @listcurr		
		print @regionList
	  end
         select   @count_lobl_1 = cnt  from #TMPRLOBL_CNT where rrgngrp_id = @SWV_curs2_cntry_id
         select   @count_lobl_2 = cnt  from #TMP_LOBL_CNT where rrgngrp_id = @SWV_curs2_cntry_id and
         trig_num = @SWV_curs2_trigNo and layr_key = @SWV_curs2_layer_key
         if(@count_lobl_1 = @count_lobl_2)
         begin
                set @sql = 'insert into #PRINTTMP select distinct t1.trty_key, t1.layr_key, t1.trig_num, t1.threshold_val, t1.threshold_CC, 
		t1.peril_name,       ''All LOBs'', t3.country, '''+@regionList+'''from TMP_PTL_JOIN_TABLE t1, TMP_RREGIONS_JOIN_TABLE t3      
		where t1.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t3.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t1.layr_key = ' + str(@SWV_curs2_layer_key) + ' and 
		t3.layr_key = ' + str(@SWV_curs2_layer_key) + ' and t1.trig_num = ' + str(@SWV_curs2_trigNo) + ' and t3.trig_num = ' + str(@SWV_curs2_trigNo)
         end
         else
         begin
                set @sql = 'insert into #PRINTTMP  select distinct t1.trty_key, t1.layr_key, t1.trig_num,  t1.threshold_val, 
		t1.threshold_CC, t1.peril_name, t2.lob_name, t3.country, '''+@regionList+'''       
		from TMP_PTL_JOIN_TABLE t1, TMP_RLOBL_JOIN_TABLE t2, TMP_RREGIONS_JOIN_TABLE t3      
		where t1.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t2.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) +  ' and 
		t3.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and 
		t1.layr_key = ' + str(@SWV_curs2_layer_key) + ' and t2.layr_key = ' + str(@SWV_curs2_layer_key) + ' and t3.layr_key = ' + 
		str( @SWV_curs2_layer_key) + ' and t1.trig_num = ' + str(@SWV_curs2_trigNo) + ' and t2.trig_num = ' + str(@SWV_curs2_trigNo) + ' and t3.trig_num = ' + str(@SWV_curs2_trigNo)
         end
         if @debug > 0
         begin
            execute absp_messageEx @sql
         end
         execute(@sql)
      
         fetch next from @curs2 into @SWV_curs2_layer_key,@SWV_curs2_trigNo,@SWV_curs2_cntry_id,@SWV_curs2_Count2
   end
   close @curs2
   select distinct  trty_key AS TRTY_KEY, LAYER_KEY AS LAYER_KEY, TRIG_NUM AS TRIG_NUM, THRESHOLD_VAL AS THRESHHOLD_VAL, THRESHOLD_CC AS THRESHHOLD_CC, PERIL AS PERIL, LOB AS LOB, COUNTRY AS COUNTRY, REGION AS REGION from
   #PRINTTMP order by trty_key asc,LAYER_KEY asc,trig_num asc,COUNTRY asc,PERIL asc,LOB asc
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end



