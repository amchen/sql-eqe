if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CrolInfoClone') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_CrolInfoClone;
end
go

create procedure absp_CrolInfoClone @oldCaseLayrKey int, @newCaseKey int, @targetDB varchar(130)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure clones the CROLINFO record for the given CASE LAYER if it does not already exist
               in the target database and updates the references.

Returns:       Nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  targetDB^^  The database where the data is cloned.

*/
as
begin

	set nocount on;

	declare @sSql nvarchar(max)
	declare @oldCalcrId int
	declare @newCalcrId int
	declare @longName varchar(255)
	declare @newName varchar(120)
	declare @where varchar(255)
	declare @substitutions varchar(255)
	declare @tabSep char(2)
	declare @debug int
	declare @fieldNames varchar(max)
	declare @insertStr varchar(max)

	set @debug=1

	if @targetDB=''
		return

	--Enclose within square brackets--
	execute absp_getDBName @targetDB out, @targetDB

	if substring(@targetDB,2,len(@targetdb)-2)=DB_NAME()
		return

	execute  absp_GenericTableCloneSeparator @tabSep output

	--Get the CALD_ID for the CASELAYR_KEY--
	select @oldCalcrId = CALCR_ID from CASELAYR where CSLAYR_KEY=@oldCaseLayrKey

	--Check if the crol record exists in target database
	set @newCalcrId = -1
	set @sSql = 'select top (1) @newCalcrId =  T_NEW.CALCR_ID from CROLINFO as T_OLD,' + dbo.trim(@targetDB) + '..CROLINFO as T_NEW
				 where T_OLD.FACTOR1 = T_NEW.FACTOR1
				 and T_OLD.FACTOR2 = T_NEW.FACTOR2
				 and T_OLD.FACTOR3 = T_NEW.FACTOR3
				 and T_OLD.FACTOR4 = T_NEW.FACTOR4
				 and T_OLD.SAMP_LOSS = T_NEW.SAMP_LOSS
				 and T_OLD.SAMP_SIGMA = T_NEW.SAMP_SIGMA
				 and T_OLD.SAMP_LIMIT = T_NEW.SAMP_LIMIT
				 and T_OLD.CALCR_ID = ' + dbo.trim(str(@oldCalcrId))
	if @debug = 1
		execute absp_messageEx @sSql
	execute sp_executesql @sSql,N'@newCalcrId int output',@newCalcrId output

	--If no matching record found clone CROL record--
	if @newCalcrId =-1
	begin
	 		--lookup does not exist
	 		-- determine the new LONGNAME
			set @sSql = 'select @longName = LONGNAME from CROLINFO where CALCR_ID = '+ dbo.trim((str(@oldCalcrId)))
			if @debug = 1
				execute absp_MessageEx  @sSql
			execute sp_executesql @sSql,N'@longName char(255) output',@longName output

			set @longName = case when @longName IS NULL then 'rate on line' else @longName	end

			set @sSql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''CROLINFO'',''LONGNAME'''
			execute sp_executesql @sSql,N'@newName char(120) output',@newName output


			-- determine the new CALCR_ID
			set @sSql = 'select  @newCalcrId = MAX(CALCR_ID)+1  from ' + dbo.trim(@targetDB) + '..CROLINFO'
			execute sp_executesql @sSql,N'@newCalcrId int output',@newCalcrId output

			-- copy into a new one with the new unique name and new CALCR_ID
			set @where = 'CALCR_ID = '+cast(@oldCalcrId as char)
			set @substitutions = 'INT' + @tabSep + 'CALCR_ID' + @tabSep + str(@newCalcrId)
			set @substitutions = @substitutions + @tabSep + 'STR' + @tabSep + 'LONGNAME' + @tabSep + @newName
			set @substitutions = @substitutions + @tabSep + 'STR' + @tabSep + 'DFLT_CROL' + @tabSep + 'N'
			execute absp_GenericTableCloneRecords 'CROLINFO',0,@where,@substitutions,0,@targetDB

	end

	-- update all the references to the @oldCalcrId with the @newCalcrId
	set @sSql='begin transaction; update ' + dbo.trim(@targetDB) + ' ..CASELAYR
		  set CALCR_ID = ' + dbo.trim(str(@newCalcrId)) +
		 ' where CALCR_ID= '+ dbo.trim(str(@oldCalcrId)) + ' and CASE_KEY = ' + dbo.trim(str(@newCaseKey))+'; commit transaction; '
	if @debug = 1
		execute absp_messageEx @sSql
	execute(@sSql)

end
