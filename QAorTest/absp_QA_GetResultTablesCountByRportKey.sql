if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_GetResultTablesCountByRportKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_GetResultTablesCountByRportKey
end
go

--message now(), ' Load absp_QA_GetResultTablesCountByRportKey' 
-------------------------------------------------------
create procedure absp_QA_GetResultTablesCountByRportKey @rportKey int,@writeToFile int = 0,@filePath char (256) = 'C:'
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console " >
====================================================================================================
DB Version: SQL2005
Purpose:    This procedure writes the record count of result tables to a file or outputs a
            resultset to the client for a specific RPORT_KEY.
Returns:    Nothing
====================================================================================================
</pre>
</font>
##BD_END
##PD  @rportKey     ^^ The RPORT_KEY is used determine the type of table.
##PD  @writeToFile  ^^ The flag for which record count stores on file or not.
##PD  @filePath     ^^ The specified filepath to create file.
*/
as
begin

    declare @indx int 
    declare @prevIndx int 
    declare @InterTableNames varchar(max)
    declare @tableName char (120)
    declare @count int
    declare @progKeyInList varchar(max)
    declare @me varchar(1000)
    declare @sql varchar(max)
    declare @tmpTable char(120)
    declare @tableType char(1)
    declare @msg varchar(100)

	set @me = 'absp_QA_GetResultTablesCountByRportKey'
    set @indx = 0 
    set @prevIndx = 0 
    set @tableName = '' 

    exec absp_Util_Log_Info 'Start', @me

    -- create a temp table and drop it later.
    --create table TMPRESULTCOUNT (TABLENAME char (20), PROG_KEY int, COUNT char (20))
    exec absp_Util_MakeCustomTmpTable 
           @tmpTable output, 
           'TMPRESULTCOUNT', 
           'TABLENAME char (20), PROG_KEY int, COUNT char (20)' 
	
    -- Set the list of Intermediate tables. To be replaced later when we change the DICTCOL table structure.
    set @InterTableNames = 'DMGRES|DMBRESB|EVENTRES|EVENTRESCC|EVENTRESLC|EVTCEDGS|EVTREST|EXPPOL|EXPRES|EXPRESB|LIMITPOL|LIMITRES|LIMTRESB|TRTYREC|'
	
	-- create list of prog_keys for the specific rport_key
	set @sql = 'select CHILD_KEY from RPORTMAP where RPORT_KEY=' + cast(@rportKey as char) + ' and CHILD_TYPE=7';
    exec absp_Util_Log_Info @sql, @me
    exec absp_Util_GenInListString @progKeyInList output, @sql, 'N'
   
    -- Parse the Intermediate Result Tables String and get the count for each table
    select @indx= charindex('|',@InterTableNames,@indx) 
	while(@indx > 0) 
	begin
		select @indx= charindex('|',@InterTableNames,@indx) 
		if(@indx = 0) 
		begin
			set @tableName=''
			set @prevIndx=0
			set @indx=0
			break
		end
		select @tableName = SUBSTRING(@InterTableNames,@prevIndx+1,(@indx-@prevIndx)-1)
		set @msg = 'Table Name ' + @tableName
		exec absp_Util_Log_Info @msg, @me
		
		set @sql = 'if exists (select 1 from SYSOBJECTS where NAME = ''' + ltrim(rtrim(@tableName)) + ''')  ' +
                       'insert into '+ @tmpTable +' (TABLENAME, PROG_KEY, COUNT) select ''' + ltrim(rtrim(@tableName)) + ''', PROG_KEY, count(*) from ' +
                                                                                              ltrim(rtrim(@tableName)) + ' where PROG_KEY in (' +
                                                                                              @progKeyInList + ') group by PROG_KEY order by PROG_KEY' 
                       
                  
        exec absp_Util_Log_Info @sql, @me
        execute(@sql)
		set @prevIndx=@indx;
		set @indx=@indx+1;
		set @tableName=''
	end

 

    if (@writeToFile = 1) 
    begin

        print 'Unload table #TMPRESULTCOUNT to "' +  ltrim(rtrim(@filePath)) + '\ResultTablesCountByRportKey.txt" delimited by "|" QUOTES OFF' 
        set @filePath = ltrim(rtrim(@filePath)) + '\ResultTablesCountByRportKey.txt'
        exec absp_Util_UnloadData
                    @unloadType='t',
                    @unloadText=@tmpTable,
                    @outFile=@filePath ,
                    @delimiter = '|' 
	end
    else if (@writeToFile = 0) 
       execute('select * from '+ @tmpTable +' order by TABLENAME, PROG_KEY') 
	
	set @sql ='drop table '+rtrim(ltrim(@tmpTable))
	execute (@sql)
	exec absp_Util_Log_Info 'Completed', @me
end 
