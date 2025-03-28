if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DumpLookupTables') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_DumpLookupTables
end
go
create procedure absp_DumpLookupTables  @outputPath varchar(500), @userName	varchar(100) = '',@password	varchar(100) = ''

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL

Purpose:	   This procedure dumps lookup table data and the system lookup data in the given paths.

Returns: 	   Nothing

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @outputPath ^^ The path to dump lookup table data
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication

*/
as
begin

	set nocount on
    
	/*
		SDG__00026174  -- Need to write a stored procedure to dump all of our system level lookups in a known table and sort order 
	*/
	
	declare @tableName varchar(100)
	declare @query varchar(2000)
	declare @filePath varchar(1000)	
	declare @msgText varchar(500)
	
	--Create a temporary table to hold the queries to get system lookup data--
	
	create table #TMP_QRYTBL (TABLENAME varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS, QUERY varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS)
	
	insert into #TMP_QRYTBL values('CIL','select * from CIL where TRANS_ID in (57,58, 59, 10000) order by cover_id')
	insert into #TMP_QRYTBL values('DTL','select * from dtl where TRANS_ID in (57,58, 59, 10000) order by deduct_id')
	insert into #TMP_QRYTBL values('EOTDL','select * from eotdl where TRANS_ID in (57,58, 59, 10000) order by country_id, e_occpy_id')
	insert into #TMP_QRYTBL values('ESDL','select * from esdl where TRANS_ID in (57,58, 59, 10000) order by country_id, str_eq_id')
	--insert into #TMP_QRYTBL values('ESTRCMOD','select * from ESTRCMOD where TRANS_ID in (57,58, 59, 10000) order by country_id, estrmod_id')
	insert into #TMP_QRYTBL values('FOTDL','select * from fotdl where TRANS_ID in (57,58, 59, 10000) order by country_id, f_occpy_id')
	insert into #TMP_QRYTBL values('FSDL','select * from fsdl where TRANS_ID in (57,58, 59, 10000) order by country_id, str_fd_id')
	insert into #TMP_QRYTBL values('LTL','select * from ltl where TRANS_ID in (57,58, 59, 10000) order by limit_id')
	insert into #TMP_QRYTBL values('PTL','select * from ptl where TRANS_ID in (57,58, 59, 10000) order by peril_key')
	insert into #TMP_QRYTBL values('RLOBL','select * from RLOBL where TRANS_ID in (57,58, 59, 10000) order by country_id, r_lob_id')
	insert into #TMP_QRYTBL values('SHIFTL','select * from SHIFTL where TRANS_ID in (57,58, 59, 10000) order by shift_id')
	insert into #TMP_QRYTBL values('TORL','select * from torl order by r_type_id')
	insert into #TMP_QRYTBL values('WOTDL','select * from wotdl where TRANS_ID in (57,58, 59, 10000) order by country_id, w_occpy_id')
	insert into #TMP_QRYTBL values('WSDL','select * from wsdl where TRANS_ID in (57,58, 59, 10000) order by country_id, str_ws_id')
	--insert into #TMP_QRYTBL values('WSTRCMOD','select * from WSTRCMOD where TRANS_ID in (57,58, 59, 10000) order by country_id, wstrmod_id')
	 
	
	--Dump Lookup table data --	
	declare curs1 cursor fast_forward for
		select TABLENAME from DICTTBLX where TYPE = ''  and TABLENAME not in ('STATEL', 'TIL') order by TABLENAME asc

		open curs1
		fetch next from curs1 into @tableName

		while @@fetch_status = 0
		begin 
            
			--Dump all rows--
			set @msgText='Dumping '+ @tableName + ' data'
			execute absp_MessageEx @msgText

			--Dump system lookups--
			set @msgText='Dumping '+ @tableName + ' system data'
			execute absp_MessageEx @msgText

			set @query = ''
			select @query= QUERY from #TMP_QRYTBL where TABLENAME = @tableName
			if @query <>''
			begin
			set @filePath = @outputPath + '\' + dbo.trim(@tableName) + '.txt'
			execute absp_Util_UnloadData  'Q',@query, @filePath,'|','','','','','',@userName,@password
			end

			fetch next from curs1 into @tableName
		end

		close curs1
		deallocate curs1
end
