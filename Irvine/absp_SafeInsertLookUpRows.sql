if exists(select * from SYSOBJECTS where ID = object_id(N'absp_SafeInsertLookUpRows') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_SafeInsertLookUpRows
end
go
create procedure absp_SafeInsertLookUpRows @autoKey int, @lkupTbl varchar(120),@newId int, @eqeCol varchar(120),@targetDB varchar(130),@noInsert int, @countryId char(3)
as
begin
	declare @fieldValueTrios varchar(4000)
	declare @replNames varchar(max)
	declare @fieldNames varchar(max)
	declare @tabSep char(2)
	declare @debug int
	declare @sSql nvarchar(max)
	declare @tmpTbl varchar(140)
	declare @oldEqeId int 
	set @debug=0
	
	begin try
 		--Insert record
		execute absp_DataDictGetFields @fieldNames output, @lkupTbl  , 0   
		execute  absp_GenericTableCloneSeparator @tabSep output
		 
		set @fieldValueTrios = 'str'+@tabSep+ @eqeCol+@tabSep+dbo.trim(cast(@newId as varchar))		
		set @fieldValueTrios = @fieldValueTrios + @tabSep +	'str' + @tabSep + 'DFLT_ROW' + @tabSep + 'N'
		execute absp_StringSetFields @replNames output, @fieldNames, @fieldValueTrios	
		if @debug=1
			exec absp_MessageEx @replNames
		
		if @noInsert=0
		begin
 
			set @sSql = ' insert into '+ dbo.trim(@targetDB) + '..'+   dbo.trim(@lkupTbl) +' ( '+@fieldNames+' )'+' 
			select  '+@replNames+' from TMP_MISMATCHED_LOOKUPS where  AUTOKEY = ' + cast(@autoKey as varchar)
		 
			if @debug=1
				exec absp_MessageEx @sSql
	        	execute (@sSql)
	    	end
		
		--Insert old and new keys--
		set @tmpTbl ='TMP_' + dbo.trim(@lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))
  	
		--Get oldId 
		set @sSql ='select @oldEqeId=' + @eqeCol + ' from TMP_MISMATCHED_LOOKUPS  where AUTOKEY=' + cast(@autoKey as varchar)
 
		if @debug=1
			execute absp_messageEx @sSql
		execute sp_executesql @sSql, N'@oldEqeId int output',@oldEqeId output
 
			
		set @sSql= 'insert into '+@tmpTbl   + ' values( '''+@countryId +''','+ cast(@oldEqeId as varchar) + ',' + CAST(@newID as varchar) + ')'
		if @debug=1
			execute absp_messageEx @sSql 
		execute (@sSql)
		
		return 0
	end try
	begin catch
		return -1
	end catch
end
