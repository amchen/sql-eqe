if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ChasCurrencyRateOrConvert') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_ChasCurrencyRateOrConvert
end
go

create procedure absp_ChasCurrencyRateOrConvert @ret_amt_USD float(53) output ,@currskKey int,@currCodeIn char(20),@amount float(53) = -1.0,@reverseCalc int = 0
/*

##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This Procedure returns the US dollar equivalent of the given amount for given currency code
and currency key.	              

Returns:     The US dollar equivalent of the given amount.               
====================================================================================================
</pre>
</font>
##BD_END

##PD  ret_amt_USD ^^ The US dollar equivalent of the given amount.
##PD  currskKey ^^  The currency key for which the amount is to be calculated.
##PD  currCodeIn ^^ The currency code for which the amount is to be calculated. 
##PD  amount ^^ The Amount in the given currency code.
##PD  reverseCalc ^^ A flag to indicate if reverse calculation will be done or not.


*/
as
begin

   set nocount on
   
   declare @UsdRate float(53)
   declare @OthrRate float(53)
   declare @xchgRate float(53)
   declare @factor float(53)
   declare @letter char(1)
   declare @currCode varchar(20)
  
   set @currCode = rtrim(ltrim(@currCodeIn))
  -- IF the code is any sort of USD, then the exchange rate is 1.0 or a 10**x multiple thereof
	
   if lower(left(@currCode,3)) = 'usd'
   begin
      if lower(@currCode) = 'usd'
      begin
         set @xchgRate = 1.0
      end
      else
      begin
         set @letter = lower(right(@currCode,1))
         set @xchgRate = 1.0
         if @letter = 'k'
         begin
            set @xchgRate = 1000.0
         end
         else
         begin
            if @letter = 'm'
            begin
               set @xchgRate = 1000000.0
            end
            else
            begin
               if @letter = 'g'
               begin
                  set @xchgRate = 1000000000.0
               end
               else
               begin
                  if @letter = 't'
                  begin
                     set @xchgRate = 1000000000000
                  end
               end
            end
         end
      end
      if @amount = -1.0
      begin
      --    return  (@xchgRate); 
         set @ret_amt_USD = @xchgRate
      end
      else
      begin
         if @reverseCalc <> 1
         begin
            set @ret_amt_USD =(@amount*@xchgRate)
         end
         else
         begin
            set @ret_amt_USD =(@amount/@xchgRate)
         end
      end
   end
  -- OK, if we are here, then it is NOT USD

  -- get the rate for USD they have specified, if any (the rules say there should be one - we assume 1.0 if not anyway)
   set @UsdRate = -1.0
   set @letter = ''
   select   @UsdRate = EXCHGRATE  from EXCHRATE where
   ACTIVE = 'Y' and EXCHGRATE > 0 and CURRSK_KEY = @currskKey and rtrim(ltrim(CODE)) = 'USD'



	if @UsdRate = -1.0
   begin
      select  top 1 @UsdRate = EXCHGRATE, @letter = LOWER(right(rtrim(ltrim(CODE)),1))  from EXCHRATE where
      ACTIVE = 'Y' and EXCHGRATE > 0 and CURRSK_KEY = @currskKey and left(rtrim(ltrim(CODE)),3) = 'USD'

      if @UsdRate = -1.0
      begin
         set @UsdRate = 1.0
      end
      else
      begin

         if @letter = 'k'
         begin
            set @UsdRate = @UsdRate*1000.0
         end
         else
         begin
            if @letter = 'm'
            begin
               set @UsdRate = @UsdRate*1000000.0
            end
            else
            begin
               if @letter = 'g'
               begin
                  set @UsdRate = @UsdRate*1000000000.0
               end
               else
               begin
                  if @letter = 't'
                  begin
                     set @UsdRate = @UsdRate*1000000000000
                  end
               end
            end
         end
      end
   end
  -- Now get the other rate
   set @OthrRate = -1.0
   set @factor = 1.0
   select  top 1 @OthrRate = EXCHGRATE  from EXCHRATE where
   ACTIVE = 'Y' and EXCHGRATE > 0 and CURRSK_KEY = @currskKey and rtrim(ltrim(CODE)) = @currCode


if @OthrRate = -1.0
   begin
      set @letter = LOWER(right(@currCode,1))
      if @letter = 'k' or @letter = 'm' or @letter = 'g' or @letter = 't'
      begin
         select  top 1 @OthrRate = EXCHGRATE  from EXCHRATE where
         ACTIVE = 'Y' and EXCHGRATE > 0 and CURRSK_KEY = @currskKey and rtrim(ltrim(CODE)) =
         left(@currCode,LEN(@currCode) -1)
      end
      if @OthrRate = -1.0
      begin

         set @OthrRate = 1.0
      end
      else
      begin
         if @letter = 'k'
         begin
            set @factor = 1000.0
         end
         else
         begin
            if @letter = 'm'
            begin
               set @factor = 1000000.0
            end
            else
            begin
               if @letter = 'g'
               begin
                  set @factor = 1000000000.0
               end
               else
               begin
                  if @letter = 't'
                  begin
                     set @factor = 1000000000000
                  end
               end
            end
         end
      end
   end
   if @OthrRate = -1.0
   begin
      set @OthrRate = 1.0
   end
   set @xchgRate = @OthrRate/@UsdRate
 

   if @amount = -1.0
   begin
      set @amount = 1.0
   end
   if @reverseCalc = 1
   begin
      set @ret_amt_USD =(@amount*@xchgRate)/@factor
   end
   else
   begin
      set @ret_amt_USD =(@amount/@xchgRate)*@factor
   end
end
