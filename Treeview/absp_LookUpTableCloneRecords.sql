if exists(select * from SYSOBJECTS where ID = object_id(N'absp_LookUpTableCloneRecords') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_LookUpTableCloneRecords
end
go
create procedure absp_LookUpTableCloneRecords @lkupTbl varchar(120),@targetDB varchar(130)=''
as
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:       This procedure clones the Lookup Table records in the target database.
 
 Returns:       Nothing.
 
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
 
 ##PD  @lkupTbl ^^  The associated lookup table name
 ##PD  @targetDB ^^  The database where the data is cloned.
  
 */

begin
set nocount on	

	declare @sSql nvarchar(max) 
	declare @newID int
	declare @debug int
	declare @cnt int
	declare @userNameCol varchar(120)
	declare @lkupType char(1)
	declare @eqeCol varchar(120)
	declare @tmpTbl varchar(140)
	declare @tbl varchar(120)
	declare @insertStr varchar(8000)
	declare @lookupCopy varchar(140)
    	declare @oldEqeId int 
	declare @transId int 
	declare @userColVal varchar(120)
	declare @userNmColVal varchar(120)
	declare @countryId char(3)
	declare @insertStatus int
	declare @rule varchar(8000)
	declare @autoKey int
	declare @idVal int
	declare @fieldNames varchar(max)
	declare @lookupRow varchar(8000)
	declare @auditRec varchar(8000)
	declare @keyVal int
	declare @sql nvarchar(max)
	declare @byCountry char(1)
	declare @mappedLkups int
	declare @me varchar (50)
	declare @msg varchar (256)
	set @debug= 0
	set @me = 'absp_LookUpTableCloneRecords'

	set @msg = @me + ' Starting'
	
	set @keyVal=-1
	
	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me
	 
  	set @idVal=''
  	set  @byCountry=''
  	  	 
 	if @lkupTbl='D0410'
		set @eqeCol='TRANS_ID'
	else if @lkupTbl='PTL'
		set @eqeCol='PERIL_KEY'
	else
	begin
		select @eqeCol=EQECOL,@userNameCol=UNAMECOL,@lkupType=TYPE from DICTTBLX where TABLENAME=@lkupTbl
		select @byCountry = CNTRYBASED from DICTLOOK  where TABLENAME=@lkupTbl
	end
    
	set @tmpTbl ='TMP_' + dbo.trim(@lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))
	execute absp_DataDictGetFields @fieldNames output, @lkupTbl  , 0   
	set @fieldNames=' ' + @fieldNames
	
	if dbo.trim(@lkupType) ='' 
		set @mappedLkups=1
		
 	--Handle rules table--
	declare cur0 cursor for select AUTOKEY from TMP_MISMATCHED_LOOKUPS 
	open cur0
	fetch cur0 into @autokey
	while @@fetch_status=0
	begin
	
		set @sSql ='select @oldEqeId=' + @eqeCol + ' from TMP_MISMATCHED_LOOKUPS  where AUTOKEY=' + cast(@autoKey as varchar)
		execute sp_executesql @sSql, N'@oldEqeId int output',@oldEqeId output

		--Get countryId
		if @byCountry='Y'
		begin
				set @sSql ='select @countryId=COUNTRY_ID from TMP_MISMATCHED_LOOKUPS  where AUTOKEY=' + cast(@autoKey as varchar)
				execute sp_executesql @sSql, N'@countryId char(3) output',@countryId output
		end
		set @countryId=isnull(@countryId,'')
			
		
		if @keyVal=-1
		begin
	
			set @newId=-1
			set @idVal=-1
			--Get newId to use later--		
			if  @byCountry='Y'
			begin
				--For country based tables check if we already have the Id for a different country since absp_GetNeId generates a new Id always
				set @sSql='select @idVal=NEW_VAL from '+ @tmpTbl + ' where OLD_VAL = ' + cast(@oldEqeId as varchar)
				execute sp_executesql @sSql, N'@idVal int output',@idVal output 
			end
			
			if  @idVal=-1
			begin
				set @sSql= 'exec @idVal = ' + dbo.trim(@targetDB) + '..absp_Util_GetNewId ''' + @lkupTbl + ''',''' + @eqeCol +''''	
				if @byCountry='Y'
					set @sSql = @sSql + ','''+dbo.Trim(@countryId)+''''			
				if @debug=1
					exec absp_MessageEx @sSql
				execute sp_executesql @sSql, N'@idVal int output',@idVal output 

				--Delete the new lookup entry. Inserted later.
				set @sSql='delete from ' + dbo.trim(@targetDB) + '..' + @lkupTbl  + ' where ' + @eqeCol + '=' + cast(@idVal as varchar)
				if @debug=1
					exec absp_MessageEx @sSql
				execute (@sSql	)
			end
			
			--Implement RULE1 later
			------------------------------------
			set  @insertStatus=-1  ---Do not implement rule 1 now
			
			--Implement Rule 2
			-------------------
			if @insertStatus=-1 
			begin
				set @newId=-1
				select @rule=RULE2 from #TMP_RULE where TABLENAME=@lkupTbl
				if @rule=''
					set @insertStatus=-1 
				else
				begin
					--set @ruleCols=replace(@rule,'T1.','T2.')
					set @sSql = 'select @newId = T1.' + dbo.trim(@eqeCol) + ' from ' + dbo.trim(@targetDB) + '..' + rtrim(@lkupTbl) +
						' T1,TMP_MISMATCHED_LOOKUPS T2  where ' + @rule + ' and T2.AUTOKEY = ' + cast(@autoKey as varchar)
					if @debug=1
						exec absp_MessageEx @sSql
					execute sp_executeSql @sSql,N'@newId int out',@newId out
					
					if (@debug = 1)
						exec absp_MessageEx 'Rule2'
					
					if @newId<>-1 --Exists
						exec @insertStatus = absp_SafeInsertLookUpRows  @autoKey,@lkupTbl, @newId ,@eqeCol,@targetDB,1 ,@countryId
					else
						set @insertStatus=-1 
				end
			end

			--Implement Rule 3
			-------------------
			if @insertStatus=-1 
			begin
			    set @newId=-1
				select @rule=RULE3 from #TMP_RULE where  TABLENAME=@lkupTbl
				if @rule=''
					set @insertStatus=-1 
				else
				begin 
					--set @ruleCols=replace(@rule,'T1.','T2.')
 					set @sSql = 'select @newId = T1.' + dbo.trim(@eqeCol) + ' from ' + dbo.trim(@targetDB) + '..' + rtrim(@lkupTbl) +
							' T1,TMP_MISMATCHED_LOOKUPS T2  where  ' + @rule + ' and T2.AUTOKEY = ' + cast(@autoKey as varchar)
					if @debug=1
						exec absp_MessageEx @sSql
					execute sp_executeSql @sSql,N'@newId int out',@newId out
					
					if (@debug = 1)
						exec absp_MessageEx 'Rule3'
			
 					if @newId<>-1 --Exists
						exec @insertStatus = absp_SafeInsertLookUpRows @autoKey,@lkupTbl, @newId,@eqeCol,@targetDB,1,@countryId
					else
						set @insertStatus=-1 
				 end
			end
			
			--try to insert rule1
			if  @insertStatus=-1 
				exec @insertStatus = absp_SafeInsertLookUpRows  @autoKey,@lkupTbl, @idVal ,@eqeCol,@targetDB,0 ,@countryId

			--Implement Rule 4
			-------------------
			if @insertStatus=-1 
			begin
				select @rule=RULE4 from #TMP_RULE  where  TABLENAME=@lkupTbl
				set @sSql = 'begin transaction; update TMP_MISMATCHED_LOOKUPS set ' + @rule + '=' + dbo.trim(@rule) +'+''_' + dbo.trim(cast(@idVal as varchar))+''''+
				' where AUTOKEY = ' + cast(@autoKey as varchar)+'; commit transaction; '
				if @debug=1
					exec absp_MessageEx @sSql
				exec (@sSql)
				
				if (@debug = 1)
					exec absp_MessageEx 'Rule4'
					
				exec @insertStatus = absp_SafeInsertLookUpRows @autoKey, @lkupTbl,@idVal ,@eqeCol,@targetDB,0,@countryId
			end
		end
		fetch cur0 into @autokey
	end
	close cur0
	deallocate cur0
	
	set @msg = @me + ' Completed'
			
	if (@debug = 1)
		execute absp_Util_Log_Info  @msg, @me

 end