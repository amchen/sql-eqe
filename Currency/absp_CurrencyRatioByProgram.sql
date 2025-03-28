if exists(select * from SYSOBJECTS WHERE id = object_id(N'absp_CurrencyRatioByProgram') and OBJECTPROPERTY(Id,N'IsProcedure') = 1)
begin
   drop procedure absp_CurrencyRatioByProgram
end
go
create  procedure absp_CurrencyRatioByProgram @table_to_update CHAR(120),@src_curr_key INT,@dest_curr_key INT , @targetDb varchar(130) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure expects a table name created by absp_CheckIsSingleCurrencyUsed procedure. This
procedure processes all the programs in the given table that uses a single currency schema and
calculates the USD ratio. The CurrConvR engine will use this multipler to update all the intermediate
records.

The formula to calculate the ratio is as shown below.

Multiplier = OLD_RATIO/NEW_RATIO

For Example:

In Currency Schema 1, 2 USD = 3 EUR
In Currency Schema 2, 4 USD = 5 EUR

If the user is copying a program from Currency Schema 1 to Currency Schema 2 then the blob currency data 
should be multiplied by the following ratio

New USD RATIO = 5/4;
Old USD RATIO = 3/2

Multiplier = (3/2)/(5/4) = 1.2

Lets assume that user input was 60 EUR. 
In Currency Schema 1 the USD value is 40 USD
In Currency Schema 2 the USD value is 48 USD for the same 60 EUR.

So when we copy Intermediate results from schema 1 to schema 2 we need to multiple the USD value with the 
multipler to get the correct USD value. In the above example we need to multiple 90 USD * .8333 = 75 USD.


Returns:      Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  table_to_update ^^  The table name whose CURR_RATIO column is to be updated.  
##PD  src_curr_key ^^  Source Currency Schema.
##PD  dest_curr_key ^^ Destination Currency Schema.


*/
AS
begin

   set nocount on
   
   --declare @curs1 cursor
   declare @sql varchar(max)
   declare @sql1 nvarchar(4000)
   declare @exists int
   declare @currCode char(3)
   declare @progKey int
   declare @newRatio float(53)
   declare @oldRatio float(53)
   declare @usdRate float(53)
   declare @otherRate float(53)
   declare @currRatio float(53)
   declare @ifExsits int
   
   set @currCode = ''
   set @progKey = 0.0
   set @newRatio = 0.0
   set @oldRatio = 0.0
   set @usdRate = 0.0
   set @otherRate = 0.0
   set @ifExsits = 0
   
   if @targetDB=''
      set @targetDB = DB_NAME()
      	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB
   
   set @sql1 = 'select @ifExsits = 1 from ' + @targetDB + '..sysobjects where name = ''' + dbo.trim(@table_to_update) + ''''
   exec sp_executesql @sql1,N' @ifExsits int output', @ifExsits output
   
   if @ifExsits = 1
   begin
      set @sql = 'select SRC_PROG_KEY, CURR_CODE, CURR_RATIO from '+@targetDB + '.dbo.'+ rtrim(ltrim(@table_to_update))+' where IS_CURR_MISMATCH = ''N'''
      begin
		set @sql1 = 'declare curs1 CURSOR GLOBAL FOR '+ @sql + 'FOR UPDATE OF CURR_RATIO'
		exec (@sql1)

		   open curs1 
		   fetch next from curs1 into @progKey,@currCode,@currRatio
		   while @@FETCH_STATUS = 0
		   begin
         
		        set @sql1 = 'select @usdRate = EXCHGRATE  from EXCHRATE where CODE = ''USD'' and CURRSK_KEY = '+str(@src_curr_key)
 			exec sp_executesql @sql1,N' @usdRate float(53) output',@usdRate output
            		set @sql1 = 'select @otherRate = EXCHGRATE  from EXCHRATE where CODE = '''+@currCode+'''  and CURRSK_KEY = '+str(@src_curr_key)
                        exec sp_executesql @sql1,N' @otherRate float(53) output',@otherRate output
                        
            		print '@otherRate '+cast(@otherRate as CHAR)
            		print '@usdRate '+str(@usdRate)
            		set @oldRatio = @otherRate/@usdRate
            		set @usdRate = 0
            		set @sql1 = 'select @usdRate = EXCHGRATE from ' + @targetDB + '..EXCHRATE where CODE = ''USD'' and CURRSK_KEY = '+str(@dest_curr_key)
            
            	        exec sp_executesql @sql1,N' @usdRate float(53) output',@usdRate output
            		set @sql1 = 'select @otherRate = EXCHGRATE from ' + @targetDB + '..EXCHRATE where CODE = '''+@currCode+'''  and CURRSK_KEY = '+str(@dest_curr_key)
            
                        exec sp_executesql @sql1,N' @otherRate float(53) output',@otherRate output
            		print '@otherRate '+cast(@otherRate as char)
            		print '@usdRate '+cast(@usdRate as char)
            		set @newRatio = @otherRate/@usdRate
            		print '@newRatio '+cast(@newRatio as char)
            		print '@oldRatio '+cast(@oldRatio as char)
		        set @sql1 = 'UPDATE ' + @targetDB + '..'+rtrim(ltrim(@table_to_update))+' SET CURR_RATIO = '+ ltrim(rtrim(cast(@oldRatio/@newRatio as varchar))) +' WHERE CURRENT OF Curs1' --CURR_RATIO ='+ str(@currRatio)
            
            		execute(@sql1)
			fetch next from curs1 into @progKey,@currCode,@currRatio
            	   end
	           close curs1
         	   deallocate curs1
         	   end
      		end
   end
   




