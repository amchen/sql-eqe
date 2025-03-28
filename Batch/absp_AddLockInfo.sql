if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_AddLockInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_AddLockInfo
end

go
create procedure absp_AddLockInfo 
@tblName char(14),@fldName char(14),@nodeKey int, @tempPath varchar(max) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure add lock information to the temporary Table #LOCKINFO (assumed being previously created) 
	based on the values of the field name(@fldName) of the given blob table name(@tblName) and 
	the node key to be locked

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Name of the table for which the invalidation will take place
##PD  @fieldName ^^  Name of the key field of the above table
##PD  @nodeKey ^^  node Key to be locked
##PD  @tempPath ^^	log file path    

*/
AS
-- SDG__00017296, SDG__00019516 Invalidation on server startup takes forever

begin
   set nocount on
   declare @pk1 int
   declare @pk2 int
   declare @pk3 int
   declare @pkType int
   declare @execStr varchar(4000)    
   
   if OBJECT_ID('tempdb..#LOCKINFO','u') IS NULL
   begin
	   --print ' inside absp_AddLockInfo: LOCKINFO doesnt exist... It will be created!'
	   exec absp_Util_LogIt ' inside absp_AddLockInfo: LOCKINFO doesnt exist... It will be created!' ,1 ,'absp_AddLockInfo' , @tempPath
	   create table #LOCKINFO
	   (
		 KEY1 	  int,
		 KEY2 	  int,
		 KEY3 	  int,
		 NODETYPE int    
	   )
   end
   
   if @nodeKey <= 0 begin return end
        
   --   CASE_KEY Lock Info
   if @fldName = 'CASE_KEY'
   begin
	-- try to get the rport key (@pk1) and rport node type (@pk3) for the case_key = @nodeKey
        execute absp_FindNodeParent @pk1 output, @pk3 output, @nodeKey,10 		
        if @pk1 > 0 and @pk3 = 3  -- if rport-program 
        begin
		-- get the program key (@pk2) and program node type (@pk3) for the case_key = @nodeKey
		execute absp_FindNodeParent @pk2 output, @pk3 output, @nodeKey,10,0,1
        end
        else
        begin -- it may be a reinsurance account node
       	        execute absp_FindNodeParent @pk1 output, @pk3 output, @nodeKey,30  
                execute absp_FindNodeParent @pk2 output, @pk3 output, @nodeKey,30,0,1 
        end 
        if @pk1 > 0 and @pk2 > 0 and (@pk3 = 7 or @pk3 = 27)
        begin
		-- add the locking information for this program or reinsurance account
		set @execStr = 'insert into #LOCKINFO values( ' + rtrim(ltrim(str(@pk1))) + ',' + rtrim(ltrim(str(@pk2)))+',0,'+rtrim(ltrim(str(@pk3)))+')'
                --print @execStr
		exec absp_Util_LogIt @execStr ,1 ,'absp_AddLockInfo' , @tempPath 
		insert into #LOCKINFO values(@pk1,@pk2,0,@pk3)
		--execute(@execStr)
        end

   end
   
   -- PROG_KEY Lock Info
   else if @fldName = 'PROG_KEY' 
   begin
	 
	exec @pk3 = absp_Util_GetProgramType @nodeKey
	if @pk3 = 7 or @pk3 = 27
	begin    
		-- get the rport key (@pk1) and rport node type (@pk2) for the prog_key = @nodeKey
		execute absp_FindNodeParent @pk1 output, @pk2 output,@nodeKey,@pk3  
		--print '@pk1 = ' + rtrim(ltrim(str(@pk1))) + ', @pk2 = ' + rtrim(ltrim(str(@pk2)))
		-- it is a program or reinsurance account, add the locking information for this reinsurance account
		if @pk1 > 0 and (@pk2 = 3 or @pk2 = 23)
		begin
			set @execStr = 'insert into #LOCKINFO values( '+ rtrim(ltrim(str(@pk1))) + ','+ rtrim(ltrim(str(@nodeKey)))+',0,'+rtrim(ltrim(str(@pk3)))+ ')'           
			--print @execStr
			exec absp_Util_LogIt @execStr ,1 ,'absp_AddLockInfo' , @tempPath
			insert into #LOCKINFO values(@pk1,@nodeKey,0,@pk3)
			--execute(@execStr)
		end
	end

   end
   
   -- PPORT_KEY Lock Info
   else	if @fldName = 'PPORT_KEY'
   begin
	if @tblName <> 'PREFPOF'
	begin
		-- add the locking information for this Pportfolio
		set @execStr = 'insert into #LOCKINFO values( ' + rtrim(ltrim(str(@nodeKey))) + ',0,0,2)'
		--print @execStr
		exec absp_Util_LogIt @execStr ,1 ,'absp_AddLockInfo' , @tempPath
		insert into #LOCKINFO values(@nodeKey,0,0,2)
		--execute(@execStr)
	end
   end
   -- RPORT_KEY Lock Info
   else	if @fldName = 'RPORT_KEY'
   begin
	exec @pk3 = absp_Util_GetRPortType @nodeKey
	if @pk3 =3 or @pk3 = 23
	begin   
 		-- add the locking information for this Rportfolio or 
		set @execStr = 'insert into #LOCKINFO values( ' + rtrim(ltrim(str(@nodeKey))) + ',0,0,'+ rtrim(ltrim(str(@pk3))) + ')'
		--print @execStr
		exec absp_Util_LogIt @execStr ,1 ,'absp_AddLockInfo' , @tempPath
		insert into #LOCKINFO values(@nodeKey,0,0,@pk3)
		--execute(@execStr)
	end
   end
   
   -- APORT_KEY Lock Info
   else	if @fldName = 'APORT_KEY'
   begin
	-- add the locking information for this Aportfolio
	set @execStr = 'insert into #LOCKINFO values( ' + rtrim(ltrim(str(@nodeKey))) + ',0,0,1)'
	--print @execStr
	exec absp_Util_LogIt @execStr ,1 ,'absp_AddLockInfo' , @tempPath
	insert into #LOCKINFO values(@nodeKey,0,0,1)
	--execute(@execStr)
   end


end