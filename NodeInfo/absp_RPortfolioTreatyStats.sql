if exists(select * from SYSOBJECTS where ID = object_id(N'absp_RPortfolioTreatyStats') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_RPortfolioTreatyStats
end
go

create procedure absp_RPortfolioTreatyStats @RPortfolioKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a single resultset containing the count of each of the different treaties 
defined for all the base cases under the given rport.

Returns:	A single reultset containing the count of each of the different treaties 
defined for all the base cases under the given rport

====================================================================================================
</pre>
</font>
##BD_END

##PD  @RPortfolioKey ^^  The key of the rport .

##RS T1 ^^ The count of Excess Of Loss Treaty
##RS T2 ^^ The count of Quota Share Treaty
##RS T3 ^^ The count of Stop Loss Treaty
##RS T4 ^^ The count of 2nd Event Treaty
##RS T5 ^^ The count of 3rd Event Treaty
##RS T6 ^^ The count of Surplus Share Treaty
##RS T7 ^^ The count of Industry Loss Warrenty Treaty
##RS T8 ^^ The count of Per Risk Treaty
##RS T9 ^^ Reserved (Currently Not Supported)
##RS T10 ^^ The count of InnerAggregate Treaty (Currently Not Supported)
##RS T11 ^^ The count of 1st Event Treaty
##RS T12 ^^ The count of 4th Event Treaty
##RS T13 ^^ The count of 5th Event Treaty
##RS T14 ^^ The count of 6th Event Treaty
##RS T15 ^^ Reserved (Currently Not Supported)

*/
begin

   set nocount on
   
  -- how you know you are done with loop
   
   declare @sql1 varchar(max)
   declare @rport_node_type int
   declare @prog_node_type int
   declare @sql varchar(1000)
   declare @programCondition varchar(100)
   declare @trKey int
   declare @trCnt int
   declare @Type1Count int
   declare @Type2Count int
   declare @Type3Count int
   declare @Type4Count int
   declare @Type5Count int
   declare @Type6Count int
   declare @Type7Count int
   declare @Type8Count int
   declare @Type9Count int
   declare @Type10Count int
   declare @Type11Count int
   declare @Type12Count int
   declare @Type13Count int
   declare @Type14Count int
   declare @Type15Count int
   set @Type1Count = 0
   set @Type2Count = 0
   set @Type3Count = 0
   set @Type4Count = 0
   set @Type5Count = 0
   set @Type6Count = 0
   set @Type7Count = 0
   set @Type8Count = 0
   set @Type9Count = 0
   set @Type10Count = 0
   set @Type11Count = 0
   set @Type12Count = 0
   set @Type13Count = 0
   set @Type14Count = 0
   set @Type15Count = 0
  -- set default condition phase	
   set @programCondition = ' and caseinfo.case_key = proginfo.bcase_key '

  -- Based on the RPORT node type we can find out the program node_type since
  -- we cannot have a Multi-Treaty program under a Regular RPORT and vice-versa
  -- If Reference Portfolio is not set then RPortfolioKey = 0 need to handle that case too.
   if(@RPortfolioKey > 0)
   begin
      execute @rport_node_type = absp_Util_GetRPortType @RPortfolioKey

     -- all cases under an MT program will be included
      if(@rport_node_type = 3)
      begin
         set @prog_node_type = 7
      end
      else
      begin
         if(@rport_node_type = 23)
         begin
            set @prog_node_type = 27
            set @programCondition = ' '
         end
      end
   end
   else
   begin
      set @prog_node_type = 7
   end
  -- this query gets all the stats you need
   --set @sql = 'SELECT trtytype.TTYPE_ID, Count(*) AS TypeCount '+'FROM rportmap '+'INNER JOIN ((caseinfo '+'INNER JOIN proginfo ON caseinfo.PROG_KEY = proginfo.PROG_KEY '+@programCondition+' ) '+'INNER JOIN trtytype ON caseinfo.TTYPE_ID = trtytype.TTYPE_ID) '+'ON rportmap.CHILD_KEY = proginfo.PROG_KEY '+'WHERE rportmap.CHILD_TYPE = '+str(@prog_node_type)+' AND RPORTMAP.RPORT_KEY = '+str(@RPortfolioKey)+' GROUP BY trtytype.TTYPE_ID '+' ORDER BY trtytype.TTYPE_ID'  
-- what we do is loop thru each result set and set the apropriate variable
   begin
	  
      set @sql1= 'Declare rs CURSOR GLOBAL FOR SELECT trtytype.TTYPE_ID, Count(*) AS TypeCount FROM rportmap 
      INNER JOIN ((caseinfo INNER JOIN proginfo ON caseinfo.PROG_KEY = proginfo.PROG_KEY 
      '+@programCondition+')  INNER JOIN trtytype ON caseinfo.TTYPE_ID = trtytype.TTYPE_ID) 
      ON rportmap.CHILD_KEY = proginfo.PROG_KEY WHERE rportmap.CHILD_TYPE = '+str(@prog_node_type) +'AND RPORTMAP.RPORT_KEY = '+str(@RPortfolioKey)+' GROUP BY trtytype.TTYPE_ID
      ORDER BY trtytype.TTYPE_ID'
   
      execute(@sql1)
   
      open rs 
      loopvals: while 1 = 1
      begin
         fetch next FROM rs into @trKey,@trCnt
         --if NULL = err_notfound

         if @@fetch_status != 0
            begin
            break
         end
         if @trKey = 1
         begin
            set @Type1Count = @trCnt
         end
         else
         begin
            if @trKey = 2
            begin
               set @Type2Count = @trCnt
            end
            else
            begin
               if @trKey = 3
               begin
                  set @Type3Count = @trCnt
               end
               else
               begin
                  if @trKey = 4
                  begin
                     set @Type4Count = @trCnt
                  end
                  else
                  begin
                     if @trKey = 5
                     begin
                        set @Type5Count = @trCnt
                     end
                     else
                     begin
                        if @trKey = 6
                        begin
                           set @Type6Count = @trCnt
                        end
                        else
                        begin
                           if @trKey = 7
                           begin
                              set @Type7Count = @trCnt
                           end
                           else
                           begin
                              if @trKey = 8
                              begin
                                 set @Type8Count = @trCnt
                              end
                              else
                              begin
                                 if @trKey = 9
                                 begin
                                    set @Type9Count = @trCnt
                                 end
                                 else
                                 begin
                                    if @trKey = 10
                                    begin
                                       set @Type10Count = @trCnt
                                    end
                                    else
                                    begin
                                       if @trKey = 11
                                       begin
                                          set @Type11Count = @trCnt
                                       end
                                       else
                                       begin
                                          if @trKey = 12
                                          begin
                                             set @Type12Count = @trCnt
                                          end
                                          else
                                          begin
                                             if @trKey = 13
                                             begin
                                                set @Type13Count = @trCnt
                                             end
                                             else
                                             begin
                                                if @trKey = 14
                                                begin
                                                   set @Type14Count = @trCnt
                                                end
                                                else
                                                begin
                                                   if @trKey = 15
                                                   begin
                                                      set @Type15Count = @trCnt
                                                   end
                                                end
                                             end
                                          end
                                       end
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      close rs
      deallocate rs
   end
  -- return the  answers
   select   T1 = @Type1Count,  T2 = @Type2Count,T3 = @Type3Count ,  
T4 = @Type4Count,T5 = @Type5Count  , T6 = @Type6Count,T7 = @Type7Count , T8 = @Type8Count,
T9 = @Type9Count, T10 = @Type10Count, T11 = @Type11Count, T12 = @Type12Count, 
T13 = @Type13Count,T14 = @Type14Count, T15 = @Type15Count
end





