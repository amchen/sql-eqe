
if exists(select * from SYSOBJECTS where id = object_id(N'absp_CheckNodeRelation') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckNodeRelation
end
 go
create procedure absp_CheckNodeRelation @nodeType1 int ,
@key1 int ,@extraKey1 int ,@nodeType2 int ,@key2 int ,@extraKey2 int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns 1 if the first node is an ancestor of the second, else returns 0. 

Returns:	It returns 1 if node1 is an ancestor of node2 else returns 0. 

====================================================================================================
</pre>
</font>
##BD_END

##PD  nodeType1 ^^  The type of the parent node
##PD  key1 ^^  The key of the parent node
##PD  extraKey1 ^^  Used in case of policies & sites.
##PD  nodeType2 ^^  The type of child node
##PD  key2 ^^  The key of the child node
##PD  extraKey2 ^^  Used in case of policies & sites.

##RD @retValue ^^ Returns 1 if node1 is an ancestor of node2 else returns 0. 

*/
as
begin
 
   set nocount on
   
  declare @retValue int
   declare @recCount int
   declare @numRecord int
   set @retValue = 0
  -- This procedure will check if node represented by nodeType1 is an ancestor node represented by nodeType2.
   -- folder node
     -- Accum node
     -- Primary port node
     -- Reins port node
     -- Muti-Treaty Reins port node
     -- program node
     -- program node
     -- policy node
     -- site node
     -- case node
     -- case node
   if @nodeType1 = 0
   begin
      set @retValue = 0
   end
   else
   begin
      if @nodeType1 = 1
      begin
         if @nodeType2 = 1
         begin
            if @key1 = @key2
            begin
               set @recCount = 1
            end
         end
         else
         begin
            if @nodeType2 = 2
            begin
               select  @numRecord = count(*)  from APORTMAP where child_key = @key2 and child_type = 2 and aport_key = @key1
               set @recCount = @numRecord
            end
            else
            begin
               if @nodeType2 = 3
               begin
                  select  @numRecord = count(*)  from APORTMAP where child_key = @key2 and child_type = 3 and aport_key = @key1
                  set @recCount = @numRecord
               end
               else
               begin
                    if (@nodeType2 = 7 or @nodeType2 = 27)
                    begin
                       select  @numRecord = count(*)  from APORTMAP where child_type in (3,23) and child_key = any(select  rport_key from rportmap where child_type in (7,27) and child_key = @key2) and aport_key = @key1
                       set @recCount = @numRecord
                    end
                    else
                    begin
                       if @nodeType2 = 10
                       begin
                          select  @numRecord = count(*)  from APORTMAP where child_type = 3 and child_key = any(select  rport_key from rportmap where child_type = 7 and child_key = any(select  prog_key from proginfo where BCASE_KEY = @key2)) and aport_key = @key1
                          set @recCount = @numRecord
                       end
                       else
                       begin
				if @nodeType2 = 30
				begin
					select  @numRecord = count(*)  from APORTMAP where child_type = 23 and child_key = any(select  rport_key from rportmap where child_type = 27 and child_key = any(select  prog_key from caseinfo where CASE_KEY = @key2)) and aport_key = @key1
					set @recCount = @numRecord
				end
				else
				begin
					set @recCount = 0
				end
			end
		  end
	     end
          end
        end
      end
      else
      begin
         if @nodeType1 = 2
         begin
            if @nodeType2 = 2
            begin
               if(@key1 = @key2)
               begin
                  set @recCount = 1
               end
            end
            else
            begin
               set @recCount = 0
            end
         end
         else
         begin
            if @nodeType1 = 3
            begin
               if @nodeType2 = 3
               begin
                  if(@key1 = @key2)
                  begin
                     set @recCount = 1
                  end
               end
               else
               begin
                  if @nodeType2 = 7
                  begin
                     select  @numRecord = count(*)  from rportmap where child_type = 7 and child_key = @key2 and rport_key = @key1
                     set @recCount = @numRecord
                  end
                  else
                  begin
                     if @nodeType2 = 10
                     begin
                        select  @numRecord = count(*)  from rportmap where child_type = 7 and child_key = any(select  prog_key from proginfo where BCASE_KEY = @key2) and rport_key = @key1
                        set @recCount = @numRecord
                     end
                     else
                     begin
                        set @recCount = 0
                     end
                  end
               end
            end
            else
            begin
               if @nodeType1 = 23
               begin
                  if @nodeType2 = 23
                  begin
                     if(@key1 = @key2)
                     begin
                        set @recCount = 1
                     end
                  end
                  else
                  begin
                     if @nodeType2 = 27
                     begin
                        select  @numRecord = count(*)  from rportmap where child_type = 27 and child_key = @key2 and rport_key = @key1
                        set @recCount = @numRecord
                     end
                     else
                     begin
                        if @nodeType2 = 30
                        begin
                           select  @numRecord = count(*)  from rportmap where child_type = 27 and child_key = any(select  prog_key from CASEINFO where CASE_KEY = @key2) and rport_key = @key1
                           set @recCount = @numRecord
                        end
                        else
                        begin
                           set @recCount = 0
                        end
                     end
                  end
               end
               else
               begin
                  if @nodeType1 = 7
                  begin
                     if @nodeType2 = 7
                     begin
                        if(@key1 = @key2)
                        begin
                           set @recCount = 1
                        end
                     end
                     else
                     begin
                        if @nodeType2 = 10
                        begin
                           select  @numRecord = count(*)  from proginfo where BCASE_KEY = @key2 and prog_key = @key1
                           set @recCount = @numRecord
                        end
                        else
                        begin
                           set @recCount = 0
                        end
                     end
                  end
                  else
                  begin
                     if @nodeType1 = 27
                     begin
                        if @nodeType2 = 27
                        begin
                           if(@key1 = @key2)
                           begin
                              set @recCount = 1
                           end
                        end
                        else
                        begin
                           if @nodeType2 = 30
                           begin
                              select  @numRecord = count(*)  from CASEINFO where CASE_KEY = @key2 and prog_key = @key1
                              set @recCount = @numRecord
                           end
                           else
                           begin
                              set @recCount = 0
                           end
                        end
                     end
                    	if @nodeType1 = 10
			begin -- Check for Program Node 
				if @nodeType2 = 7
				begin
					select  @numRecord = count(*)  from proginfo where BCASE_KEY = @key1 and prog_key = @key2
					set @recCount = @numRecord
				end
				else
				begin
					if @nodeType2 = 10
					begin
						if(@key1 = @key2)
						begin
							set @recCount = 1
						end
					end
					else
					begin
						set @recCount = 0
					end
				end
			end
			else
			begin
				if @nodeType1 = 30
				begin -- Check for Program Node 
					if @nodeType2 = 27
					begin
						select  @numRecord = count(*)  from CASEINFO where CASE_KEY = @key1 and prog_key = @key2
						set @recCount = @numRecord
					end
					else
					begin
						if @nodeType2 = 30
						begin
							if(@key1 = @key2)
							begin
								set @recCount = 1
							end
						end
						else
						begin
							set @recCount = 0
						end
					end
				end
				else
				begin
					set @recCount = 0
				end
			end
		end
	    end
	  end
         end
      end
   end
   if @recCount > 0
   begin
      set @retValue = 1
   end
   else
   begin
      set @retValue = 0
   end
   return @retValue
end

go


