if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PerformResultComparison') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PerformResultComparison
end
 go

create procedure absp_PerformResultComparison	@sessionId int,
												@DBName1 varchar(130),
												@reportID1 int,
												@reportQuery1 varchar(max),
												@summaryRPKey1 int,
												@snapshotKey1 int,
												@DBName2 varchar(130),
												@reportID2 int,
												@reportQuery2 varchar(max),
												@summaryRPKey2 int,
												@snapshotKey2 int,
												@roundUpValues int=0,
												@debug int=0
												

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	The procedure will compare reports from 
		- Two different nodes of the same type
		- Compare same type of reports within the same nodes
		- Compare reports from a Snapshot view
		- Compare reports between comparable report types

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin try
	set nocount on
	declare @comparableColList1 varchar(max);
	declare @comparableColList2 varchar(max);
	declare @colList1 varchar(max);
	declare @colList2 varchar(max);
	declare @sql nvarchar(max);
	declare @tmpTbl1 varchar(50);
	declare @tmpTbl2 varchar(50);
	declare @tmpRDBTbl1 varchar(50);
	declare @tmpRDBTbl2 varchar(50);
	declare @resultsComparisonTable varchar(100);
	declare @joinColumns varchar(max);
	declare @joinStr varchar(max);
	declare @i int;
	declare @j int;
	declare @cnt int;
	declare @rp1 varchar(8000);
	declare @rp2 varchar(8000);
	declare @mainTableName varchar(120);
	declare @mainTableName1 varchar(120);
	declare @joinTblName varchar(120);
	declare @isRDB int;
	declare @schemaName1 varchar(120);
	declare @schemaName2 varchar(120);
	declare @reportName1 varchar(500);
	declare @reportName2 varchar(500);

   --Enclose within square brackets--
   execute absp_getDBName @DBName1 out, @DBName1
   execute absp_getDBName @DBName2 out, @DBName2
   
   --Get schemaName for Snapshot--
	if @snapshotKey1>0
	begin
		set @sql='select @schemaName1 = SchemaName from ' + @DBName1 + '.dbo.snapshotinfo where SnapshotKey=' + cast(@snapshotKey1 as varchar(30));
		exec sp_executesql @sql,N'@schemaName1 varchar(120) out',@schemaName1 out
	end
	else
		set @schemaName1 ='dbo';
    
    if @snapshotKey2>0
	begin
		set @sql='select @schemaName2 = SchemaName from ' + @DBName2 + '.dbo.snapshotinfo where SnapshotKey='+ cast(@snapshotKey2 as varchar(30));
		exec sp_executesql @sql,N'@schemaName2 varchar(120) out',@schemaName2 out
	end
	else
		set @schemaName2 ='dbo';
    
   
   if exists (select 1 from RQEVersion where DBType='RDB') set @isRDB=1 else set @isRDB=0
	
	
	-- If the main table already exists, then drop the table since this table is from the last result comparison.
	set @resultsComparisonTable='FinalResultsComparisonTbl_'+dbo.trim(cast(@sessionId as varchar(30)))
	if exists(select 1 from sys.tables where name=@resultsComparisonTable) 	exec('drop Table ' + @resultsComparisonTable)
	
	
	-- Based on the ReportID get the list of comparable columns for both report 1 and report 2.
	set @comparableColList1=''
	if @isRDB=1
	begin
		--Get MaintableName--
		select @mainTableName=MainTableName from ReportQuery where ReportId=@reportID1;
		--TableName is as ResYLTEAL (YLTSUMMARY)
		select @mainTableName1= dbo.trim(left(@mainTableName,charindex('(',@mainTableName)-1));
		select  @joinTblName=substring(@mainTableName,charindex('(',@mainTableName)+1 ,len(@mainTableName)-(charindex('(',@mainTableName)+1))
		select @comparableColList1=@comparableColList1 +  FieldName +',' from systemdb..DictCol where  IsComparable='Y' and TableName=@mainTableName1;
	end
	else
	begin
		select @comparableColList1=@comparableColList1 +  FieldName +',' from systemdb..DictCol where  IsComparable='Y' and TableName in (select MainTableName from ReportQuery where ReportId=@reportID1);
	end
	
	set @comparableColList1=left(@comparableColList1,len(@comparableColList1)-1)
		
	----------------------
	--Handle summary rp in case of summary reports only--
	--Get the RPs that match--
	select @reportName1=reportDisplayName from reportQuery where reportID=@reportID1

	if @summaryRPKey1>0 and @reportName1 like ('Summary%')
	begin
		set @rp1=''
		set @rp2=''
		set @i=1
		while 1=1
		begin		
			set @j=1;
			while 1=1
			begin		
				set @sql='select @cnt=count(*) from summaryRp A inner join SummaryRP B on A.ReturnPeriod' + dbo.trim(cast(@i as varchar(30))) + 
						' = B.ReturnPeriod' + dbo.trim(cast(@j as varchar(30))) + 
						' where A.SummaryRPKey=' + dbo.trim(cast(@summaryRPKey1 as varchar(30)))+
						' and B.SummaryRPKey=' + dbo.trim(cast(@summaryRPKey2 as varchar(30))) 
				exec sp_executesql @sql,N'@cnt int out',@cnt out
				if @cnt=1
				begin
				
					set @RP1=@RP1 +  ' Items like ''%[_]RP' + dbo.trim(cast(@i as varchar(30))) + '%'' or '
					set @RP2=@RP2 +  ' Items like ''%[_]RP' + dbo.trim(cast(@j as varchar(30))) + '%'' or '
					break;
				end
				set @j=@j+1;
				if @j=5 break;
			end
			set @i=@i+1;
			if @i=5 break;
		end	
		--remove extra or--
		if @RP1<>'' set @RP1='(' + left(@RP1,len(@RP1)-3) + ')'
		if @RP2<>'' set @RP2='(' + left(@RP2,len(@RP2)-3)+ ')'		
	end

	----------------------
	
	--Create temporary tables--
	set @tmpTbl1='Tmp_Report1_'+dbo.trim(cast(@sessionId as varchar(30)));
	if exists(select 1 from sys.tables where name=@tmpTbl1) 	exec('drop Table ' + @tmpTbl1)

	set @reportQuery1=replace(@reportQuery1,dbo.trim(@schemaName1) +'.',@dbName1+'.' + dbo.trim(@schemaName1) + '.')
	set @sql=replace(@reportQuery1,' from ',' into ' + @tmpTbl1 +' from ' )
		
	--if @debug=1 exec absp_MessageEx @sql;
	print @sql
	exec(@sql);	
	print '--Temp1 created!'
	print ''
	
	if @isRDB=1 --need YltId
	begin
		set @tmpRDBTbl1='TmpRDB1_'+dbo.trim(cast(@sessionId as varchar(30)));
		if exists(select 1 from sys.tables where name=@tmpRDBTbl1) 	exec('drop Table ' + @tmpRDBTbl1)
		
		set @sql=replace(@reportQuery1,' from ',',YltSummary.* from ' )
		set @sql=replace(@sql,' from ',' into ' + @tmpRDBTbl1 +' from ' );

		exec(@sql)

	end

	if @summaryRPKey1>0 and @reportName1 like ('Summary%')
	begin
		--Remove the RP columns which need not be compared--
		set @sql=''
		select @sql= @sql +  sc.Name + ',' from sysobjects so 	join syscolumns sc on sc.id = so.id where so.name = @tmpTbl1 order by sc.ColID
		select * into #Tmp_Cols1 from dbo.Split(@sql,',')

		set @sql='delete from #Tmp_Cols1 where (' + @RP1 + ' or Items not like ''%[_]RP%'')';	
		exec (@sql)
 		set @sql='';
		select @sql=@sql + Items + ',' from #Tmp_Cols1;	
		if len(@sql)>0
		begin
			set @sql='alter table ' + @tmpTbl1 + ' drop column ' + @sql
			set @sql=left(@sql,len(@sql)-1)
			exec (@sql)	
		end			
	end
	
	--create tmp2 from query run on target db--
	set @tmpTbl2='Tmp_Report2_'+dbo.trim(cast(@sessionId as varchar(30)));
	if exists(select 1 from sys.tables where name=@tmpTbl2) 	exec('drop Table ' + @tmpTbl2)
	
	set @reportQuery2=replace(@reportQuery2,dbo.trim(@schemaName2) +'.',@dbName2+'.' + dbo.trim(@schemaName2) + '.')
	set @sql=replace(@reportQuery2,' from ',' into ' + @tmpTbl2  +' from ' )

	--if @debug=1 exec absp_MessageEx @sql;

	exec(@sql);
	print '--Temp2 created!'
	print ''

	
	if @isRDB=1 --need YltId
	begin
		set @tmpRDBTbl2='TmpRDB2_'+dbo.trim(cast(@sessionId as varchar(30)));
		if exists(select 1 from sys.tables where name=@tmpRDBTbl2) 	exec('drop Table ' + @tmpRDBTbl2)
		
		set @sql=replace(@reportQuery2,' from ',',YltSummary.* from ' )
		set @sql=replace(@sql,' from ',' into ' + @tmpRDBTbl2 +' from ' );

		exec(@sql)
		
	end

	select @reportName2=reportDisplayName from reportQuery where reportID=@reportID1

	if @summaryRPKey2>0 and @reportName2 like ('Summary%')
	begin
		--Remove the RP columns which need not be compared--
		set @sql=''
		select @sql= @sql +  sc.Name + ',' from sysobjects so 	join syscolumns sc on sc.id = so.id where so.name = @tmpTbl2 order by sc.ColID
		select * into #Tmp_Cols2 from dbo.Split(@sql,',')
		set @sql='delete from #Tmp_Cols2 where (' + @RP2 + ' or Items not like ''%[_]RP%'')';
		
		exec (@sql)
		set @sql='';
		select @sql=@sql + Items + ',' from #Tmp_Cols2;		
		if len(@sql)>0
		begin 
			set @sql='alter table ' + @tmpTbl2 + ' drop column ' + @sql
			set @sql=left(@sql,len(@sql)-1)
			exec (@sql)	
		end	
	end	
	
	--Create Final results table--
	set @sql='create table ' + @resultsComparisonTable + '( RowNum int IDENTITY(1,1) PRIMARY KEY, ';
	
	--Add columns for first query--
	select @sql = @sql + ' ' + sc.Name + '_A ' + st.Name +
	case when st.Name in ('varchar','varchar','char') then '(' + cast(sc.Length as varchar) + ')' else '' end + ','  
	from sysobjects so
	join syscolumns sc on sc.id = so.id
	join systypes st on st.xusertype = sc.xusertype
	where so.name = @tmpTbl1 
	order by sc.ColID
	
	--Add columns for second query getting the same names as tht of the first--
 	select @sql = @sql + ' ' + sc.Name + '_B ' + st.Name +
	case when st.Name in ('varchar','varchar','char') then '(' + cast(sc.Length as varchar) + ')' else '' end + ','  
	from sysobjects so
	join syscolumns sc on sc.id = so.id
	join systypes st on st.xusertype = sc.xusertype
	where so.name = @tmpTbl2
	order by sc.ColID
	
	--Add derived columns -- get the comparable column list--
	select * into #Tmp_CompCols1 from dbo.Split(@comparableColList1,',');
	--Remove columns from comparable column list which are not in query'
	select sc.name as Items into #Tmp_ColsInQuery 
	from sysobjects so inner join syscolumns sc on sc.id = so.id
						where so.name =  @tmpTbl1 order by sc.ColID	 
	
	--========================================================================================================================
	--0011415: Downloading Summary by Country comparison results to a file is only printing the Header information of ResultComparison_Data.txt
	
	if exists(select 1 from #Tmp_CompCols1 where Items in('Limit' , 'Rol_Limit') )	insert into #Tmp_CompCols1 values('CROL') 
	--========================================================================================================================
						
	delete #Tmp_CompCols1  from #Tmp_CompCols1  where Items not in (select Items from #Tmp_ColsInQuery )

	--Remove columns not needed for SummaryRP--
	if @summaryRPKey1>0 and @reportName1 like ('Summary%')
		delete #Tmp_CompCols1  from #Tmp_CompCols1 T1  inner join #Tmp_Cols1 T2 on T1.Items=T2.Items;
 
        set @JoinStr=''	

	if @roundUpValues=1
	begin
		select @JoinStr=COALESCE(@JoinStr+', ' , '') +Items+'_Pct_Diff as (case when round(IsNull(' + Items + '_A,0),2)=0 and round(IsNull(' + Items + '_B,0),2)<>0 then 
		((round(cast(isNull(' + Items + '_B,0) as float),2)-round(cast(IsNull(' + Items+'_A,0) as float),2))/ round(cast(' + Items+'_B as float),2))*100  
		when round(IsNull(' + Items + '_A,0),2)=0  and round(IsNull(' + Items + '_B,0),2)=0 then 	((round(cast(isNull(' + Items + '_B,0) as float),2)-round(cast(isNull(' + Items+'_A,0) as float),2))/ 1)*100 		 
		when round(IsNull(' + Items + '_A,0),2)<>0  and round(IsNull(' + Items + '_B,0),2)<>0 then 	((round(cast(isNull(' + Items + '_B,0) as float),2) - round(cast(isNull(' + Items+'_A,0) as float),2)) /round(cast(' + Items+'_A as float),2) )   * 100
		else (round(cast(isNull(' + Items + '_B,0) as float),2)-round(cast(isNull(' + Items+'_A,0) as float),2))/ round(cast(' + Items+'_A as float),2)*100 	end),' 
		+ Items+'_Diff as  ((round(cast(IsNull(' + Items+'_B,0) as float),2)-round(cast(IsNull(' + Items+'_A,0) as float),2))) '
		from #Tmp_CompCols1
	set @JoinStr = @JoinStr + ',Has_Diff as (case when ' 
	select @JoinStr=  COALESCE(@JoinStr+'' , '') + '((isNULL(cast(' + Items + '_A as float),0)-isNull(cast(' + Items + '_B as float),0)))=0 and ' 	from #Tmp_CompCols1

	end
	else
	begin
	select @JoinStr=COALESCE(@JoinStr+', ' , '') +Items+'_Pct_Diff as (case when floor(IsNull(' + Items + '_A,0))=0 and floor(IsNull(' + Items + '_B,0))<>0 then 
		((floor(cast(isNull(' + Items + '_B,0) as float))-floor(cast(IsNull(' + Items+'_A,0) as float)))/ floor(cast(' + Items+'_B as float)))*100  
		when floor(IsNull(' + Items + '_A,0))=0  and floor(IsNull(' + Items + '_B,0))=0 then 	floor(((cast(isNull(' + Items + '_B,0) as float))-floor(cast(isNull(' + Items+'_A,0) as float)))/ 1)*100 		 
		when floor(IsNull(' + Items + '_A,0))<>0  and floor(IsNull(' + Items + '_B,0))<>0 then 	((floor(cast(isNull(' + Items + '_B,0) as float)) - floor(cast(isNull(' + Items+'_A,0) as float))) /floor(cast(' + Items+'_A as float)) )   * 100
		else floor((cast(isNull(' + Items + '_B,0) as float))-floor(cast(isNull(' + Items+'_A,0) as float)))/ floor(cast(' + Items+'_A as float))*100 	end),' 
		+ Items+'_Diff as  ((floor(cast(IsNull(' + Items+'_B,0) as float))-floor(cast(IsNull(' + Items+'_A,0) as float)))) '
		from #Tmp_CompCols1
	set @JoinStr = @JoinStr + ',Has_Diff as (case when ' 
	select @JoinStr=  COALESCE(@JoinStr+'' , '') + '((isNULL(cast(' + Items + '_A as float),0)-isNull(cast(' + Items + '_B as float),0)))=0 and ' 	from #Tmp_CompCols1
	end

	--Remove string 'and' from the end
	set @sql=left(@sql,len(@sql)-1) +left(@JoinStr,len(@JoinStr)-4)+' then 0 else 1 end ))' 	

	--Add IsComparableRow column to the FinalResultsComparisonTbl to indicate whether the row is a comparable row or not.
	set @JoinStr =   ',IsComparableRow as (case when  ' 
	select @JoinStr= COALESCE(@JoinStr+'' , '') + Items + '_A is null or ' + Items + '_B is null or '  from #Tmp_CompCols1 

	--Remove string 'or' from the end
	select @sql = left(@sql,len(@sql)-1) +left(@JoinStr,len(@JoinStr)-3)+' then 0 else 1 end ))' 			
	print @sql

	exec (@sql)
	print '--Final Results Comparison Table Created!'
	print ''

	--Get join columns--
	select @joinColumns=JoinColumns from ReportQuery where ReportID =@reportID1;
	select * into #Tmp_JoinStr from dbo.Split(@joinColumns,',')
	
	--Check if the join columns exist in the query--
	if @isRDB=0
	begin
		delete #Tmp_JoinStr where replace(replace(Items,'[',''),']','') not in (select  sc.Name
		from sysobjects so
		join syscolumns sc on sc.id = so.id
		join systypes st on st.xusertype = sc.xusertype
		where so.name = @tmpTbl1)
	end


	set @JoinStr=null
 	select @JoinStr=COALESCE(@JoinStr+' and ' , '') + ' A.' + Items+' = B.' + Items from #Tmp_JoinStr

	--Populate the final result comparison table--
	if @isRDB =0
	begin
		set @sql='insert into ' + @resultsComparisonTable + ' select * from ' + @tmpTbl1 + ' A full outer join ' + @tmpTbl2 +' B on ' + @JoinStr
		print @sql
		--if @debug=1 exec absp_MessageEx @sql;
		exec (@sql)
	end
	else
	begin
		set @colList1 =''
		select @colList1 = @colList1 +  sc.Name + ',' from sysobjects so inner join syscolumns sc on sc.id = so.id
						where so.name = @tmpTbl1	order by sc.ColID


		set @colList1=left(@colList1,len(@colList1)-1)
	
		set @colList2=@colList1;
		set @colList1='A.' + REPLACE(@colList1,',',',A.')
		set @colList2='B.' + REPLACE(@colList2,',',',B.')

		set @sql='insert into ' + @resultsComparisonTable + ' select ' + @colList1 + ',' + @colList2+' from ' + @tmpRDBTbl1 + 
			' A full outer join ' + @tmpRDBTbl2 +' B on ' + @JoinStr

		--if @debug=1 exec absp_MessageEx @sql;
		exec (@sql)
	end

	print '--Populated Final Results Comparison Table!'
	print ''
	
	--Cleanup tmp tables--
	
	if exists(select 1 from sys.tables where name=@tmpTbl1) exec('drop Table ' + @tmpTbl1)
	if exists(select 1 from sys.tables where name=@tmpTbl2) exec ('drop table '+@tmpTbl2)
	if exists(select 1 from sys.tables where name=@tmpRDBTbl1) exec ('drop table '+@tmpRDBTbl1)
	if exists(select 1 from sys.tables where name=@tmpRDBTbl2) exec ('drop table '+@tmpRDBTbl2)
	
end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

	select @ProcName = object_name(@@procid);
    	select	@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch

