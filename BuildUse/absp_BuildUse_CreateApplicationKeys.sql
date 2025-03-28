if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_BuildUse_CreateApplicationKeys') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BuildUse_CreateApplicationKeys
end
go

create procedure absp_BuildUse_CreateApplicationKeys
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure create Application Keys (AK) which are foreign keys defined in DICTCNST.
    These keys are temporarily used to create entity relationship diagrams for database documentation.

Returns:	None
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin

	set nocount on

    declare @tn    varchar(100)
    declare @tname varchar(100)
    declare @fname varchar(100)
    declare @qry   varchar(8000)
    declare @list  varchar(8000)
    declare @sql   varchar(8000)

    declare curs1 cursor fast_forward for
		select distinct RTableName, RFieldName
			from DictCnst
		order by RTableName, RFieldName

    declare curs2 cursor fast_forward for
		select distinct TableName from DictCnst where CnstType='AK'
		order by TableName

	-- Make parent constraint columns NOT NULL
    open curs1 fetch next from curs1 into @tname,@fname
    while @@FETCH_STATUS = 0
    begin
        if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_TYPE = 'BASE TABLE' and TABLE_NAME = @tname)
        begin
			set @qry = 'alter table [@tname] alter column [@fname] int not null';
			set @qry = REPLACE(@qry, '@tname', @tname)
			set @qry = REPLACE(@qry, '@fname', @fname)

			print @qry
			execute(@qry)
		end
		fetch next from curs1 into @tname,@fname
	end
    close curs1
    deallocate curs1


	-- Create application keys as foreign key constraints
	-- cursor DictCnst by Tablename
	open curs2 fetch next from curs2 into @tname
    while @@FETCH_STATUS = 0
		begin
		print 'Running: exec absp_Util_CreateTableConstraint @baseTableName='+''''+@tname+''''+', @cnstType='+'''AK'''
			exec absp_Util_CreateTableConstraint @baseTableName=@tname, @cnstType='AK'
			fetch next from curs2 into @tname
		end
    close curs2
    deallocate curs2
end
