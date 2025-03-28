if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ResultsNegativeKeyCounter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ResultsNegativeKeyCounter
end
go
create procedure absp_ResultsNegativeKeyCounter @dbType char(1) = 'M'
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    ASA
Purpose:       This procedure returns a list of results tableName and the no of negative records that 
               exists in those tables.

Returns:       A resultset containing the TABLENAME number of negaive rows in the table
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @dbType      ^^ The dbType on which procedure will be executed.

##RS  TABLENAME ^^  The invalidate results tablename depends on nodetype.
##RS  CNT ^^  The No of records presents in table.
*/
as
begin
  declare @portIdList varchar(1000)
  declare @aportList varchar(1000)
  declare @pportList varchar(1000)
  declare @rportList varchar(1000)
  declare @progList varchar(1000)
  declare @caseList varchar(1000)
  declare @sql varchar(max)
  declare @sql2 varchar(1000)
  declare @mode int
  declare @IR_DBName varchar(2000)
  
  exec @mode=absp_Util_IsSingleDB
  if @mode=0
      set @IR_DBName = DB_NAME() + '_IR'
  
  set @aportList='<0'
  set @portIdList='<0'
  set @pportList='<0'
  set @rportList ='<0'
  set @progList='<0'
  set @caseList='<0'

  if(@dbType = 'M')
  begin 
    create table #COUNT_TBL (TABLENAME char(10) COLLATE SQL_Latin1_General_CP1_CI_AS, CNT int)

    exec absp_APortMasterCounter  '#COUNT_TBL', @aportList 
    exec absp_PPortMasterCounter '#COUNT_TBL',@aportList,@pportList,@portIdList
    exec absp_RPortMasterCounter '#COUNT_TBL',@aportList,@rportList,@progList,@caseList
     
    select * from #COUNT_TBL
    drop table #COUNT_TBL
  end
  else if(@dbType = 'R') 
  begin
    if @mode = 0
    begin
        set @sql='if exists (select 1 from ' + @IR_DBName + '..sysobjects where name = ''COUNT_TBL'')  drop table ' + @IR_DBName + '..COUNT_TBL'    
        execute(@sql) 
        set @sql='create table ' + @IR_DBName + '..COUNT_TBL (TABLENAME char(10), CNT int)'
        print @sql
        execute(@sql)  

        set @sql='exec ' + @IR_DBName + '..absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@portIdList+'''';
         exec(@sql)
        set @sql='exec ' + @IR_DBName + '..absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
        exec(@sql)

    
        execute('select * from ' + @IR_DBName + '..COUNT_TBL')  
        execute('drop table ' + @IR_DBName + '..COUNT_TBL')  
    end
    else
    begin
        set @sql='if exists (select 1 from sysobjects where name = ''COUNT_TBL'')  drop table COUNT_TBL'    
        execute(@sql) at resultdb
        set @sql='create table COUNT_TBL (TABLENAME char(10), CNT int)'
        print @sql
        execute(@sql) at resultdb

        set @sql='exec resultdb...absp_PPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@pportList+''', '''+@portIdList+'''';
        exec(@sql)
        set @sql='exec resultdb...absp_RPortResultCounter ''COUNT_TBL'', '''+@aportList+''', '''+@rportList+''', '''+@progList+''', '''+@caseList+'''';
        exec(@sql)

    
       execute('select * from COUNT_TBL') at resultdb
       execute('drop table COUNT_TBL') at resultdb

    end
  end 
end


