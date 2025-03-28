if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Print_GetExclTreatyData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Print_GetExclTreatyData
end
go

create procedure /*

This procedure will genarate a result set containing all Exclusion Information in a format that
is used for Printing.

*/
absp_Print_GetExclTreatyData @tableName char(20) ,@node_key int ,@debugFlag int = 0 
as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	ASA
Purpose:	This procedure returns a single result set containing all retro, inuring cover or case 
exclusion layer treaties defined under a given aport or program or case respectively.

Returns:	Single result set containing the following fields:-
1) Treaty key
2) Layer Key
3) Exclusion number
4) Exclusion mode
5) Perils
6) Line of Business
7) Countries
8) Regions

====================================================================================================

</pre>
</font>
##BD_END

##PD   tableName 	^^ Respective exclusion layer table name for retro treaty Or inuring cover treaty or case treaty
##PD   node_key 	^^ Key of aport or program or case
##PD   debugFlag	^^ Debug flag (debugged if value > 0)

##RS 	TRTY_KEY	^^ Treaty key
##RS 	LAYER_KEY	^^ Layer key
##RS 	EXCL_NUM	^^ Exclusion number
##RS 	EXCL_MODE	^^ Exclusion mode
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
   declare @treatyKey char(20)
   declare @layerKey char(20)
   declare @count1 int
   declare @count2 int
   declare @regionList varchar(max)
   declare @count_lobl_1 int
   declare @count_lobl_2 int
   declare @trtyKeyList varchar(max)
   declare @qry varchar(255)
   declare @SWV_curs2_layer_key varchar(255)
   declare @SWV_curs2_exclNo varchar(255)
   declare @SWV_curs2_cntry_id varchar(255)
   declare @SWV_curs2_Count2 varchar(255)
   declare @curs2 cursor
   declare @tempVal varchar(max)
  -- initialize standard items
   set @me = 'absp_Print_GetExclTreatyData: ' -- set to my name Procedure Name
   set @debug = 1 -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   if @debug > 0
   begin
      execute absp_messageEx @msg
   end
  -- set the fieldNames based on tableName
   select   @tableName2 = LOWER(@tableName) 
   if(@tableName2 = 'caseexcl')
   begin
      set @keyFieldName = 'CASEEX_KEY'
      set @treatyKey = 'CASE_KEY'
      set @layerKey = 'CSLAYR_KEY'
      set @trtyKeyList = ' in ( '+str(@node_key)+')'
   end
   else
   begin
      if(@tableName2 = 'inurexcl')
      begin
         set @keyFieldName = 'INUREX_KEY'
         set @treatyKey = 'INUR_KEY'
         set @layerKey = 'INLAYR_KEY'
         set @qry = 'select INUR_KEY from INURINFO where prog_key = '+str(@node_key)
         execute absp_Util_GenInList @trtyKeyList out, @qry
      end
      else
      begin
         if(@tableName2 = 'rtroexcl')
         begin
            set @keyFieldName = 'RTROEX_KEY'
            set @treatyKey = 'RTRO_KEY'
            set @layerKey = 'RTLAYR_KEY'
            set @qry = 'select RTRO_KEY from RTROINFO where parent_key = '+str(@node_key)
            execute absp_Util_GenInList @trtyKeyList out, @qry
         end
      end
   end
  -- Create temp tables
   create table #PRINTTMP
   (
      trty_key INT   null,
      LAYER_KEY INT   null,
      EXCL_NUM INT   null,
      EXCL_MODE CHAR(1)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      PERIL CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      LOB CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      COUNTRY CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      REGION VARCHAR(255)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   create table #TMP_PTL_JOIN_TABLE
   (
      trty_key INT   null,
      layr_key INT   null,
      excl_num INT   null,
      excl_mode CHAR(1)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      rrgngrp_id INT   null,
      peril_name CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   create index index_1 on #TMP_PTL_JOIN_TABLE
   (rrgngrp_id asc)
   create table #TMP_RLOBL_JOIN_TABLE
   (
      trty_key INT   null,
      layr_key INT   null,
      excl_num INT   null,
      excl_mode CHAR(1)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      rrgngrp_id INT   null,
      lob_name CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   create index index_1 on #TMP_RLOBL_JOIN_TABLE
   (rrgngrp_id asc)
   create table #TMP_RREGIONS_JOIN_TABLE
   (
      trty_key INT   null,
      layr_key INT   null,
      excl_num INT   null,
      excl_mode CHAR(1)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      rrgngrp_id INT   null,
      country CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      region CHAR(256)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   create index index_1 on #TMP_RREGIONS_JOIN_TABLE
   (rrgngrp_id asc)
  -- Create temp tables

   select distinct RRGNGRP_ID,R_LOB_NO,LOB_NAME into #TMP_RLOBL_DATA
   from RLOBL join
   RRGNLIST on RRGNLIST.country_id = RLOBL.country_id join
   RREGIONS on RRGNLIST.rrgn_key = RREGIONS.rrgn_key where
   FILETYP_ID = 2
   set @sql = 'insert into #TMP_PTL_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', excl_num, excl_mode, '+@tableName2+'.rrgngrp_id, peril_name from ptl  inner join '+@tableName2+' on excl_value = peril_id where ptl.trans_id in (10000, 57, 59) and excl_type = 1 and peril_id <> 6 and peril_id <> 7 and in_list = ''Y'' and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   set @sql = 'insert into #TMP_RLOBL_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', excl_num, excl_mode, '+@tableName2+'.rrgngrp_id, lob_name from #TMP_RLOBL_DATA, '+@tableName2+' where excl_value = r_lob_no and excl_type = 2 and #TMP_RLOBL_DATA.rrgngrp_id = '+@tableName2+'.rrgngrp_id '+' and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
   execute(@sql)
   set @sql = 'insert into #TMP_RREGIONS_JOIN_TABLE select distinct '+@treatyKey+', '+@layerKey+', excl_num, excl_mode, '+@tableName2+'.rrgngrp_id, case when charindex (''-'', rrgngrps.name )=0 then '''' else left (rrgngrps.name, charindex (''-'', rrgngrps.name )-1) end as country, rregions.name as region from '+@tableName2+' inner join rregions on rrgn_key = excl_value and excl_type = 3 inner join rrgngrps on rrgngrps.rrgngrp_id = '+@tableName2+'.rrgngrp_id'+' and '+@treatyKey+@trtyKeyList
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end

   execute(@sql)
   select rrgngrp_id,count(name) as cnt into #TMPRREGIONS_CNT from RREGIONS group by rrgngrp_id
   create table #TMP_RRGN_CNT (layr_key int , excl_num int, rrgngrp_id int ,cnt int)

   set @sql = 'Insert into  #TMP_RRGN_CNT select distinct ' + @layerKey + ' as layr_key, excl_num, rrgngrp_id ,count(excl_value) as cnt  from '+ @tableName2 + ' where excl_type = 3  and '+ @treatyKey + @trtyKeyList + ' group by '+ @layerKey+ ', excl_num, rrgngrp_id'
   
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end
  
   execute(@sql)
   create table #TMP_LOBL_CNT(layr_key int , excl_num int , rrgngrp_id int,cnt int )  
   set @sql = 'Insert into #TMP_LOBL_CNT select distinct '+@layerKey+' as layr_key, excl_num, rrgngrp_id ,count(excl_value) as cnt  from '+@tableName2+' where excl_type = 2  and '+@treatyKey+@trtyKeyList+' group by '+@layerKey+', excl_num, rrgngrp_id'
   if(@debug > 0)
   begin
      execute absp_messageEx @sql
   end

   execute(@sql)
   select rrgngrp_id,Count(distinct r_lob_no) as cnt into #TMPRLOBL_CNT from RLOBL,RREGIONS,RRGNLIST where
   RLOBL.country_id = RRGNLIST.country_id and RRGNLIST.rrgn_key = RREGIONS.rrgn_key and
   TRANS_ID in(10000,0,57, 59) and FILETYP_ID = 2
   group by rrgngrp_id order by rrgngrp_id asc
   
  /*
  * For Degub only 
  *

  select * from #TMP_RRGN_CNT;
  select * from #TMP_RREGIONS_JOIN_TABLE;
  select * from #TMP_RLOBL_DATA order by rrgngrp_id;;
  select * from #TMP_RLOBL_JOIN_TABLE order by rrgngrp_id;
  select * from #TMPRLOBL_CNT order by rrgngrp_id;
  select * from #TMP_LOBL_CNT order by rrgngrp_id;
  */
  -- Now loop thru each country and get the print data
--

   set @curs2 = cursor dynamic for select distinct LAYR_KEY as LAYER_KEY,EXCL_NUM as EXCLNO,RRGNGRP_ID as CNTRY_ID,CNT as COUNT2 from #TMP_RRGN_CNT
   open @curs2
   fetch next from @curs2 into @SWV_curs2_layer_key,@SWV_curs2_exclNo,@SWV_curs2_cntry_id,@SWV_curs2_Count2
   while @@fetch_status = 0
   begin
      print 'loop ==== '+str(@SWV_curs2_cntry_id)
      select   @count1 = cnt  from #TMPRREGIONS_CNT where rrgngrp_id = @SWV_curs2_cntry_id
      if(@count1 = @SWV_curs2_Count2)
      begin
         set @regionList = 'All Regions'
      end
   else
   begin
        /*
	select   @regionList = list(distinct rtrim(ltrim(region)),', ')  from #TMP_RREGIONS_JOIN_TABLE where
        rrgngrp_id = @SWV_curs2_cntry_id and layr_key = @SWV_curs2_layer_key and excl_num = @SWV_curs2_exclNo
	*/
	set @tempVal =   ' select  distinct rtrim(ltrim(region)) from #TMP_RREGIONS_JOIN_TABLE where  
        rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and layr_key = ' + str(@SWV_curs2_layer_key) + 
	 ' and excl_num = ' + str(@SWV_curs2_exclNo) 
	exec absp_util_geninlist   @regionList out, @tempVal
		
	set @regionList = right(@regionList ,len(@regionList )-5)
	set @regionList = ltrim(rtrim(@regionList ))
	set @regionList = left(@regionList ,len(@regionList)-1)
	
      end
      select   @count_lobl_1 = cnt  from #TMPRLOBL_CNT where rrgngrp_id = @SWV_curs2_cntry_id
      select   @count_lobl_2 = cnt  from #TMP_LOBL_CNT where rrgngrp_id = @SWV_curs2_cntry_id and excl_num = @SWV_curs2_exclNo and
      layr_key = @SWV_curs2_layer_key
      if(@count_lobl_1 = @count_lobl_2)
      begin
         set @sql = 'insert into #PRINTTMP select distinct t1.trty_key, t1.layr_key, t1.excl_num, t1.excl_mode, t1.peril_name, '' All LOBs '' , t3.country, '''+@regionList+''' from #TMP_PTL_JOIN_TABLE t1, #TMP_RREGIONS_JOIN_TABLE t3 where t1.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) +'
         and t3.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t1.layr_key = ' + str(@SWV_curs2_layer_key) + ' and t3.layr_key = ' + str(@SWV_curs2_layer_key) + ' and t1.excl_num = ' + str(@SWV_curs2_exclNo) + ' and t3.excl_num = ' + str(@SWV_curs2_exclNo)
      end
      else
      begin
         set @sql = 'insert into #PRINTTMP select distinct t1.trty_key, t1.layr_key, t1.excl_num, t1.excl_mode, t1.peril_name, t2.lob_name, t3.country, '''+@regionList+''' from #TMP_PTL_JOIN_TABLE t1, #TMP_RLOBL_JOIN_TABLE t2, #TMP_RREGIONS_JOIN_TABLE t3 where t1.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t2.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t3.rrgngrp_id = ' + str(@SWV_curs2_cntry_id) + ' and t1.layr_key = ' + str(@SWV_curs2_layer_key)  + ' and t2.layr_key = ' + str(@SWV_curs2_layer_key)  + ' and t3.layr_key = ' + str(@SWV_curs2_layer_key)  + ' and t1.excl_num = ' + str(@SWV_curs2_exclNo) + ' and t2.excl_num = ' + str(@SWV_curs2_exclNo) + ' and t3.excl_num = ' + str(@SWV_curs2_exclNo)
      end
      execute absp_messageEx @sql
      execute(@sql)
      
      fetch next from @curs2 into @SWV_curs2_layer_key,@SWV_curs2_exclNo,@SWV_curs2_cntry_id,@SWV_curs2_Count2
   end
   close @curs2
   deallocate @curs2
   select distinct  trty_key AS TRTY_KEY, LAYER_KEY AS LAYER_KEY, EXCL_NUM AS EXCL_NUM, EXCL_MODE AS EXCL_MODE, PERIL AS PERIL, LOB AS LOB, COUNTRY AS COUNTRY, REGION AS REGION from #PRINTTMP order by trty_key asc,LAYER_KEY asc,EXCL_NUM asc,COUNTRY asc,PERIL asc,LOB asc
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end


