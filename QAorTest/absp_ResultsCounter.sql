if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ResultsCounter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ResultsCounter
end
go
create procedure absp_ResultsCounter @nodeName char(120),@nodeType integer,@dbType char(1) = 'M'
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedure count the no of records of invalidate results table based on dbType, 
               nodeName and nodeType.

Returns:       A resultset containing the TABLENAME and CNT of temporary table COUNT_TBL.
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @nodeName    ^^ The nodeName is used to get list of nodekey and it's childKey.
##PD  @nodeType    ^^ The node type for which records will be count.
##PD  @dbType      ^^ The dbType on which procedure will be executed.

##RS  TABLENAME ^^  The invalidate results tablename depends on nodetype.
##RS  CNT ^^  The No of records presents in table.
*/
as
begin

  declare @exposurekeyList varchar(1000)
  declare @aportList varchar(1000)
  declare @pportList varchar(1000)
  declare @rportList varchar(1000)
  declare @progList varchar(1000)
  declare @caseList varchar(1000)
  declare @sql varchar(max)
  declare @sql2 varchar(1000)
  declare @mode int
  declare @IR_DBName varchar(2000)
  declare @ebeRunIdList varchar(2000)
  declare @tmpEbeRunIdList varchar(2000)

  exec @mode=absp_Util_IsSingleDB
  if @mode=0
  	set @IR_DBName = DB_NAME() + '_IR'
	  
  --Enclose within square brackets--
  execute absp_getDBName @IR_DBName out, @IR_DBName
  
  if(@nodeType = 1)
  begin
	set @sql = 'select APORT_KEY from APRTINFO where LONGNAME = '''+@nodeName+''''
    exec absp_Util_GenInList @aportList output, @sql
	set @sql = 'select CHILD_KEY from APORTMAP where APORT_KEY '+@aportList+' and CHILD_TYPE = 2'
    exec absp_Util_GenInList @pportList output, @sql
    set @sql = 'select exposurekey from exposuremap where parentkey '+@pportList
    exec absp_Util_GenInList @exposurekeyList output, @sql
	set @sql = 'select CHILD_KEY from APORTMAP where APORT_KEY '+@aportList+' and CHILD_TYPE in (3, 23)'
    exec absp_Util_GenInList @rportList output, @sql
	set @sql = 'select CHILD_KEY from RPORTMAP where RPORT_KEY '+@rportList+' and CHILD_TYPE in (7, 27)'
    exec absp_Util_GenInList @progList output, @sql
	set @sql = 'select CASE_KEY  from CASEINFO where PROG_KEY '+@progList
    exec absp_Util_GenInList @caseList output, @sql
    set @sql = 'select EBERUNID  from ELTSummary where NodeKey '+@aportList + ' and NodeType = 1'
    exec absp_Util_GenInList @ebeRunIdList output, @sql
  end 
  
  else if(@nodeType = 2) 
  begin
	set @sql = 'select PPORT_KEY from PPRTINFO where LONGNAME = '''+@nodeName+''''
    exec absp_Util_GenInList @pportList output, @sql
    set @sql = 'select APORT_KEY from APORTMAP where CHILD_KEY '+@pportList+' and CHILD_TYPE = 2'
    exec absp_Util_GenInList @aportList output, @sql
	set @sql = 'select exposurekey from exposuremap where parentkey '+@pportList
    exec absp_Util_GenInList @exposurekeyList output, @sql
    set @sql = 'select EBERUNID  from ELTSummary where NodeKey '+@pportList + ' and NodeType = 2'
    exec absp_Util_GenInList @ebeRunIdList output, @sql
  end  
  
  else if(@nodeType = 3 or @nodeType = 23) 
  begin
    set @sql = 'select RPORT_KEY from RPRTINFO where LONGNAME = '''+@nodeName+''''
    exec absp_Util_GenInList @rportList output, @sql
    set @sql = 'select APORT_KEY from APORTMAP where CHILD_KEY '+@rportList+' and CHILD_TYPE in (3, 23)'
    exec absp_Util_GenInList @aportList output, @sql
    set @sql = 'select CHILD_KEY from RPORTMAP where RPORT_KEY '+@rportList+' and CHILD_TYPE in (7, 27)'
    exec absp_Util_GenInList @progList output, @sql
    set @sql = 'select CASE_KEY  from CASEINFO where PROG_KEY '+@progList
    exec absp_Util_GenInList @caseList output, @sql
    set @sql = 'select EBERUNID from ELTSummary where NodeKey '+@rportList+' and NodeType in (3,23)'
    exec absp_Util_GenInList @tmpEbeRunIdList output, @sql
    set @ebeRunIdList = left(@tmpEbeRunIdList, charindex(')',@tmpEbeRunIdList)-1)    
    set @sql = 'select EBERUNID from ELTSummary where NodeKey '+@progList +' and NodeType in (7,27)'
    exec absp_Util_GenInList @tmpEbeRunIdList output, @sql
    set @ebeRunIdList = @ebeRunIdList + ',' + right(@tmpEbeRunIdList, len(@tmpEbeRunIdList) - charindex('(',@tmpEbeRunIdList))
    set @ebeRunIdList = left(@ebeRunIdList, charindex(')',@tmpEbeRunIdList)-3)
    set @sql = 'select EBERUNID from ELTSummary where NodeKey '+@caseList +' and NodeType in (10,30)'
    exec absp_Util_GenInList @tmpEbeRunIdList output, @sql
    set @ebeRunIdList = @ebeRunIdList + ',' + right(@tmpEbeRunIdList, len(@tmpEbeRunIdList) - charindex('(',@tmpEbeRunIdList))
  end  
  
  else if(@nodeType = 7 or @nodeType = 27) 
  begin
	set @sql = 'select PROG_KEY from PROGINFO where LONGNAME = '''+@nodeName+''''
    exec absp_Util_GenInList @progList output, @sql
    set @sql = 'select RPORT_KEY from RPORTMAP where CHILD_KEY '+@progList+' and CHILD_TYPE in (7, 27)'
    exec absp_Util_GenInList @rportList output, @sql
    set @sql = 'select APORT_KEY from APORTMAP where CHILD_KEY '+@rportList+' and CHILD_TYPE in (3, 23)'
    exec absp_Util_GenInList @aportList output, @sql
    set @sql = 'select CASE_KEY  from CASEINFO where PROG_KEY '+@progList
    exec absp_Util_GenInList @caseList output, @sql
    set @sql = 'select EBERUNID from ELTSummary where NodeKey '+@progList +' and NodeType in (7,27)'
    exec absp_Util_GenInList @tmpEbeRunIdList output, @sql
    set @ebeRunIdList = left(@tmpEbeRunIdList, charindex(')',@tmpEbeRunIdList)-3) 
    set @sql = 'select EBERUNID from ELTSummary where NodeKey '+@caseList +' and NodeType in (10,30)'    
    exec absp_Util_GenInList @tmpEbeRunIdList output, @sql
    set @ebeRunIdList = @ebeRunIdList + ',' + right(@tmpEbeRunIdList, len(@tmpEbeRunIdList) - charindex('(',@tmpEbeRunIdList))
  end  
  
  else if(@nodeType = 10 or @nodeType = 30) 
  begin
    set @sql = 'select CASE_KEY  from CASEINFO where LONGNAME = '''+@nodeName+''''
    exec absp_Util_GenInList @caseList output, @sql
    set @sql = 'select PROG_KEY  from CASEINFO where CASE_KEY  '+@caseList
    exec absp_Util_GenInList @progList output, @sql
    set @sql = 'select RPORT_KEY from RPORTMAP where CHILD_KEY '+@progList+' and CHILD_TYPE in (7, 27)'
    exec absp_Util_GenInList @rportList output, @sql
    set @sql = 'select APORT_KEY from APORTMAP where CHILD_KEY '+@rportList+' and CHILD_TYPE in (3, 23)'
    exec absp_Util_GenInList @aportList output, @sql
    set @sql = 'select EBERUNID  from ELTSummary where NodeKey '+@caseList + ' and NodeType in (10,30)'
    exec absp_Util_GenInList @ebeRunIdList output, @sql
  end 
  
  print 'aportList = '+@aportList;
  print '@rportList = '+@rportList;
  print 'progList = '+@progList;
  print 'ebeRunIdList = '+@ebeRunIdList;
  
  if(@dbType = 'M')
  begin 
    create table #COUNT_TBL (TABLENAME char(50) COLLATE SQL_Latin1_General_CP1_CI_AS, CNT int)

    if(@nodeType = 1) 
    begin
      exec absp_APortMasterCounter '#COUNT_TBL', @aportList, @ebeRunIdList 
      --exec absp_PPortMasterCounter '#COUNT_TBL',@aportList,@pportList,@exposurekeyList, @ebeRunIdList
      --exec absp_RPortMasterCounter '#COUNT_TBL',@aportList,@rportList,@progList,@caseList, @ebeRunIdList
    end
    else if(@nodeType = 2)     
      exec absp_PPortMasterCounter '#COUNT_TBL',@aportList,@pportList,@exposurekeyList, @ebeRunIdList
    else if(@nodeType = 3 or @nodeType = 23) 
      exec absp_RPortMasterCounter '#COUNT_TBL',@aportList,@rportList,@progList,@caseList, @ebeRunIdList, @nodeType
    else if(@nodeType = 7 or @nodeType = 27) 
      exec absp_RPortMasterCounter '#COUNT_TBL',@aportList,@rportList,@progList,@caseList, @ebeRunIdList, @nodeType
    else if(@nodeType = 10 or @nodeType = 30) 
      exec absp_RPortMasterCounter '#COUNT_TBL',@aportList,@rportList,@progList,@caseList, @ebeRunIdList, @nodeType
     
    select * from #COUNT_TBL
    drop table #COUNT_TBL
  end
  
  else if(@dbType = 'R') 
  begin
     if @mode=0
     begin
        set @sql='if exists (select 1 from ' + @IR_DBName + '..sysobjects where name = ''COUNT_TBL'')  drop table ' + @IR_DBName + '..COUNT_TBL'    
        execute(@sql)  
        set @sql='create table ' + @IR_DBName + '..COUNT_TBL (TABLENAME varchar(100), CNT int)'
        print @sql
        execute(@sql)  
     end
     else
     begin
        set @sql='if exists (select 1 from sysobjects where name = ''COUNT_TBL'')  drop table COUNT_TBL'    
        execute(@sql) at resultdb
        set @sql='create table COUNT_TBL (TABLENAME varchar(100), CNT int)'
        print @sql
        execute(@sql) at resultdb
    end
    
    if(@nodeType = 1) 
    begin
        if @mode=0
        begin
             set @sql='exec ' + @IR_DBName + '..absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@exposurekeyList+'''';
             exec(@sql)
             set @sql='exec ' + @IR_DBName + '..absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
             exec(@sql)
         end
   
    	else
    	begin
      		set @sql='exec resultdb...absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@exposurekeyList+'''';
      		exec(@sql)
      	    set @sql='exec resultdb...absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
      	    exec(@sql)
        end
    end
    else if(@nodeType = 2) 
    begin
    	if @mode=0
      		set @sql='exec ' + @IR_DBName + '..absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@exposurekeyList+'''';
    	else
    		set @sql='exec resultdb...absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@exposurekeyList+'''';
      	exec(@sql)
    end
    
    else if(@nodeType = 3 or @nodeType = 23) 
    begin
		if @mode=0
      		set @sql='exec ' + @IR_DBName + '..absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
		else
			set @sql='exec resultdb...absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
      	exec(@sql)
    end
    
    else if(@nodeType = 7 or @nodeType = 27) 
    begin
		if @mode=0
      		set @sql='exec ' + @IR_DBName + '..absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
		else
      		set @sql='exec resultdb...absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';

      exec(@sql)
    end
    
    else if(@nodeType = 10 or @nodeType = 30) 
    begin
		if @mode=0
      		set @sql='exec ' + @IR_DBName + '..absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
		else
			set @sql='exec resultdb...absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
      	exec(@sql)
	end
    
	if @mode=0
	begin
    	execute('select * from ' + @IR_DBName + '..COUNT_TBL') 
    	execute('drop table ' + @IR_DBName + '..COUNT_TBL')  
	end
	else
	begin
    	execute('select * from COUNT_TBL') at resultdb
    	execute('drop table COUNT_TBL') at resultdb

	end
  end 
end


