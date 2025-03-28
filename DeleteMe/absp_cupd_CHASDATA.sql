if exists(select * from SYSOBJECTS where ID = object_id(N'absp_cupd_CHASDATA') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_cupd_CHASDATA
end
go

create procedure absp_cupd_CHASDATA @cupdKey int,@chasKey int,@debug int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure performs a currency conversion for the currency values in the CHASDATA table for the
given chasKey.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  cupdKey ^^  The currency update key. 
##PD  chasKey ^^  The chasKey for which the currency conversion is to be done.
##PD  debug ^^  The debug flag.

*/
as

begin

   set nocount on
   
  /*
  This procedure is part of a set used to update the currency values of a table.

  Alg:
  1.  Load the CURRATIO table into a local temporary table (to make it a memory table)
  2.  cursor through each record of CHASDATA for a given CHAS_KEY
  3.  handle each currency field by
  a)   Look up the field Ratio for each field currency code in the CURRATIO_TEMP table
  b)   New value[i] = Ratio * currency value[i]
  4.  update the currency values in the record using the appropriate keys to update only this record


  */
  /*
  currency fields:

  cast(ratio as char)+', DEDUCTUSD = DEDUCTUSD *'+
  cast(ratio as char)+', LIMITUSD = LIMITUSD *'+
  cast(ratio as char)+', POLDEDUSD = POLDEDUSD *'+
  cast(ratio as char)+', POLLIMUSD = POLLIMUSD *'+
  cast(ratio as char)+', PDEDMINUSD = PDEDMINUSD *'+
  cast(ratio as char)+', UNDRCVRUSD = UNDRCVRUSD *'+


  UNIQUE INDEX CHASDATA_I1 ON CHAS_KEY, ROW_NO


  */
   declare @cc0 char(5)
   declare @cc1 char(5)
   declare @val1 float(53)
   declare @cc2 char(5)
   declare @val2 float(53)
   declare @cc3 char(5)
   declare @val3 float(53)
   declare @cc4 char(5)
   declare @val4 float(53)
   declare @cc5 char(5)
   declare @val5 float(53)
   declare @cc6 char(5)
   declare @val6 float(53)
   declare @cc7 char(5)
   declare @val7 float(53)
   declare @ratio1 float(53)
   declare @value1 float(53)
   declare @value2 float(53)
   declare @value3 float(53)
   declare @value4 float(53)
   declare @value5 float(53)
   declare @value6 float(53)
   declare @value7 float(53)
   declare @cBaseCode char(3)
   declare @ccField char(5)
   declare @ccUnit char(1)
   declare @cCode char(3)
   declare @me varchar(255)
   declare @msgTxt01 varchar(255)
   declare @CURRENCY char(8)
   declare @VALUEUSD float(53)
   declare @DEDUCTUSD float(53)
   declare @LIMITUSD float(53)
   declare @POLDEDUSD float(53)
   declare @POLLIMUSD float(53)
   declare @PDEDMINUSD float(53)
   declare @UNDRCVRUSD float(53)
   
   declare curs_chasdata  cursor forward_only for
		select CURRENCY,VALUEUSD,DEDUCTUSD,LIMITUSD,POLDEDUSD,POLLIMUSD,PDEDMINUSD,UNDRCVRUSD
			from CHASDATA
			where CHAS_KEY = @chasKey
   
   set @me = 'absp_cupd_CHASDATA: ' -- set to my name (name_of_proc plus ': '
   set @msgTxt01 = 'start '+@me+' cupdKey = '+rtrim(ltrim(str(@cupdKey)))+' chasKey = '+rtrim(ltrim(str(@chasKey)))
   execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
   
   set @cc0 = '...'
   -- iterate the CHASDATA table records
   open curs_chasdata
   fetch next from curs_chasdata into @CURRENCY,@VALUEUSD,@DEDUCTUSD,@LIMITUSD,@POLDEDUSD,@POLLIMUSD,@PDEDMINUSD,@UNDRCVRUSD
   while @@fetch_status = 0
   begin
   
	   if (@CURRENCY is not NULL)
	   begin
	   
		  set @cc1 = @CURRENCY
		  set @val1 = @VALUEUSD
		  set @val2 = @DEDUCTUSD
		  set @val3 = @LIMITUSD
		  set @val4 = @POLDEDUSD
		  set @val5 = @POLLIMUSD
		  set @val6 = @PDEDMINUSD
		  set @val7 = @UNDRCVRUSD
		  
		  if @cc0 <> @cc1
		  begin
				 set @cc0 = @cc1
				 -- look up each currency field ratio
				 -- only if it is a monetary value (not days or percent)
				 -- calculate value = ratio * oldvalue
				 set @ccField = @cc1
				 set @cCode = left(@ccField,3)
				 set @cBaseCode = @cCode
				 set @ccUnit = right(@ccField,1)
				 
				 select @ratio1 = RATIO  from #CURRATIO_TMP where CODE = @cCode
				 
				 if @ratio1 is null
				 begin
					set @msgTxt01 = 'invalid currency code '+@ccField+'for CHASDATA chasKey '+rtrim(ltrim(str(@chasKey)))
					execute absp_CupdLogMessage @cupdKey,'E',@msgTxt01,'CHAS_KEY',@chasKey
					set @value1 = @val1
					set @value2 = @val2
					set @value3 = @val3
					set @value4 = @val4
					set @value5 = @val5
					set @value6 = @val6
					set @value7 = @val7
				 end
				 else
				 begin
					set @value1 = @ratio1*@val1
					set @value2 = @ratio1*@val2
					set @value3 = @ratio1*@val3
					set @value4 = @ratio1*@val4
					set @value5 = @ratio1*@val5
					set @value6 = @ratio1*@val6
					set @value7 = @ratio1*@val7
				 end
		  end
		  else
		  begin
				 set @value1 = @ratio1*@val1
				 set @value2 = @ratio1*@val2
				 set @value3 = @ratio1*@val3
				 set @value4 = @ratio1*@val4
				 set @value5 = @ratio1*@val5
				 set @value6 = @ratio1*@val6
				 set @value7 = @ratio1*@val7
		  end
		  
		  --======================================
		  -- update the record with the new currency values
		  declare @sql varchar(1000)
		  set @sql = 'RATIO = ' + str(@ratio1) + ', VALUEUSD = ' + str(@value1) + ', DEDUCTUSD = ' + str(@value2) + ', LIMITUSD = ' + str(@value3) + ', POLDEDUSD = ' + str(@value4) + ', POLLIMUSD = ' + str(@value5) + ', PDEDMINUSD = ' + str(@value6) + ', UNDRCVRUSD = ' + str(@value7)
		  update CHASDATA
				set VALUEUSD = @value1, DEDUCTUSD = @value2, LIMITUSD = @value3, POLDEDUSD = @value4, POLLIMUSD = @value5, PDEDMINUSD = @value6, UNDRCVRUSD = @value7
				where current of curs_chasdata
	  end
	  fetch next from curs_chasdata into @CURRENCY,@VALUEUSD,@DEDUCTUSD,@LIMITUSD,@POLDEDUSD,@POLLIMUSD,@PDEDMINUSD,@UNDRCVRUSD
   end
   close curs_chasdata
   deallocate curs_chasdata
   
   -- note:  I purposely do not commit.   The driver promised to commit after updating all of the tables.
   -- with this chasKey
   set @msgTxt01 = 'end   '+@me+' cupdKey = '+rtrim(ltrim(str(@cupdKey)))+' chasKey = '+rtrim(ltrim(str(@chasKey)))
   execute absp_CupdLogMessage @cupdKey,'M',@msgTxt01
end
