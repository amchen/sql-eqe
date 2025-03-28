if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_BuildUse_AddExtendedProperty') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BuildUse_AddExtendedProperty
end
go

create procedure absp_BuildUse_AddExtendedProperty
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure adds extended properties for the target database.
    It is used only by the database build process.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin

	set nocount on

    declare @tn varchar(100)
    declare @tname varchar(100)
    declare @fname varchar(100)
    declare @FrndlyName varchar(100)
    declare @primary varchar(512)
    declare @secondary varchar(512)
    declare @example varchar(512)
    declare @qry varchar(8000)
    declare @sql varchar(8000)

    declare curs1 cursor fast_forward for
        select rtrim(coalesce(CloneName, t1.TableName)), rtrim(t1.TableName), rtrim(t1.FrndlyName)
            from DICTTBL t1 left outer join DICTCLON t2
              on t1.TableName = t2.TableName
        order by t1.TableName

    open curs1 fetch next from curs1 into @tname,@tn,@FrndlyName
    while @@FETCH_STATUS = 0
    begin

        if exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_TYPE = 'BASE TABLE' and TABLE_NAME = @tname)
        begin

			if (len(@FrndlyName) = 0)
			begin
				set @FrndlyName = 'None.'
			end

			-- Table Definition
			set @qry = 'EXEC sp_addextendedproperty
				@name = ''MS_Description'', @value = ''@FrndlyName'',
				@level0type = ''Schema'', @level0name = [dbo],
				@level1type = ''Table'',  @level1name = [@tname]'

			set @primary = REPLACE(@FrndlyName, '''', '''''')
			set @qry = REPLACE(@qry, '@FrndlyName', @FrndlyName)
			set @qry = REPLACE(@qry, '@tname', @tname)

			print @qry
			execute(@qry)

            declare curs2 cursor fast_forward for
                select FIELDNAME, DEFINITION, DEFINITION2, DEFINITION3 from DICTCOL where TABLENAME = @tn order by FIELDNUM

            open curs2 fetch next from curs2 into @fname,@primary,@secondary,@example
            while @@FETCH_STATUS = 0
            begin

                if (len(@primary) = 0)
                begin
                    set @primary = 'None.'
                end

                -- Column: Primary Definition
                set @qry = 'EXEC sp_addextendedproperty
                    @name = ''Primary'', @value = ''@primary'',
                    @level0type = ''Schema'', @level0name = [dbo],
                    @level1type = ''Table'',  @level1name = [@tname],
                    @level2type = ''Column'', @level2name = [@fname]'

                set @primary = REPLACE(@primary, '''', '''''')
                set @qry = REPLACE(@qry, '@primary', @primary)
                set @qry = REPLACE(@qry, '@tname', @tname)
                set @qry = REPLACE(@qry, '@fname', @fname)

                print @qry
                execute(@qry)

                if (len(@secondary) = 0)
                begin
                    set @secondary = 'None.'
                end

                -- Column: Secondary Definition
                set @qry = 'EXEC sp_addextendedproperty
                    @name = ''Secondary'', @value = ''@secondary'',
                    @level0type = ''Schema'', @level0name = [dbo],
                    @level1type = ''Table'',  @level1name = [@tname],
                    @level2type = ''Column'', @level2name = [@fname]'

                set @secondary = REPLACE(@secondary, '''', '''''')
                set @qry = REPLACE(@qry, '@secondary', @secondary)
                set @qry = REPLACE(@qry, '@tname', @tname)
                set @qry = REPLACE(@qry, '@fname', @fname)

                print @qry
                execute(@qry)

                if (len(@example) = 0)
                begin
                    set @example = 'None.'
                end

                -- Column: Example Definition
                set @qry = 'EXEC sp_addextendedproperty
                    @name = ''Example'', @value = ''@example'',
                    @level0type = ''Schema'', @level0name = [dbo],
                    @level1type = ''Table'',  @level1name = [@tname],
                    @level2type = ''Column'', @level2name = [@fname]'

                set @example = REPLACE(@example, '''', '''''')
                set @qry = REPLACE(@qry, '@example', @example)
                set @qry = REPLACE(@qry, '@tname', @tname)
                set @qry = REPLACE(@qry, '@fname', @fname)

                print @qry
                execute(@qry)

                fetch next from curs2 into @fname,@primary,@secondary,@example
            end

            close curs2
            deallocate curs2

        end

        fetch next from curs1 into @tname,@tn,@FrndlyName
    end

    close curs1
    deallocate curs1

end
