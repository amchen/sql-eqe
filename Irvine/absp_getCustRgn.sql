if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_getCustRgn') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getCustRgn
end
go
create procedure absp_getCustRgn as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure returns single result set containing the custom region name, country, 
region key and region name for all available custom regions.

Returns:       Single result set containing the following fields:

1. Custom region name
2. Country 
3. Region key
4. Region name


====================================================================================================

</pre>
</font>
##BD_END

##RS	CUST_REGION_NAME	^^ Custom region name
##RS	COUNTRY			^^ Country
##RS	RRGN_KEY		^^ Region key
##RS	REGION_NAME		^^ Region name

*/
begin

set nocount on
  /*
  This procedure returns a record set containing CUST_RGN, COUNTRY and RRGNLIST info needed to
  populate the JTrees in the Custom Region Editor.

  */
   declare @sql varchar(MAX)
   declare @rrgnKeys varchar(MAX)
   declare @curs1_RegNm varchar(max)
   declare @curs1_RrgnKeys varchar(MAX)
   declare @curs1 cursor
   declare @rgnId int

   create table #CUST_RGNS
   (
      RGN_ID INT,
      CUST_REGION_NAME CHAR(50)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      COUNTRY CHAR(50)   COLLATE SQL_Latin1_General_CP1_CI_AS  null,
      RRGN_KEY INT   null,
      REGION_NAME CHAR(80)   COLLATE SQL_Latin1_General_CP1_CI_AS  null      
   )
   set @curs1 = cursor fast_forward for 
          select RGN_ID as RGN_ID, rtrim(ltrim(REG_NAME)) as REG_NAME,rtrim(ltrim(convert(varchar(MAX),RRGN_KEYS))) as RRGN_KEYS from CUST_RGN
   open @curs1
   fetch next from @curs1 into @rgnId,@curs1_RegNm,@curs1_RrgnKeys
   while @@fetch_status = 0
   begin

      set @rrgnKeys = @curs1_RrgnKeys
      if @rrgnKeys is null or len(@rrgnKeys) = 0
      begin
         set @sql = 'insert into #CUST_RGNS '+'select  '+ dbo.trim(str(@rgnId)) + ', '''+@curs1_RegNm+''' as CUST_REGION_NAME, '''' as COUNTRY, NULL, '''' as REGION_NAME '
      end
      else
      begin
         set @sql = 'insert into #CUST_RGNS '+'select  '+ dbo.trim(str(@rgnId)) + ', '''+@curs1_RegNm+''' as CUST_REGION_NAME, rtrim(ltrim(COUNTRY)) as COUNTRY, RRGN_KEY, rtrim(ltrim(r.Name)) as REGION_NAME '+'from RRGNLIST r, COUNTRY c '+'where r.COUNTRY_ID = c.COUNTRY_ID  '+'  and RRGN_KEY in ( '+@curs1_RrgnKeys+' )'
      end
      execute absp_MessageEx @sql
      execute(@sql)

      fetch next from @curs1 into @rgnId,@curs1_RegNm,@curs1_RrgnKeys
   end
   close @curs1
   deallocate @curs1
  -- SDG__00013799 -- add RRGN_KEY to sort, so that the 1999 Cresta Zone records follow the Country Level Region record 
   select * from #CUST_RGNS order by CUST_REGION_NAME asc,COUNTRY asc,RRGN_KEY asc,REGION_NAME asc

end





