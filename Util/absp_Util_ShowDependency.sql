if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_ShowDependency') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ShowDependency
end

go
create procedure absp_Util_ShowDependency as
begin
 
   set nocount on
   
 /*
  ##BD_BEGIN  
  <font size ="3">
  <pre style="font-family: Lucida Console;" >
  ====================================================================================================
  DB Version:    MSSQL
  Purpose:

  This procedure returns a single resultset displaying the number of dependencies for every procedure 
  and function in the database.

  Returns: A single resultset as follows:-
  PROC_TYPE - Procedure or Function
  PROC_NAME - Name of the procedure
  DEPENDENCIES - The dependancy level

  ====================================================================================================
  </pre>
  </font>
  ##BD_END

  ##RS  PROC_TYPE ^^  Procedure or Function.
  ##RS  PROC_NAME ^^  Name of the procedure
  ##RS  DEPENDENCIES ^^ The dependancy level

  */
  /*
  This procedure determines the number of dependencies for every procedure and function in the database.
  */
   declare @sql varchar(max)
   declare @name varchar(max)
   declare @executeFlag int
   declare @nLen int
   declare @nLevel int
   declare @curs_PRID int
   declare @curs_PN char(128)
   declare @curs_PT char(20)
   declare @absp_curs cursor
   declare @qry varchar(max)
   
   set @executeFlag = 1
   set @nLen = 50
   print GetDate()
   print ': absp_Util_ShowDependency - Begin'
  -- create driving table
   if exists(select 1 from SYSOBJECTS where NAME = 'PROCNAMES' and type = 'U' and UID = 1)
   begin
      drop table PROCNAMES
   end
   if not exists(select 1 from SYSOBJECTS where NAME = 'PROCNAMES' and type = 'U' and UID = 1)
   begin
      create table PROCNAMES
      (
         PID INT identity not null,
         PROC_NAME char(128)   null,
         PROC_TYPE char(20)   null,
         PROC_LEVEL int default -1  null,
         primary key(PID)
      )
      create index PROCNAMES_IDX on PROCNAMES
      (PROC_NAME asc)
   end
  -- create dependency table
   if exists(select 1 from SYSOBJECTS where NAME = 'PROCDEPS' and type = 'U' and UID = 1)
   begin
      drop table PROCDEPS
   end
   if not exists(select 1 from SYSOBJECTS where NAME = 'PROCDEPS' and type = 'U' and UID = 1)
   begin
      create table PROCDEPS
      (
         PID INT   null,
         PROC_NAME char(128)   null,
         PROC_TYPE char(20)   null
      )
      create index PROCDEPS_IDX on PROCDEPS
      (PROC_NAME asc)
   end
  -- populate the driving table
   insert into PROCNAMES(PROC_NAME,PROC_TYPE)
   select rtrim(ltrim(o.NAME)),
      (case when CHARINDEX('procedure',lower(left(p.definition,@nLen))) > 6 then 'Procedure'
   when CHARINDEX('function',lower(left(p.definition,@nLen))) > 6 then 'Function' else 'Unknown'
end) as PROC_TYPE from
   SYSOBJECTS as o join sys.sql_modules as p on
   object_name(p.object_id) = o.NAME where
   o.UID = 1 order by o.NAME asc

  -- populate the dependency table
   set @absp_curs = cursor dynamic for select PID as PRID,PROC_NAME as PN,PROC_TYPE as PT from PROCNAMES
   open @absp_curs
   fetch next from @absp_curs into @curs_PRID,@curs_PN,@curs_PT
   while @@fetch_status = 0
   begin
      print @curs_PT+' '+@curs_PN
      set @qry='insert into PROCDEPS(PID,PROC_NAME)
            select ' + str(@curs_PRID) +',object_name(object_id) from sys.sql_modules where
            CHARINDEX(''' + ltrim(rtrim(@curs_PN)) + ''',DEFINITION) > 10 and
            object_name(object_id) <> '''+ltrim(rtrim(@curs_PN))+''''
      exec(@qry)
--      commit work
      fetch next from @absp_curs into @curs_PRID,@curs_PN,@curs_PT
   end
   close @absp_curs

  -- end of the procedures cursor
  -- update the dependency table PROC_TYPE
    update PROCDEPS  set
    PROCDEPS.PROC_TYPE = PROCNAMES.PROC_TYPE from PROCNAMES where
    PROCDEPS.PROC_NAME = PROCNAMES.PROC_NAME
  -- set level 0 procs
   update PROCNAMES set PROC_LEVEL = 0  where not PROC_NAME = any(select distinct PROC_NAME from PROCDEPS)
  -- set level procs
   set @nLevel = 1
   lbl: while 1 = 1
   begin
      print 'Set Level '+str(@nLevel)+' procedures'
      select distinct PROC_NAME into #TMP1 from PROCDEPS group by PROC_NAME having count(*) = @nLevel;
      update PROCNAMES  set PROCNAMES.PROC_LEVEL = @nLevel from #TMP1 
      where
      PROCNAMES.PROC_LEVEL = -1 and
      PROCNAMES.PROC_NAME = #TMP1.PROC_NAME
      drop table #TMP1
      if not exists(select 1 from PROCNAMES where PROC_LEVEL = -1)
      begin
         break
      end
      else
      begin
         set @nLevel = @nLevel+1
      end
   end
   print GetDate()
   print ': absp_Util_ShowDependency - End'
   select PROC_TYPE AS PROC_TYPE, PROC_NAME AS PROC_NAME, PROC_LEVEL AS DEPENDENCIES from PROCNAMES order by PROC_LEVEL asc,PID asc
end


