if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_hasPasteLinkWithResults') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_hasPasteLinkWithResults
end
go

create procedure absp_hasPasteLinkWithResults @rportKey int,@progKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks if the given program has been paste linked to another rport and the destination
rport has been analyzed.

Returns:       A value @retVal
1. @retVal = 1, when the given program has been paste linked to another rport and analyzed
2. @retVal = 0, when the given program has not been paste linked and/or analyzed
====================================================================================================
</pre>
</font>
##BD_END

##PD  rportKey ^^  The key of the rport node.
##PD  progKey ^^  The key of the program node.

##RD  @retVal ^^  A return value signifying if the given program has been paste linked to another rport and/or analysis has been done.

*/
as
begin

   set nocount on
   declare @cntInstance int
  -- Fixed code to handle Multi-Treaty Node
   declare @cntResults int
   declare @retVal int
   declare @prog_node_type int
   declare @sql varchar(1000)
   declare @SWV_curs_rprtKey int
   declare @curs cursor
   declare @SWV_curs1_rprtKey int
   declare @curs1 cursor
   set @prog_node_type = 0
   if(@progKey > 0)
   begin
      
	exec @prog_node_type = absp_Util_GetProgramType @progKey
   end
  --	first we need to see if this is the only instance
   select @cntInstance = COUNT(*) from RPORTMAP where RPORT_KEY <> @rportKey and CHILD_KEY = @progKey AND CHILD_TYPE = @prog_node_type
   
   if @cntInstance > 0 and @prog_node_type = 7
   begin
      set @curs = cursor fast_forward for select RPORT_KEY   from RPORTMAP 
          where RPORT_KEY <> @rportKey and CHILD_KEY = @progKey and CHILD_TYPE = 7
      open @curs
      fetch next from @curs into @SWV_curs_rprtKey
      while @@fetch_status = 0
      begin
         if(select count(*)  from ReportsDone where NodeKey= @SWV_curs_rprtKey and NodeType=3) > 0
         begin
            set @retVal = 1
            return @retVal
         end
         fetch next from @curs into @SWV_curs_rprtKey
      end
      close @curs
      deallocate @curs
   end
   else
   begin
      if @cntInstance > 0 and @prog_node_type = 27
      begin
         set @curs1 = cursor fast_forward for  
               select RPORT_KEY from RPORTMAP where  RPORT_KEY <> @rportKey and CHILD_KEY = @progKey and CHILD_TYPE = 27
         open @curs1
         fetch next from @curs1 into @SWV_curs1_rprtKey
         while @@FETCH_STATUS = 0
         begin
            if(select count(*)  from ReportsDone where NodeKey = @SWV_curs1_rprtKey and NodeType=23) > 0
            begin
               set @retVal = 1
               return @retVal
            end
            fetch next from @curs1 into @SWV_curs1_rprtKey
         end
         close @curs1
         deallocate @curs1
      end
   end

   set @retVal = 0
   return @retVal
end



