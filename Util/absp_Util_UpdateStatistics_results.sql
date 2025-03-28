if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_UpdateStatistics_results') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_UpdateStatistics_results
end
go

create procedure absp_Util_UpdateStatistics_results
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MSSQL
Purpose:    This procedure updates statistics on the results database.
Returns:    Nothing
====================================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on

    declare @sql varchar(max)
    declare @tname varchar(120)
    declare @iname varchar(120)

    declare curs1 cursor fast_forward for
        select rtrim(NAME) from SYS.TABLES where NAME in (select distinct TABLENAME from DELCTRL where BLOB_DB = 'R')

    open curs1 fetch next from curs1 into @tname
    while @@FETCH_STATUS = 0
    begin

        declare curs2 cursor fast_forward for
            select rtrim(NAME) from SYSINDEXES
                where id = object_id(ltrim(rtrim(@tname)))
                and   indid > 0 and indid < 255
                and   indexproperty(id, name, 'IsStatistics') = 0
                and   name like '%_I%'
                and   name not like 'PK%'
                order by indid desc

        open curs2 fetch next from curs2 into @iname
        while @@FETCH_STATUS = 0
        begin
            set @sql = 'update statistics ' + @tname + ' ' + @iname
            exec absp_Util_LogIt @sql, 1, 'Updating Index Statistics'
            execute (@sql)

            fetch next from curs2 into @iname
        end

        close curs2
        deallocate curs2

        set @sql = 'update statistics ' + @tname
        exec absp_Util_LogIt @sql, 1, 'Updating Table Statistics'
        execute (@sql)
        
        -- wait for 3 minutes - Reduced this from 5 to 3 because the DBs are small
        WAITFOR DELAY '00:03';

        fetch next from curs1 into @tname
    end

    close curs1
    deallocate curs1

end
