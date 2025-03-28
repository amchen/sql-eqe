if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_GetResultTablesCount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_GetResultTablesCount
end
go

create procedure absp_QA_GetResultTablesCount @tableType char(1), @writeToFile integer = 0, @filePath char(256) = 'C:\\tmp'
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure write the record count of certain tables to a file or Store in a temp 
               table based on the parameter writeToFile 

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @tableType    ^^ The tableType is used determine the type of table.
##PD  @writeToFile  ^^ The flag for which record count stores on file or not.
##PD  @filePath      ^^ The specified filepath to create file.

*/
as
begin
	declare @tmpTable varchar(120)
	declare @FinalTableNames varchar (max)
	declare @InterTableNames varchar (max)
	declare @DoneTableNames varchar (max)
	declare @indx int
	declare @prevIndx int
	declare @tableName char(120)
	declare @count char(20)
	declare @sql nvarchar(4000)
	declare @dbname nvarchar(128) 
	declare @fileName varchar(256)
	declare @sqlCount nvarchar(4000) 
	
	
	set @dbname = db_name()
	set @indx=0
	set @prevIndx=0
	set @tableName=''
    exec absp_Util_MakeCustomTmpTable 
           @tmpTable output, 
           'TMPRESULTCOUNT', 
           'tableName char (120), count char (20)' 
	set @FinalTableNames='ResAPortAEP|ResAPortAEPTVaR|ResAPortOEP|ResAPortOEPTVaR|ResAPortByPortfolio|ResAPortByCountry|ResAPortByRegion|ResAPortByTreaty|ResAPortByLayer|ResAPortByReinsurer|ResAPortReinstByTreaty|ResAPortReinstByLayer|ResAPortReinstByReinsurer|ResAPortLFSByIntensity|ResRPortAEP|ResRPortAEPTVaR|';
	set @FinalTableNames=@FinalTableNames+'ResRPortOEP|ResRPortOEPTVaR|ResRPortByProgram|ResRPortByDivision|ResRPortByProducer|ResRPortByCountry|ResRPortByRegion|';
	set @FinalTableNames=@FinalTableNames+'ResRTrtyAEP|ResRTrtyOEP|ResRTrtyByTreaty|ResRTrtyByReinstatement|ResRTrtyByRegion|ResRPortLFSByIntensity|ResPPortAEP|ResPPortOEPTVaR|ResPPortAEPTVaR|ResPPortOEP|ResPPortByAccount|ResPPortByPolicy|ResPPortByDivision|ResPPortByBranch|';
	set @FinalTableNames=@FinalTableNames+'ResPPortByLoB|ResPPortByProducer|ResPPortByCompany|ResPPortByCountry|ResPPortByRegion|ResPPortBySubRegion|ResPPortByPostCode|ResPPortByCustomRegion|ResPAccAEP|ResPAccOEP|ResPAccByCoverage|ResPAccBySubRegion|';
	set @FinalTableNames=@FinalTableNames+'ResPAccBySite|ResRAccAEP|ResRAccOEP|ResPStrByCoverage|ResPStrWBU|ResPPortLFSByIntensity|WCEBEOUT|WCEXCEED|PREFPOF|';
	set @InterTableNames='EVENTRES|EVTREST|PEVENT|RTROINTR|RTROINTRD|RTROINTRF|RTRONET|RTRONETX|RTROREC|RTRORECX|';
	set @InterTableNames=@InterTableNames+'RTRORES|RTRORESA|RTRORESD|DMGRES|EXPRES|LIMITRES|SP_FILES|PROGRS_A|PROGRS_P|EXPPOL|LIMITPOL|';
	set @InterTableNames=@InterTableNames+'PDAMAGE|PLIMIT|PFACREC|INTDAMAGE|CHASPTF|';
	set @doneTableNames='';
	DBCC UPDATEUSAGE (@dbname) WITH NO_INFOMSGS;
	
	if @tableType = 'A' or @tableType = 'F' 
	begin		    
		select @indx= charindex('|',@FinalTableNames,@indx) 				
		while(@indx > 0) 
		begin
			select @indx= charindex('|',@FinalTableNames,@indx)
			if(@indx = 0) 
			begin
				set @tableName='';
				set @prevIndx=0;
				set @indx=0;
				break
			end		
			select @tableName=substring(@FinalTableNames,@prevIndx+1,(@indx-@prevIndx)-1)
			print 'Table Name '+@tableName ;
			select @count= rowcnt 
							from	sysindexes, sysobjects 
							where	sysindexes.id = sysobjects.id 
							and		sysobjects.xtype = 'U' 
							and		sysindexes.indid in (0,1)
							and		sysobjects.name = @tableName; 
			
			print 'insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(@count))+')' ;
			set @sql='insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(str(@count)))+')';			
			execute(@sql);		
			set @prevIndx=@indx;
			set @indx=@indx+1;
			set @tableName=''
		end		
	end
	if @tableType = 'A' or @tableType = 'D' 
	begin		     
		select @indx= charindex('|',@doneTableNames,@indx) 
		while(@indx > 0) 
		begin
			select @indx= charindex('|',@doneTableNames,@indx) 
			if(@indx = 0)
			begin
				set @tableName='';
				set @prevIndx=0;
				set @indx=0;
				break;
			end;
			select @tableName=SUBSTRING(@doneTableNames,@prevIndx+1,(@indx-@prevIndx)-1);
			print 'Table Name '+@tableName ;
			select @count= rowcnt 
							from	sysindexes, sysobjects 
							where	sysindexes.id = sysobjects.id 
							and		sysobjects.xtype = 'U' 
							and		sysindexes.indid in (0,1)
							and		sysobjects.name = @tableName; 
		
			print 'insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(@count))+')';
			set @sql='insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(str(@count)))+')';		
			execute(@sql);
			set @prevIndx=@indx;
			set @indx=@indx+1;
			set @tableName=''
		end
	end	
	if @tableType = 'A' or @tableType = 'I' 
	begin		    
		select @indx= charindex('|',@InterTableNames,@indx) 
		while(@indx > 0) 
		begin
			select @indx= charindex('|',@InterTableNames,@indx) 
			if(@indx = 0) 
			begin
				set @tableName='';
				set @prevIndx=0;
				set @indx=0;
				break;
			end;
			select @tableName = SUBSTRING(@InterTableNames,@prevIndx+1,(@indx-@prevIndx)-1);
			print 'Table Name '+@tableName;
			select @count= rowcnt 
						from	sysindexes, sysobjects 
						where	sysindexes.id = sysobjects.id 
						and		sysobjects.xtype = 'U' 
						and		sysindexes.indid in (0,1)
						and		sysobjects.name = @tableName; 

			print 'insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(@count))+')';
			set @sql='insert into '+rtrim(ltrim(@tmpTable))+' values ('''+rtrim(ltrim(@tableName))+''', '+rtrim(ltrim(str(@count)))+')';
			execute(@sql);
			set @prevIndx=@indx;
			set @indx=@indx+1;
			set @tableName=''
		end;
	end;	
	if(@writeToFile = 1) 
	begin
		set @fileName = rtrim(@filePath) + '\\ResultTablesRowCount.txt';

		exec absp_Util_UnloadData
                    @unloadType='T',
                    @unloadText=@tmpTable,
                    @outFile=@fileName,
					@delimiter='='  
	end
	else if	(@writeToFile = 0) 
		execute('select * from '+ @tmpTable +' ') 
		
	set @sql ='drop table '+rtrim(ltrim(@tmpTable))
	execute (@sql)
end