if exists(select * from sysobjects where id = object_id(N'absp_QA_VerifyLocator') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_VerifyLocator
end

go

--message now(), ' Load absp_QA_VerifyLocator';
-------------------------------------------------------
create procedure absp_QA_VerifyLocator @theCountryId  char(3), @theChasKey int, @thePath  char(255) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=====================================================================================================================
DB Version:     SQL2005
Purpose:	This procedure compares locators/policyid in CHASDATA with WCCCODES using given chasKey and countryId 
		of Chasdata and invalid locators and mismatched policyId are written to comma-delimited .txt file 
		using given path. 

Returns:        Nothing

=====================================================================================================================

</pre>
</font>

##BD_END

##PD    @theCountryId  ^^ The CountryID
##PD    @theChasKey  ^^ The cahskey of CHASDATA
##PD    @thePath  ^^ Path where the Runtime Statistics .csv file will be written
*/
as
begin

    -- This procedure compares locators/policyid in CHASDATA with WCCCODES
	-- Illegal locators and mismatched policyid are output to comma-delimited TXT files

    declare @len    int
    declare @pos    int
    declare @head   int
    declare @tail   int
    declare @ch     char(2)
    declare @debug  int
    declare @myList varchar(MAX)
    declare @fileHdr varchar(MAX)
    declare @fileData varchar(MAX)
    declare @fileName varchar(MAX)
    declare @mode   int
    declare @filepath char(255)
    declare @me  varchar(MAX)
    declare @msg varchar(MAX)
    declare @sql varchar(7999);			-- so will not be replaced by MAX
    declare @padding char(5)

	declare @tempHeader varchar(100)


	set @me = 'absp_QA_VerifyLocator';
    exec absp_Util_Replace_Slash @filepath out, @thePath

	-- make exception for GBR
	if (@theCountryId = 'GBR') 
		set @padding = '-'
	else
		set @padding = '-0'

    exec absp_Util_Log_Info '-------- Begin --------', @me

	if exists (select 1 from CHASDATA where COUNTRY_ID = @theCountryId and CHAS_KEY = @theChasKey) 
	begin

		-- create header record table
		exec absp_Util_MakeCustomTmpTable 
           @tempHeader output, 
           'tempHeader', 
           'CHAS_LOCATOR char(30), WCC_LOCATOR char(30), VALUE char(30), LATITUDE char(30), LONGITUDE char(30), CHAS_POLICYID char(30), LEFT7_CHAS_POLICYID char(30),WCC_POLICYID char(30),MAPI_STAT char(30)' 
		print @tempHeader
	
		-- add header record
		exec('insert into '+@tempHeader +' values (''CHASDLL_RETURNED_LOCATOR'',''WCCCODES_LOCATOR'',''CHASDATA_VALUE'',''CHASDLL_RETURNED_LATITUDE'',''CHASDLL_RETURNED_LONGITUDE'',''COMPLETE_CHASDATA_POLICYID'',''LEFT7_OF_CHASDATA_POLICYID'',''WCCCODES_CRESTA_ZONE'',''CHASDLL_RETURNED_MAPI_STAT'')')

		set @fileHdr = ltrim(rtrim(@filepath)) + '\\file.hdr'
		set @sql = 'select * from eqe.dbo.' + ltrim(rtrim(@tempHeader)) 
		exec absp_Util_UnloadData 'q',@sql, @fileHdr ,','

		-- create work table
		select c.LOCATOR as C_LOCATOR, ltrim(rtrim(w.LOCATOR)) as W_LOCATOR,
			   c.VALUE, c.LATITUDE, c.LONGITUDE,c.POLICYID as C_FULL_POLICYID,
		           left(c.POLICYID, 7) as C_POLICYID, ltrim(rtrim(w.COUNTRY_ID)) + ltrim(rtrim(@padding)) + ltrim(rtrim(w.STATE_2)) as W_POLICYID, c.MAPI_STAT
			   into #tmp_1
			   from CHASDATA c left outer join WCCCODES w
			   on c.LOCATOR = w.LOCATOR
			   where c.CHAS_KEY = @theChasKey
			     and c.COUNTRY_ID = @theCountryId


		-- check for illegal LOCATORs
		if exists (select 1 from #tmp_1 where W_LOCATOR is NULL) 
		begin

			if (@thePath <> '') 
			begin

				-- create temp table
				select c.LOCATOR as C_LOCATOR, w.LOCATOR as W_LOCATOR,
					   c.VALUE, c.LATITUDE, c.LONGITUDE,c.POLICYID as C_FULL_POLICYID,
					   left(c.POLICYID, 7) as C_POLICYID, w.COUNTRY_ID + @padding + w.STATE_2 as W_POLICYID, c.MAPI_STAT
					   into tmp_2
					   from CHASDATA c left outer join WCCCODES w
					   on c.LOCATOR = w.LOCATOR
					   where 1 = 2


				-- add header record
				set @fileName = ltrim(rtrim(@filepath)) + '\\' + upper(@theCountryId) + '_BAD_LOCATOR'
				set @fileData = ltrim(rtrim(@fileName)) + '.dat'
				set @fileName = ltrim(rtrim(@fileName)) + '.txt'

				-- add illegal locators
				insert into tmp_2 select * from #tmp_1 where W_LOCATOR is NULL;


				set @sql = 'select * from eqe.dbo.tmp_2'
				exec absp_Util_UnloadData 'q',@sql, @fileData ,','
				drop table tmp_2
			
				set @sql = 'copy /b "' + ltrim(rtrim(@fileHdr)) + '" + "' + ltrim(rtrim(@fileData)) + '"  "' + @fileName + '"'
			    exec master.dbo.xp_cmdshell @sql
				set @sql = 'del /f "' + ltrim(rtrim(@fileData)) + '"' 
			    exec master.dbo.xp_cmdshell @sql

			end 

		end 

		-- check for mismatch POLICYIDs
		
		if exists (select 1 from #tmp_1 where C_POLICYID <> W_POLICYID) 
		begin

			if (@thePath <> '') 
			begin

				-- create temp table
				select c.LOCATOR as C_LOCATOR, w.LOCATOR as W_LOCATOR,
					   c.VALUE, c.LATITUDE, c.LONGITUDE,c.POLICYID as C_FULL_POLICYID,
					   left(c.POLICYID, 7) as C_POLICYID, ltrim(rtrim(w.COUNTRY_ID)) + ltrim(rtrim(@padding)) + ltrim(rtrim(w.STATE_2)) as W_POLICYID, c.MAPI_STAT
					   into tmp_3
					   from CHASDATA c left outer join WCCCODES w
					   on c.LOCATOR = w.LOCATOR
					   where 1 = 2


				-- add header record
				set @fileName = ltrim(rtrim(@filepath)) + '\\' + upper(@theCountryId) + '_BAD'
				set @fileData = ltrim(rtrim(@fileName)) + '.dat'
				set @fileName = ltrim(rtrim(@fileName)) + '.txt'

				-- add mismatch POLICYIDs
				insert into tmp_3 select * from #tmp_1 where C_POLICYID <> W_POLICYID


				set @sql = 'select * from eqe.dbo.tmp_3 '
				exec absp_Util_UnloadData 'q',@sql, @fileData ,','
				drop table tmp_3
				
				set @sql = 'copy /b "' + @fileHdr + '" + "' + @fileData + '"  "' + @fileName + '"'
			    exec master.dbo.xp_cmdshell @sql
				set @sql = 'del /f "' + @fileData + '"'
			    exec master.dbo.xp_cmdshell @sql

			end 
		end
		else
		begin

			-- add header record
			set @fileName = ltrim(rtrim(@filepath)) + '\\' + upper(@theCountryId) + '_GOOD'
			set @fileName = ltrim(rtrim(@fileName)) + '.txt'

			-- add mismatch POLICYIDs
			select 'No mismatches found!' as msg into tmp_3 --from dummy

			set @sql = 'select * from eqe.dbo.tmp_3 '
			exec absp_Util_UnloadData 'q',@sql, @fileName ,','
			drop table tmp_3

		end 

		exec('drop table '+ @tempHeader)

	    exec absp_Util_DeleteFile @fileHdr
		end

	else
	begin

		set @msg = 'No records found for COUNTRY_ID = ' + cast(@theCountryId as char) +
		                            ', and CHAS_KEY = ' + cast(@theChasKey as char) +
									' in CHASDATA';
	    exec absp_Util_Log_Info @msg, @me

	end 

    exec absp_Util_Log_Info '-------- End --------', @me

end
